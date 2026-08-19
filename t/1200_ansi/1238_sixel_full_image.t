use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Port of TestFullImage from charmbracelet/x/ansi/sixel/sixel_test.go
# Inline encoder/decoder for sixel round-trip validation.
use Cancer::Ansi::Sixel qw(WriteRaster DecodeRaster DecodeRepeat);

# SixelColor  (channels 0-100)
package SixelColor {
    use v5.42;
    sub new( $c, $r, $g, $b, $a ) { bless { r => $r // 0, g => $g // 0, b => $b // 0, a => $a // 0 }, $c }
    sub r($s)            { $s->{r} // 0 }
    sub g($s)            { $s->{g} // 0 }
    sub b($s)            { $s->{b} // 0 }
    sub a($s)            { $s->{a} // 0 }
    sub equals( $s, $o ) { $s->{r} == $o->{r} && $s->{g} == $o->{g} && $s->{b} == $o->{b} && $s->{a} == $o->{a} }
    sub clone($s)        { bless { r => $s->{r}, g => $s->{g}, b => $s->{b}, a => $s->{a} }, ref $s }
}

# Color conversion  (8-bit RGBA -> sixelColor 0-100)
sub _convert_channel ($ch) { int( ( $ch * 257 + 328 ) * 100 / 0xffff ) }

sub _convert_color ( $r, $g, $b, $a ) {
    SixelColor->new( _convert_channel($r), _convert_channel($g), _convert_channel($b), _convert_channel($a) );
}
sub _ckey ($c) { pack 'V4', $c->{r} // 0, $c->{g} // 0, $c->{b} // 0, $c->{a} // 0 }

# Median-cut palette (simplified for test images)
package QCube {
    use v5.42;
    sub new( $c, %a ) { bless { start => 0, len => 0, ch => 'r', score => 0, pixels => 0, %a }, $c }
}

package CubeHeap {
    use v5.42;
    sub new($c) { bless [], $c }

    sub push( $h, $cube ) {
        push @$h, $cube;
        @$h = sort { $b->{score} <=> $a->{score} } @$h;
    }
    sub pop($h) { shift @$h }
    sub len($h) { scalar @$h }
}

sub _create_cube ( $colors, $pixel_counts, $start, $len ) {
    my ( $min_r, $min_g, $min_b, $min_a ) = (0xffffffff) x 4;
    my ( $max_r, $max_g, $max_b, $max_a ) = (0) x 4;
    my $total = 0;
    for my $i ( $start .. $start + $len - 1 ) {
        my $c = $colors->[$i];
        my $r = $c->{r} // 0;
        $min_r = $r if $r < $min_r;
        $max_r = $r if $r > $max_r;
        my $g = $c->{g} // 0;
        $min_g = $g if $g < $min_g;
        $max_g = $g if $g > $max_g;
        my $b = $c->{b} // 0;
        $min_b = $b if $b < $min_b;
        $max_b = $b if $b > $max_b;
        my $a = $c->{a} // 0;
        $min_a = $a if $a < $min_a;
        $max_a = $a if $a > $max_a;
        $total += $pixel_counts->{ _ckey($c) };
    }
    my ( $dr, $dg, $db, $da ) = ( $max_r - $min_r, $max_g - $min_g, $max_b - $min_b, $max_a - $min_a );
    my $ch    = 'r';
    my $score = $dr;
    if    ( $dg >= $dr && $dg >= $db && $dg >= $da ) { $ch = 'g'; $score = $dg }
    elsif ( $db >= $dr && $db >= $dg && $db >= $da ) { $ch = 'b'; $score = $db }
    elsif ( $da >= $dr && $da >= $dg && $da >= $db ) { $ch = 'a'; $score = $da }
    QCube->new( start => $start, len => $len, ch => $ch, score => $score * $total, pixels => $total );
}

sub _load_color ( $colors, $pixel_counts, $start, $len ) {
    my ( $tr, $tg, $tb, $ta, $tc ) = (0) x 5;
    for my $i ( $start .. $start + $len - 1 ) {
        my $c   = $colors->[$i];
        my $cnt = $pixel_counts->{ _ckey($c) };
        $tr += $c->{r} * $cnt;
        $tg += $c->{g} * $cnt;
        $tb += $c->{b} * $cnt;
        $ta += $c->{a} * $cnt;
        $tc += $cnt;
    }
    SixelColor->new( int( $tr / $tc ), int( $tg / $tc ), int( $tb / $tc ), int( $ta / $tc ) );
}

sub _quantize ( $colors, $pixel_counts, $max_colors ) {
    return [ map { $_->clone } @$colors ] if @$colors <= $max_colors;
    my $heap = CubeHeap->new;
    $heap->push( _create_cube( $colors, $pixel_counts, 0, scalar @$colors ) );
    while ( $heap->len < $max_colors ) {
        my $cube = $heap->pop;
        last if !$cube;
        my $ch    = $cube->ch;
        my @slice = sort { $a->{$ch} <=> $b->{$ch} } @{$colors}[ $cube->start .. $cube->start + $cube->len - 1 ];
        for my $i ( 0 .. $#slice ) { $colors->[ $cube->start + $i ] = $slice[$i] }
        my $target = int( $cube->pixels / 2 );
        my $count  = $pixel_counts->{ _ckey( $colors->[ $cube->start ] ) };
        my $left   = 1;

        for my $i ( $cube->start + 1 .. $cube->start + $cube->len - 1 ) {
            my $w = $pixel_counts->{ _ckey( $colors->[$i] ) };
            last if $count + $w > $target;
            $left++;
            $count += $w;
        }
        my $right  = $cube->len - $left;
        my $rstart = $cube->start + $left;
        $heap->push( _create_cube( $colors, $pixel_counts, $cube->start, $left ) );
        $heap->push( _create_cube( $colors, $pixel_counts, $rstart,      $right ) ) if $right > 0;
    }
    my @palette;
    while ( $heap->len > 0 ) { my $b = $heap->pop; last if !$b; push @palette, _load_color( $colors, $pixel_counts, $b->start, $b->len ) }
    \@palette;
}

sub _new_sixel_palette ( $img, $max_colors ) {
    my ( %counts, %seen );
    my @unique;
    for my $y ( 0 .. $img->{h} - 1 ) {
        for my $x ( 0 .. $img->{w} - 1 ) {
            my $c = _convert_color( $img->{data}[$y][$x][0], $img->{data}[$y][$x][1], $img->{data}[$y][$x][2], $img->{data}[$y][$x][3] );
            my $k = _ckey($c);
            $counts{$k}++;
            next if $seen{$k}++;
            push @unique, $c;
        }
    }
    my $palette = _quantize( \@unique, \%counts, $max_colors );
    my ( %convert, %indexes );
    for my $c (@unique) {
        my ( $best, $best_idx, $best_score );
        for my $i ( 0 .. $#$palette ) {
            my $pc = $palette->[$i];
            my $dr = $c->{r} - $pc->{r};
            my $dg = $c->{g} - $pc->{g};
            my $db = $c->{b} - $pc->{b};
            my $da = $c->{a} - $pc->{a};
            my $sc = $dr * $dr + $dg * $dg + $db * $db + $da * $da;
            ( !defined $best_score || $sc < $best_score ) and ( $best = $pc, $best_idx = $i, $best_score = $sc );
        }
        $convert{ _ckey($c) } = $best;
        $indexes{ _ckey($c) } = $best_idx;
    }
    { palette => $palette, convert => \%convert, indexes => \%indexes };
}

# Encoder
sub _band_masks ( $img, $band_y, $palette_idx, $indexes ) {
    my $w = $img->{w};
    my $h = $img->{h};
    my ( $has_any, @masks );
    for my $x ( 0 .. $w - 1 ) {
        my $mask = 0;
        for my $dy ( 0 .. 5 ) {
            my $y = $band_y * 6 + $dy;
            last if $y >= $h;
            my $p   = $img->{data}[$y][$x];
            my $sc  = _convert_color( $p->[0], $p->[1], $p->[2], $p->[3] );
            my $idx = $indexes->{ _ckey($sc) };
            if ( defined $idx && $idx == $palette_idx ) { $mask |= ( 1 << $dy ) }
        }
        $has_any = 1 if $mask;
        push @masks, $mask;
    }
    ( $has_any, @masks );
}

sub _encode_sixel ($img) {
    my $max     = 256;
    my $pal     = _new_sixel_palette( $img, $max );
    my $palette = $pal->{palette};
    my $indexes = $pal->{indexes};
    my $w       = $img->{w};
    my $h       = $img->{h};
    my @out;
    push @out, WriteRaster( 1, 1, $w, $h ) if $w > 0 && $h > 0;

    for my $i ( 0 .. $#$palette ) {
        my $c = $palette->[$i];
        next if $c->{a} < 1;
        push @out, sprintf( '#%d;2;%d;%d;%d', $i, $c->{r}, $c->{g}, $c->{b} );
    }
    my $band_h = int( ( $h + 5 ) / 6 );
    for my $by ( 0 .. $band_h - 1 ) {
        push @out, '-' if $by > 0;
        my $wrote_color = 0;
        for my $ci ( 0 .. $#$palette ) {
            next if $palette->[$ci]->{a} < 1;
            my ( $has, @masks ) = _band_masks( $img, $by, $ci, $indexes );
            next if !$has;
            push @out, '$' if $wrote_color;
            $wrote_color = 1;
            push @out, "#$ci";
            my $buf_ch  = '';
            my $buf_cnt = 0;

            for my $m (@masks) {
                my $ch = chr( ord('?') + $m );
                if    ( !$buf_cnt )      { $buf_ch = $ch; $buf_cnt = 1 }
                elsif ( $ch eq $buf_ch ) { $buf_cnt++ }
                else {
                    if   ( $buf_cnt > 3 ) { push @out, '!' . $buf_cnt . $buf_ch }
                    else                  { push @out, $buf_ch x $buf_cnt }
                    $buf_ch  = $ch;
                    $buf_cnt = 1;
                }
            }
            if   ( $buf_cnt > 3 ) { push @out, '!' . $buf_cnt . $buf_ch }
            else                  { push @out, $buf_ch x $buf_cnt }
        }
    }
    push @out, '-';
    join '', @out;
}

# Decoder
sub _decode_color ($data) {
    return ( undef, 0 ) if !length $data || ord( substr( $data, 0, 1 ) ) != ord('#');
    return ( undef, 0 ) if length $data < 2;
    my ( $pc, $pu, $px, $py, $pz ) = ( 0, 0, 0, 0, 0 );
    my $n     = 1;
    my $field = 0;
    while ( $n < length $data ) {
        my $c = substr $data, $n, 1;
        if ( $c eq ';' ) { $field++; $n++; next }
        last if $c !~ /[0-9]/;
        if    ( $field == 0 ) { $pc = $pc * 10 + ord($c) - 48 }
        elsif ( $field == 1 ) { $pu = $pu * 10 + ord($c) - 48 }
        elsif ( $field == 2 ) { $px = $px * 10 + ord($c) - 48 }
        elsif ( $field == 3 ) { $py = $py * 10 + ord($c) - 48 }
        elsif ( $field == 4 ) { $pz = $pz * 10 + ord($c) - 48 }
        $n++;
    }
    ( { pc => $pc, pu => $pu, px => $px, py => $py, pz => $pz }, $n );
}
sub _palval ( $n, $a, $m ) { int( ( $n * $a + $m / 2 ) / $m ) }

sub _sixel_rgb_to_rgba ( $r, $g, $b ) {
    ( int( _palval( $r, 255, 100 ) ) * 257, int( _palval( $g, 255, 100 ) ) * 257, int( _palval( $b, 255, 100 ) ) * 257, 0xFFFF );
}

sub _decode_sixel ($data) {
    return undef if !defined $data || $data eq '';
    my @d = unpack 'C*', $data;
    my ( $ph, $pv ) = ( 0, 0 );
    my $pos = 0;
    if ( @d && $d[0] == ord('"') ) {
        my ( $raster, $read ) = DecodeRaster($data);
        return undef if $read == 0;
        $ph  = $raster->Ph;
        $pv  = $raster->Pv;
        $pos = $read;
    }

    # palette: 256 entries, each [R,G,B,A] 16-bit
    my @palette = map { [ 0, 0, 0, 0 ] } ( 0 .. 255 );

    # Use default sixel colors for 0-15
    my @defaults = (
        [ 0,   0,   0 ],
        [ 51,  51,  204 ],
        [ 204, 36,  36 ],
        [ 51,  204, 51 ],
        [ 204, 51,  204 ],
        [ 51,  204, 204 ],
        [ 204, 204, 51 ],
        [ 120, 120, 120 ],
        [ 69,  69,  69 ],
        [ 87,  87,  153 ],
        [ 153, 69,  69 ],
        [ 87,  153, 87 ],
        [ 153, 87,  153 ],
        [ 87,  153, 153 ],
        [ 153, 153, 87 ],
        [ 204, 204, 204 ]
    );
    for my $i ( 0 .. 15 ) { my $d = $defaults[$i]; $palette[$i] = [ $d->[0] * 257, $d->[1] * 257, $d->[2] * 257, 0xFFFF ] }
    my ( $cur_pal_idx, $cur_x, $cur_band_y ) = ( 0, 0, 0 );
    my ( $max_x, $max_y ) = ( 0, 0 );
    my %pixels;
    while ( $pos < @d ) {
        my $b = $d[$pos];
        if ( $b == ord('-') ) {
            $cur_band_y++;
            $cur_x = 0;
            $pos++;
            next;
        }
        elsif ( $b == ord('$') ) {
            $cur_x = 0;
            $pos++;
            next;
        }
        elsif ( $b == ord('#') ) {
            my $rest = substr $data, $pos;
            my ( $c, $n ) = _decode_color($rest);
            $pos += $n;
            next if !$c;
            $cur_pal_idx = $c->{pc};
            if ( $c->{pu} > 0 && $c->{pu} == 2 ) {
                my ( $rr, $gg, $bb ) = _sixel_rgb_to_rgba( $c->{px}, $c->{py}, $c->{pz} );
                $palette[$cur_pal_idx] = [ $rr, $gg, $bb, 0xFFFF ];
            }
            next;
        }
        elsif ( $b == ord('!') ) {
            my $rest = substr $data, $pos;
            my ( $rpt, $n ) = DecodeRepeat($rest);
            $pos += $n;
            next if $n == 0;
            my $count = $rpt->Count;
            my $char  = ord( $rpt->Char );
            for ( 1 .. $count ) {
                my $mask  = ( $char - ord('?') ) & 63;
                my $y_off = 0;
                my $tmp   = $mask;
                while ($tmp) {
                    if ( $tmp & 1 ) {
                        my $yy = $cur_band_y * 6 + $y_off;
                        $pixels{"$cur_x,$yy"} = $palette[$cur_pal_idx];
                        $max_y = $yy if $yy > $max_y;
                    }
                    $y_off++;
                    $tmp >>= 1;
                }
                $max_x = $cur_x if $cur_x > $max_x;
                $cur_x++;
            }
            next;
        }
        elsif ( $b >= ord('?') && $b <= ord('~') ) {
            my $mask  = ( $b - ord('?') ) & 63;
            my $y_off = 0;
            while ($mask) {
                if ( $mask & 1 ) {
                    my $yy = $cur_band_y * 6 + $y_off;
                    $pixels{"$cur_x,$yy"} = $palette[$cur_pal_idx];
                    $max_y = $yy if $yy > $max_y;
                }
                $y_off++;
                $mask >>= 1;
            }
            $max_x = $cur_x if $cur_x > $max_x;
            $cur_x++;
        }
        $pos++;
    }
    my $img_w = $ph > 0 ? $ph : $max_x + 1;
    my $img_h = $pv > 0 ? $pv : $max_y + 1;
    my @image;
    for my $y ( 0 .. $img_h - 1 ) {
        my @row;
        for my $x ( 0 .. $img_w - 1 ) {
            my $k = "$x,$y";
            push @row, $pixels{$k} // [ 0, 0, 0, 0 ];
        }
        push @image, \@row;
    }
    { w => $img_w, h => $img_h, data => \@image };
}

# Test
sub _make_img ( $w, $h, $colors ) {

    # $colors: hash of index => [R,G,B,A]; unlisted indices inherit from previous
    my @data;
    my $cur = [ 0, 0, 0, 0 ];
    for my $y ( 0 .. $h - 1 ) {
        my @row;
        for my $x ( 0 .. $w - 1 ) {
            my $idx = $y * $w + $x;
            $cur = $colors->{$idx} if exists $colors->{$idx};
            my @c = map { $_ // 0 } @$cur;
            push @row, \@c;
        }
        push @data, \@row;
    }
    { w => $w, h => $h, data => \@data };
}
subtest 'TestFullImage' => sub {
    my @tests = (
        { name => '3x12 single color filled', w => 3, h => 12, band => 2, colors => { 0 => [ 255, 0, 0, 255 ] }, },
        {   name   => '3x12 two color filled',
            w      => 3,
            h      => 12,
            band   => 2,
            colors => { 0 => [ 0, 0, 255, 255 ], 9 => [ 0, 255, 0, 255 ], 18 => [ 0, 0, 255, 255 ], 27 => [ 0, 255, 0, 255 ], },
        },
        {   name   => '3x12 8 color with right gutter',
            w      => 3,
            h      => 12,
            band   => 2,
            colors => {
                0  => [ 255, 0,   0,   255 ],
                2  => [ 0,   255, 0,   255 ],
                3  => [ 255, 0,   0,   255 ],
                5  => [ 0,   255, 0,   255 ],
                6  => [ 255, 0,   0,   255 ],
                8  => [ 0,   255, 0,   255 ],
                9  => [ 0,   0,   255, 255 ],
                11 => [ 128, 128, 0,   255 ],
                12 => [ 0,   0,   255, 255 ],
                14 => [ 128, 128, 0,   255 ],
                15 => [ 0,   0,   255, 255 ],
                17 => [ 128, 128, 0,   255 ],
                18 => [ 0,   128, 128, 255 ],
                20 => [ 128, 0,   128, 255 ],
                21 => [ 0,   128, 128, 255 ],
                23 => [ 128, 0,   128, 255 ],
                24 => [ 0,   128, 128, 255 ],
                26 => [ 128, 0,   128, 255 ],
                27 => [ 64,  0,   0,   255 ],
                29 => [ 0,   64,  0,   255 ],
                30 => [ 64,  0,   0,   255 ],
                32 => [ 0,   64,  0,   255 ],
                33 => [ 64,  0,   0,   255 ],
                35 => [ 0,   64,  0,   255 ]
            },
        },
        {   name   => '3x12 single color with transparent band in the middle',
            w      => 3,
            h      => 12,
            band   => 2,
            colors => { 0 => [ 255, 0, 0, 255 ], 15 => [ 0, 0, 0, 0 ], 21 => [ 255, 0, 0, 255 ], },
        },
        { name => '3x5 single color',           w => 3,  h => 5,  band => 1, colors => { 0 => [ 255, 0, 0, 255 ] }, },
        { name => '12x4 single color use RLE',  w => 12, h => 4,  band => 1, colors => { 0 => [ 255, 0, 0, 255 ] }, },
        { name => '12x1 two color use RLE',     w => 12, h => 1,  band => 1, colors => { 0 => [ 255, 0, 0, 255 ], 6 => [ 0, 255, 0, 255 ] }, },
        { name => '12x12 single color use RLE', w => 12, h => 12, band => 2, colors => { 0 => [ 255, 0, 0, 255 ] }, },
    );
    for my $tt (@tests) {
        my $img     = _make_img( $tt->{w}, $tt->{h}, $tt->{colors} );
        my $sixel   = _encode_sixel($img);
        my $decoded = _decode_sixel($sixel);
        ok defined $decoded, "$tt->{name}: decode succeeded";
        is $decoded->{w}, $tt->{w}, "$tt->{name}: width match";
        is $decoded->{h}, $tt->{h}, "$tt->{name}: height match";
        my $ok = 1;
        for my $y ( 0 .. $tt->{h} - 1 ) {
            for my $x ( 0 .. $tt->{w} - 1 ) {
                my $orig = $img->{data}[$y][$x];
                my $got  = $decoded->{data}[$y][$x];

                # Go's color.RGBA.RGBA() returns 16-bit (each 8-bit * 257)
                my ( $or, $og, $ob, $oa ) = map { ( $_ // 0 ) * 257 } @$orig;
                my ( $gr, $gg, $gb, $ga ) = map { $_ // 0 } @$got;
                if ( $or != $gr || $og != $gg || $ob != $gb || $oa != $ga ) {
                    ok 0, "$tt->{name}: pixel ($x,$y) expected ($or,$og,$ob,$oa) got ($gr,$gg,$gb,$ga)";
                    $ok = 0;
                    last;
                }
            }
            last if !$ok;
        }
        ok $ok, "$tt->{name}: all pixels match";
    }
};
#
done_testing;
