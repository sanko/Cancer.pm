use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/kitty/options_test.go
# Tests Kitty Graphics Protocol options serialization.
sub build_options {
    my ($o) = @_;
    $o //= {};
    $o->{format} = ( $o->{format} // 0 ) || 32;
    $o->{action} = ( $o->{action} // 0 ) || 't';
    $o->{delete} = ( $o->{delete} // 0 ) || 'a';
    my $transmission = $o->{transmission} || '';
    if ( !$transmission ) {
        $transmission = ( $o->{file} // '' ) ne '' ? 'f' : 'd';
    }
    my @opts;
    push @opts, sprintf( 'f=%d', $o->{format} ) if $o->{format} != 32;
    my $quiet = $o->{quiet} // 0;
    $quiet = $o->{quite} if ( $o->{quite} // 0 ) > 0;
    push @opts, sprintf( 'q=%d', $quiet )             if $quiet > 0;
    push @opts, sprintf( 'i=%d', $o->{id} )           if ( $o->{id} // 0 ) > 0;
    push @opts, sprintf( 'p=%d', $o->{placement_id} ) if ( $o->{placement_id} // 0 ) > 0;
    push @opts, sprintf( 'I=%d', $o->{number} )       if ( $o->{number} // 0 ) > 0;
    push @opts, sprintf( 's=%d', $o->{image_width} )  if ( $o->{image_width} // 0 ) > 0;
    push @opts, sprintf( 'v=%d', $o->{image_height} ) if ( $o->{image_height} // 0 ) > 0;
    push @opts, "t=$transmission"                     if $transmission ne 'd';
    push @opts, sprintf( 'S=%d', $o->{size} )         if ( $o->{size} // 0 ) > 0;
    push @opts, sprintf( 'O=%d', $o->{offset} )       if ( $o->{offset} // 0 ) > 0;

    if ( defined $o->{compression} && $o->{compression} eq 'z' ) {
        push @opts, 'o=z';
    }
    push @opts, 'U=1' if $o->{virtual_placement};
    push @opts, 'C=1' if $o->{do_not_move_cursor};
    push @opts, sprintf( 'P=%d', $o->{parent_id} )           if ( $o->{parent_id}           // 0 ) > 0;
    push @opts, sprintf( 'Q=%d', $o->{parent_placement_id} ) if ( $o->{parent_placement_id} // 0 ) > 0;
    push @opts, sprintf( 'x=%d', $o->{x} )                   if ( $o->{x}                   // 0 ) > 0;
    push @opts, sprintf( 'y=%d', $o->{y} )                   if ( $o->{y}                   // 0 ) > 0;
    push @opts, sprintf( 'z=%d', $o->{z} )                   if ( $o->{z}                   // 0 ) > 0;
    push @opts, sprintf( 'w=%d', $o->{width} )               if ( $o->{width}               // 0 ) > 0;
    push @opts, sprintf( 'h=%d', $o->{height} )              if ( $o->{height}              // 0 ) > 0;
    push @opts, sprintf( 'X=%d', $o->{offset_x} )            if ( $o->{offset_x}            // 0 ) > 0;
    push @opts, sprintf( 'Y=%d', $o->{offset_y} )            if ( $o->{offset_y}            // 0 ) > 0;
    push @opts, sprintf( 'c=%d', $o->{columns} )             if ( $o->{columns}             // 0 ) > 0;
    push @opts, sprintf( 'r=%d', $o->{rows} )                if ( $o->{rows}                // 0 ) > 0;
    my $da = $o->{delete};

    if ( $o->{delete_resources} ) {
        $da = uc($da);
    }
    push @opts, "d=$da"          if $o->{delete} ne 'a' || $o->{delete_resources};
    push @opts, "a=$o->{action}" if $o->{action} ne 't';
    @opts = sort @opts;
    return @opts;
}

sub options_string {
    my ($o) = @_;
    return join( ',', build_options($o) );
}

# -- Tests ---------------------------------------------------------------
subtest 'TestOptions_Options' => sub {
    my @tests = (
        [ 'default options',            {},                                               [] ],
        [ 'basic transmission options', { format => 100, id => 1, action => 'T' },        [ map +("$_"), sort qw(f=100 i=1 a=T) ] ],
        [ 'display options', { x => 100, y => 200, z => 3, width => 400, height => 300 }, [ map +("$_"), sort qw(x=100 y=200 z=3 w=400 h=300) ] ],
        [ 'compression and chunking', { compression => 'z', chunk => 1, size => 1024 },                     [ 'S=1024', 'o=z' ] ],
        [ 'delete options',           { delete => 'i', delete_resources => 1 },                             ['d=I'] ],
        [ 'virtual placement',        { virtual_placement => 1, parent_id => 5, parent_placement_id => 2 }, [ map +("$_"), sort qw(U=1 P=5 Q=2) ] ],
        [ 'cell positioning',         { offset_x => 10, offset_y => 20, columns => 80, rows => 24 }, [ map +("$_"), sort qw(X=10 Y=20 c=80 r=24) ] ],
        [   'transmission details',
            { transmission => 'f', file => '/tmp/image.png', offset => 100, number => 2, placement_id => 3 },
            [ map +("$_"), sort qw(p=3 I=2 t=f O=100) ]
        ],
        [ 'quiet mode and format', { quiet => 2, format => 24 }, [qw(f=24 q=2)] ],
        [ 'all zero values', { format => 0, action => 0, delete => 0 }, [] ],
    );
    for my $tc (@tests) {
        my ( $name, $options, $expected ) = @$tc;
        my @got = build_options($options);
        my @exp = sort @$expected;
        is \@got, \@exp, $name;
    }
};
subtest 'TestOptions_QuiteDeprecation' => sub {
    my @tests = (
        [ 'Quiet only',                { quiet => 1 },             ['q=1'] ],
        [ 'deprecated Quite only',     { quite => 2 },             ['q=2'] ],
        [ 'Quite overrides Quiet',     { quiet => 1, quite => 2 }, ['q=2'] ],
        [ 'Quite=0 does not override', { quiet => 1, quite => 0 }, ['q=1'] ],
        [ 'both zero emits no q=',     {},                         [] ],
    );
    for my $tc (@tests) {
        my ( $name, $options, $expected ) = @$tc;
        my @got = build_options($options);
        is \@got, $expected, $name;
    }
};
subtest 'TestOptions_Validation' => sub {
    my @got1 = build_options( { format => 999 } );
    ok scalar( grep { $_ eq 'f=999' } @got1 ), 'format validation';
    my @got2 = build_options( { delete => 'i', delete_resources => 1 } );
    ok scalar( grep { $_ eq 'd=I' } @got2 ), 'delete with resources';
    my @got3 = build_options( { transmission => 'f', file => '/tmp/test.png' } );
    ok scalar( grep { $_ eq 't=f' } @got3 ), 'transmission with file';
};
subtest 'TestOptions_String' => sub {
    my @tests = (
        [ 'empty options', {}, '' ],
        [   'full options',
            {   action              => 'A',
                quiet               => 81,
                compression         => 'C',
                transmission        => 'T',
                delete              => 'd',
                delete_resources    => 1,
                id                  => 123,
                placement_id        => 456,
                number              => 789,
                format              => 1,
                image_width         => 800,
                image_height        => 600,
                size                => 1024,
                offset              => 10,
                chunk               => 1,
                x                   => 100,
                y                   => 200,
                z                   => 300,
                width               => 400,
                height              => 500,
                offset_x            => 50,
                offset_y            => 60,
                columns             => 4,
                rows                => 3,
                virtual_placement   => 1,
                parent_id           => 999,
                parent_placement_id => 888,
            },
            'f=1,q=81,i=123,p=456,I=789,s=800,v=600,t=T,S=1024,O=10,U=1,P=999,Q=888,x=100,y=200,z=300,w=400,h=500,X=50,Y=60,c=4,r=3,d=D,a=A',
        ],
    );
    for my $tc (@tests) {
        my ( $name, $options, $want ) = @$tc;
        my $got        = options_string($options);
        my @got_parts  = sort split /,/, $got;
        my @want_parts = $want ? sort split /,/, $want : ();
        is \@got_parts, \@want_parts, $name;
    }
};
subtest 'TestOptions_MarshalText' => sub {
    my @tests = (
        [ 'marshal empty options', {}, '' ],
        [   'marshal with values',
            { action => 'A', id => 123, width => 400, height => 500, quiet => 2, do_not_move_cursor => 1 },
            'q=2,i=123,C=1,w=400,h=500,a=A',
        ],
    );
    for my $tc (@tests) {
        my ( $name, $options, $want ) = @$tc;
        my $got        = options_string($options);
        my @got_parts  = sort split /,/, $got;
        my @want_parts = $want ? sort split /,/, $want : ();
        is \@got_parts, \@want_parts, $name;
    }
};
subtest 'TestOptions_UnmarshalText' => sub {
    my %opts_default = ( format => 32, action => 't', delete => 'a' );
    my @tests        = (
        [ 'unmarshal empty',                  '',                      {} ],
        [ 'unmarshal basic options',          'a=A,i=123,w=400,h=500', { action => 'A', id => 123, width => 400, height => 500 }, ],
        [ 'unmarshal with invalid number',    'i=abc',                 {} ],
        [ 'unmarshal q= populates Quiet',     'q=1',                   { quiet             => 1 } ],
        [ 'unmarshal with delete resources',  'd=D',                   { delete            => 'd', delete_resources => 1 } ],
        [ 'unmarshal with boolean chunk',     'm=1',                   { chunk             => 1 } ],
        [ 'unmarshal with virtual placement', 'U=1',                   { virtual_placement => 1 } ],
        [ 'unmarshal with invalid format',    'invalid=format',        {} ],
        [ 'unmarshal with missing value',     'a=',                    {} ],
    );
    for my $tc (@tests) {
        my ( $name, $text, $want ) = @$tc;
        my $got = unmarshal_text($text);

        # Remove default keys for comparison
        for my $k ( keys %$got ) {
            if ( exists $want->{$k} ) {
                is $got->{$k}, $want->{$k}, "$name: $k";
            }
            else {
                ok 0, "$name: unexpected key $k";
            }
        }
        for my $k ( keys %$want ) {
            if ( !exists $got->{$k} ) {
                ok 0, "$name: missing key $k";
            }
        }
    }
};

sub unmarshal_text {
    my ($text) = @_;
    my $o = {};
    return $o if !length $text;
    for my $opt ( split /,/, $text ) {
        my ( $key, $val ) = split /=/, $opt, 2;
        next if !defined $val || $val eq '';
        if    ( $key eq 'a' ) { $o->{action}       = $val }
        elsif ( $key eq 'o' ) { $o->{compression}  = $val }
        elsif ( $key eq 't' ) { $o->{transmission} = $val }
        elsif ( $key eq 'd' ) {
            my $d = $val;
            if ( $d =~ /^[A-Z]$/ ) {
                $o->{delete_resources} = 1;
                $d = lc($d);
            }
            $o->{delete} = $d;
        }
        elsif ( $key =~ /^(?:i|q|p|I|f|s|v|S|O|m|x|y|z|w|h|X|Y|c|r|U|P|Q)$/ ) {
            if ( $val =~ /^\d+$/ ) {
                my $v = 0 + $val;
                if    ( $key eq 'i' ) { $o->{id}                  = $v }
                elsif ( $key eq 'q' ) { $o->{quiet}               = $v }
                elsif ( $key eq 'p' ) { $o->{placement_id}        = $v }
                elsif ( $key eq 'I' ) { $o->{number}              = $v }
                elsif ( $key eq 'f' ) { $o->{format}              = $v }
                elsif ( $key eq 's' ) { $o->{image_width}         = $v }
                elsif ( $key eq 'v' ) { $o->{image_height}        = $v }
                elsif ( $key eq 'S' ) { $o->{size}                = $v }
                elsif ( $key eq 'O' ) { $o->{offset}              = $v }
                elsif ( $key eq 'm' ) { $o->{chunk}               = $v }
                elsif ( $key eq 'x' ) { $o->{x}                   = $v }
                elsif ( $key eq 'y' ) { $o->{y}                   = $v }
                elsif ( $key eq 'z' ) { $o->{z}                   = $v }
                elsif ( $key eq 'w' ) { $o->{width}               = $v }
                elsif ( $key eq 'h' ) { $o->{height}              = $v }
                elsif ( $key eq 'X' ) { $o->{offset_x}            = $v }
                elsif ( $key eq 'Y' ) { $o->{offset_y}            = $v }
                elsif ( $key eq 'c' ) { $o->{columns}             = $v }
                elsif ( $key eq 'r' ) { $o->{rows}                = $v }
                elsif ( $key eq 'U' ) { $o->{virtual_placement}   = ( $v == 1 ) ? 1 : 0 }
                elsif ( $key eq 'P' ) { $o->{parent_id}           = $v }
                elsif ( $key eq 'Q' ) { $o->{parent_placement_id} = $v }
            }
        }
    }
    return $o;
}
done_testing;
