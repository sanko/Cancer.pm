use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/sixel/color_test.go
# Tests Sixel color spec encoding/decoding.
#
# Inline helper implementations of the sixel color functions
# since there is no Cancer::Ansi::Sixel module yet.
use constant COLOR_INTRODUCER => ord('#');

sub write_color {
    my ( $pc, $pu, $px, $py, $pz ) = @_;
    if ( $pu <= 0 || $pu > 2 ) {
        return sprintf( '#%d', $pc );
    }
    return sprintf( '#%d;%d;%d;%d;%d', $pc, $pu, $px, $py, $pz );
}

sub decode_color($data) {
    return ( {}, 0 ) if !length $data || ord( substr( $data, 0, 1 ) ) != COLOR_INTRODUCER;
    return ( {}, 0 ) if length $data < 2;
    my $c  = {};
    my $n  = 0;
    my $pc = \$c->{pc};
    $pc //= 0;
    $c->{pc} = 0;
    for ( $n = 1; $n < length $data; $n++ ) {
        my $ch = substr( $data, $n, 1 );
        if ( $ch eq ';' ) {
            if ( $pc == \$c->{pc} ) {
                $pc = \$c->{pu};
                $c->{pu} = 0;
            }
            else {
                $n++;
                last;
            }
        }
        elsif ( $ch =~ /[0-9]/ ) {
            ${$pc} = ${$pc} * 10 + ord($ch) - 48;
        }
        else {
            last;
        }
    }
    my $ptr = \$c->{px};
    $c->{px} = 0;
    for ( ; $n < length $data; $n++ ) {
        my $ch = substr( $data, $n, 1 );
        if ( $ch eq ';' ) {
            if ( $ptr == \$c->{px} ) {
                $ptr = \$c->{py};
                $c->{py} = 0;
            }
            elsif ( $ptr == \$c->{py} ) {
                $ptr = \$c->{pz};
                $c->{pz} = 0;
            }
            else {
                $n++;
                last;
            }
        }
        elsif ( $ch =~ /[0-9]/ ) {
            ${$ptr} = ${$ptr} * 10 + ord($ch) - 48;
        }
        else {
            last;
        }
    }
    return ( $c, $n );
}

sub palval ( $n, $a, $m ) {
    return int( ( $n * $a + $m / 2 ) / $m );
}

sub _to16bit ($v) {
    return $v * 257;    # convert 8-bit to 16-bit as Go's color.Color.RGBA() does
}

sub sixel_rgb ( $r, $g, $b ) {
    return ( _to16bit( palval( $r, 255, 100 ) ), _to16bit( palval( $g, 255, 100 ) ), _to16bit( palval( $b, 255, 100 ) ), 0xFFFF );
}

sub sixel_hls ( $h, $l, $s ) {

    # HLS to RGB conversion using the 6-cone model (matching Go's colorful.Hsl)
    my $c = ( 1 - abs( 2 * $l / 100 - 1 ) ) * $s / 100;
    my $x = $c * ( 1 - abs( ( $h / 60 ) % 2 - 1 ) );
    my $m = $l / 100 - $c / 2;
    my ( $rp, $gp, $bp );
    if    ( $h < 60 )  { $rp = $c; $gp = $x; $bp = 0 }
    elsif ( $h < 120 ) { $rp = $x; $gp = $c; $bp = 0 }
    elsif ( $h < 180 ) { $rp = 0;  $gp = $c; $bp = $x }
    elsif ( $h < 240 ) { $rp = 0;  $gp = $x; $bp = $c }
    elsif ( $h < 300 ) { $rp = $x; $gp = 0;  $bp = $c }
    else               { $rp = $c; $gp = 0;  $bp = $x }
    return (
        _to16bit( int( ( $rp + $m ) * 255 + 0.5 ) ),
        _to16bit( int( ( $gp + $m ) * 255 + 0.5 ) ),
        _to16bit( int( ( $bp + $m ) * 255 + 0.5 ) ), 0xFFFF
    );
}

# Default sixel color palette (first 16 colors)
my @SIXEL_PALETTE = (
    [ 0,   0,   0 ],      # 0  black
    [ 51,  51,  204 ],    # 1
    [ 204, 36,  36 ],     # 2
    [ 51,  204, 51 ],     # 3
    [ 204, 51,  204 ],    # 4
    [ 51,  204, 204 ],    # 5
    [ 204, 204, 51 ],     # 6
    [ 120, 120, 120 ],    # 7
    [ 69,  69,  69 ],     # 8
    [ 87,  87,  153 ],    # 9
    [ 153, 69,  69 ],     # 10
    [ 87,  153, 87 ],     # 11
    [ 153, 87,  153 ],    # 12
    [ 87,  153, 153 ],    # 13
    [ 153, 153, 87 ],     # 14
    [ 204, 204, 204 ]     # 15
);

sub color_rgba ($c) {
    my $pu = $c->{pu} // 0;
    my $pc = $c->{pc} // 0;
    return sixel_hls( $c->{px} // 0, $c->{py} // 0, $c->{pz} // 0 ) if $pu == 1;
    return sixel_rgb( $c->{px} // 0, $c->{py} // 0, $c->{pz} // 0 ) if $pu == 2;
    my $p = $SIXEL_PALETTE[$pc] // [ 0, 0, 0 ];
    return ( _to16bit( $p->[0] ), _to16bit( $p->[1] ), _to16bit( $p->[2] ), 0xFFFF );
}
#
subtest 'TestWriteColor' => sub {
    my @tests = (
        [ 'simple color number', 1, 0, 0,   0,  0,   '#1' ],
        [ 'RGB color',           1, 2, 50,  60, 70,  '#1;2;50;60;70' ],
        [ 'HLS color',           2, 1, 180, 50, 100, '#2;1;180;50;100' ],
        [ 'invalid pu > 2',      1, 3, 0,   0,  0,   '#1' ]
    );
    for my $tc (@tests) {
        my ( $name, $pc, $pu, $px, $py, $pz, $want ) = @$tc;
        my $got = write_color( $pc, $pu, $px, $py, $pz );
        is $got, $want, $name;
    }
};
subtest 'TestDecodeColor' => sub {
    my @tests = (
        [ 'simple color number', '#1',              { pc => 1 },                                          2 ],
        [ 'RGB color',           '#1;2;50;60;70',   { pc => 1, pu => 2, px => 50, py => 60, pz => 70 },   13 ],
        [ 'HLS color',           '#2;1;180;50;100', { pc => 2, pu => 1, px => 180, py => 50, pz => 100 }, 15 ],
        [ 'empty input',         '',                {},                                                   0 ],
        [ 'invalid introducer',  'X1',              {},                                                   0 ],
        [ 'incomplete sequence', '#',               {},                                                   0 ]
    );
    for my $tc (@tests) {
        my ( $name, $input, $want_c, $want_n ) = @$tc;
        my ( $got_c, $got_n ) = decode_color($input);
        is $got_n, $want_n, "$name: n";

        # Use field comparison rather than deep equality since keys are sparse
        for my $k ( keys %$want_c ) {
            is $got_c->{$k} // 0, $want_c->{$k}, "$name: $k";
        }
    }
};
subtest 'TestColor_RGBA' => sub {
    my @tests = (
        [ 'default color map 0 (black)', { pc => 0 }, 0x0000, 0x0000, 0x0000, 0xFFFF ],
        [ 'RGB mode (50%, 60%, 70%)',    { pc => 1, pu => 2, px => 50,  py => 60, pz => 70 },  0x8080, 0x9999, 0xB3B3, 0xFFFF ],
        [ 'HLS mode (180°, 50%, 100%)',  { pc => 1, pu => 1, px => 180, py => 50, pz => 100 }, 0x0000, 0xFFFF, 0xFFFF, 0xFFFF ]
    );
    for my $tc (@tests) {
        my ( $name, $color, $want_r, $want_g, $want_b, $want_a ) = @$tc;
        my ( $got_r, $got_g, $got_b, $got_a ) = color_rgba($color);
        is $got_r, $want_r, "$name: R";
        is $got_g, $want_g, "$name: G";
        is $got_b, $want_b, "$name: B";
        is $got_a, $want_a, "$name: A";
    }
};
subtest 'TestSixelRGB' => sub {
    my @tests = (
        [ 'black',          0,   0,   0,   0x0000, 0x0000, 0x0000, 0xFFFF ],
        [ 'white',          100, 100, 100, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF ],
        [ 'red',            100, 0,   0,   0xFFFF, 0x0000, 0x0000, 0xFFFF ],
        [ 'half intensity', 50,  50,  50,  0x8080, 0x8080, 0x8080, 0xFFFF ]
    );
    for my $tc (@tests) {
        my ( $name, $r, $g, $b, $want_r, $want_g, $want_b, $want_a ) = @$tc;
        my ( $got_r, $got_g, $got_b, $got_a ) = sixel_rgb( $r, $g, $b );
        is $got_r, $want_r, "$name: R";
        is $got_g, $want_g, "$name: G";
        is $got_b, $want_b, "$name: B";
        is $got_a, $want_a, "$name: A";
    }
};
subtest 'TestSixelHLS' => sub {
    my @tests = (
        [ 'black',      0,   0,   0,   0x0000, 0x0000, 0x0000, 0xFFFF ],
        [ 'white',      0,   100, 0,   0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF ],
        [ 'pure red',   0,   50,  100, 0xFFFF, 0x0000, 0x0000, 0xFFFF ],
        [ 'pure green', 120, 50,  100, 0x0000, 0xFFFF, 0x0000, 0xFFFF ],
        [ 'pure blue',  240, 50,  100, 0x0000, 0x0000, 0xFFFF, 0xFFFF ]
    );
    for my $tc (@tests) {
        my ( $name, $h, $l, $s, $want_r, $want_g, $want_b, $want_a ) = @$tc;
        my ( $got_r, $got_g, $got_b, $got_a ) = sixel_hls( $h, $l, $s );
        is $got_r, $want_r, "$name: R";
        is $got_g, $want_g, "$name: G";
        is $got_b, $want_b, "$name: B";
        is $got_a, $want_a, "$name: A";
    }
};
#
done_testing;
