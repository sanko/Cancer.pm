use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Port of charmbracelet/x/ansi/sixel/palette_test.go
# Inline median-cut color quantization + palette consistency tests.
# -------------------------------------------------------------------
# Helpers: sixelColor  (channels 0–100)
# -------------------------------------------------------------------
sub _sc ( $r, $g, $b, $a ) { bless { r => $r // 0, g => $g // 0, b => $b // 0, a => $a // 0 }, 'SixelColor' }

package SixelColor {
    use v5.42;
    sub new( $c, $r, $g, $b, $a ) { bless { r => $r // 0, g => $g // 0, b => $b // 0, a => $a // 0 }, $c }
    sub r($s)            { $s->{r} // 0 }
    sub g($s)            { $s->{g} // 0 }
    sub b($s)            { $s->{b} // 0 }
    sub a($s)            { $s->{a} // 0 }
    sub equals( $s, $o ) { $s->{r} == $o->{r} && $s->{g} == $o->{g} && $s->{b} == $o->{b} && $s->{a} == $o->{a} }
    sub clone($s)        { bless { r => $s->{r}, g => $s->{g}, b => $s->{b}, a => $s->{a} }, ref $s }
    sub stringify($s)    { sprintf '{R=%d G=%d B=%d A=%d}', $s->{r} // 0, $s->{g} // 0, $s->{b} // 0, $s->{a} // 0 }
}

# -------------------------------------------------------------------
# Channel conversion  (0xffff → 0–100)
# -------------------------------------------------------------------
sub _convert_channel ($ch) {
    return int( ( $ch + 328 ) * 100 / 0xffff );
}

sub _convert_color ( $r, $g, $b, $a ) {

    # RGBA.RGBA() in Go multiplies 8-bit by 257 to get 16-bit
    SixelColor->new( _convert_channel( $r * 257 ), _convert_channel( $g * 257 ), _convert_channel( $b * 257 ), _convert_channel( $a * 257 ), );
}

# -------------------------------------------------------------------
# Quantization cube
# -------------------------------------------------------------------
package QCube {
    use v5.42;
    sub new( $c, %args ) { bless { start => 0, len => 0, ch => 'r', score => 0, pixels => 0, %args }, $c }
    sub start($s)        { $s->{start}  // 0 }
    sub len($s)          { $s->{len}    // 0 }
    sub ch($s)           { $s->{ch}     // 'r' }
    sub score($s)        { $s->{score}  // 0 }
    sub pixels($s)       { $s->{pixels} // 0 }
}

# -------------------------------------------------------------------
# Priority queue (max-heap by score).  We keep an array and always
# pop the highest-score cube.  Insertion maintains sorted-by-score.
# -------------------------------------------------------------------
package CubeHeap {
    use v5.42;
    sub new($c) { bless [], $c }

    sub push( $h, $cube ) {
        push @$h, $cube;
        my $i = $#$h;
        while ( $i > 0 ) {
            my $p = int( ( $i - 1 ) / 2 );
            last if $h->[$p]{score} >= $h->[$i]{score};
            @$h[ $p, $i ] = @$h[ $i, $p ];
            $i = $p;
        }
    }

    sub pop($h) {
        return undef if !@$h;
        my $top = shift @$h;

        # re-sort
        @$h = sort { $b->{score} <=> $a->{score} } @$h;
        return $top;
    }
    sub len($h) { scalar @$h }
}

# -------------------------------------------------------------------
# Median-cut quantization
# -------------------------------------------------------------------
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
    my $dr    = $max_r - $min_r;
    my $dg    = $max_g - $min_g;
    my $db    = $max_b - $min_b;
    my $da    = $max_a - $min_a;
    my $ch    = 'r';
    my $score = $dr;
    if    ( $dg >= $dr && $dg >= $db && $dg >= $da ) { $ch = 'g'; $score = $dg }
    elsif ( $db >= $dr && $db >= $dg && $db >= $da ) { $ch = 'b'; $score = $db }
    elsif ( $da >= $dr && $da >= $dg && $da >= $db ) { $ch = 'a'; $score = $da }
    $score *= $total;
    return QCube->new( start => $start, len => $len, ch => $ch, score => $score, pixels => $total );
}

# String key for pixel-counts hash
sub _ckey ($c) { pack 'V4', $c->{r} // 0, $c->{g} // 0, $c->{b} // 0, $c->{a} // 0 }

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
    return SixelColor->new( int( $tr / $tc ), int( $tg / $tc ), int( $tb / $tc ), int( $ta / $tc ) );
}

sub _quantize ( $colors, $pixel_counts, $max_colors ) {
    if ( @$colors <= $max_colors ) {
        return [ map { $_->clone } @$colors ];
    }
    my $heap = CubeHeap->new;
    $heap->push( _create_cube( $colors, $pixel_counts, 0, scalar @$colors ) );
    while ( $heap->len < $max_colors ) {
        my $cube = $heap->pop;
        last if !defined $cube;

        # Sort the cube's range
        my $ch    = $cube->ch;
        my @slice = sort { $a->{$ch} <=> $b->{$ch} } @{$colors}[ $cube->start .. $cube->start + $cube->len - 1 ];
        for my $i ( 0 .. $#slice ) {
            $colors->[ $cube->start + $i ] = $slice[$i];
        }

        # Split: find the point where ~half the pixels are on the left
        my $pixels = $pixel_counts;
        my $target = int( $cube->pixels / 2 );
        my $count  = $pixels->{ _ckey( $colors->[ $cube->start ] ) };
        my $left   = 1;
        for my $i ( $cube->start + 1 .. $cube->start + $cube->len - 1 ) {
            my $w = $pixels->{ _ckey( $colors->[$i] ) };
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
    while ( $heap->len > 0 ) {
        my $b = $heap->pop;
        last if !defined $b;
        push @palette, _load_color( $colors, $pixel_counts, $b->start, $b->len );
    }
    return \@palette;
}

# -------------------------------------------------------------------
# new_sixel_palette — public entry point
# -------------------------------------------------------------------
sub _new_sixel_palette ( $img, $max_colors ) {
    my @pixels;
    for my $y ( 0 .. $img->{h} - 1 ) {
        for my $x ( 0 .. $img->{w} - 1 ) {
            my $p = $img->{data}[$y][$x];
            push @pixels, _convert_color( $p->[0], $p->[1], $p->[2], $p->[3] );
        }
    }
    my ( %counts, %seen );
    my @unique;
    for my $c (@pixels) {
        my $k = _ckey($c);
        $counts{$k}++;
        next if $seen{$k}++;
        push @unique, $c;
    }
    my $palette = _quantize( \@unique, \%counts, $max_colors );

    # Build colorConvert and paletteIndexes
    my ( %color_convert, %palette_indexes );
    for my $c (@unique) {
        my ( $best, $best_idx, $best_score );
        for my $i ( 0 .. $#$palette ) {
            my $pc = $palette->[$i];
            my $dr = $c->{r} - $pc->{r};
            my $dg = $c->{g} - $pc->{g};
            my $db = $c->{b} - $pc->{b};
            my $da = $c->{a} - $pc->{a};
            my $sc = $dr * $dr + $dg * $dg + $db * $db + $da * $da;
            if ( !defined $best_score || $sc < $best_score ) {
                $best       = $pc;
                $best_idx   = $i;
                $best_score = $sc;
            }
        }
        $color_convert{ _ckey($c) }   = $best;
        $palette_indexes{ _ckey($c) } = $best_idx;
    }
    return { palette => $palette, convert => \%color_convert, indexes => \%palette_indexes, };
}

# -------------------------------------------------------------------
# Test helpers
# -------------------------------------------------------------------
sub _make_img ( $w, $h, $pixels ) {
    my @data;
    for my $y ( 0 .. $h - 1 ) {
        my @row;
        for my $x ( 0 .. $w - 1 ) {
            my $idx = $y * $w + $x;
            push @row, $pixels->[$idx];
        }
        push @data, \@row;
    }
    return { w => $w, h => $h, data => \@data };
}

sub _sc_equal ( $a, $b ) {
    return $a->{r} == $b->{r} && $a->{g} == $b->{g} && $a->{b} == $b->{b} && $a->{a} == $b->{a};
}

sub _sc_in ( $c, $list ) {
    for my $l (@$list) { return 1 if _sc_equal( $c, $l ) }
    return 0;
}

# -------------------------------------------------------------------
# Tests
# -------------------------------------------------------------------
subtest 'TestPaletteCreationRedGreen' => sub {
    my $img = _make_img(
        2, 2,
        [   [ 255, 0,   0, 255 ],    # (0,0) red
            [ 128, 0,   0, 255 ],    # (0,1) dark red
            [ 0,   255, 0, 255 ],    # (1,0) green
            [ 0,   128, 0, 255 ],    # (1,1) dark green
        ]
    );
    my $expected_palettes = {
        'way too many colors'             => [ _sc( 100, 0, 0, 100 ), _sc( 50, 0, 0, 100 ), _sc( 0, 100, 0, 100 ), _sc( 0, 50, 0, 100 ), ],
        'just the right number of colors' => [ _sc( 100, 0, 0, 100 ), _sc( 50, 0, 0, 100 ), _sc( 0, 100, 0, 100 ), _sc( 0, 50, 0, 100 ), ],
        'color reduction'                 => [ _sc( 75, 0, 0, 100 ), _sc( 0, 75, 0, 100 ), ],
    };
    for my $name ( sort keys %$expected_palettes ) {
        my $expect   = $expected_palettes->{$name};
        my $max      = scalar @$expect;
        my $max_show = $name eq 'way too many colors' ? 16 : $max;
        my $result   = _new_sixel_palette( $img, $max_show );
        my $pal      = $result->{palette};
        ok scalar(@$pal) == scalar(@$expect), "$name: palette count (got " . scalar(@$pal) . ", want " . scalar(@$expect) . ")";
        for my $ec (@$expect) {
            ok _sc_in( $ec, $pal ), "$name: expected color " . $ec->stringify . " in palette";
        }
        for my $k ( keys %{ $result->{convert} } ) {
            my $mapped = $result->{convert}{$k};
            my $idx    = $result->{indexes}{$k};
            ok defined $idx,                       "$name: color has palette index";
            ok $idx >= 0 && $idx < @$pal,          "$name: palette index $idx in range";
            ok _sc_equal( $pal->[$idx], $mapped ), "$name: palette[$idx] matches mapped color";
        }
    }
};
subtest 'TestPaletteWithSemiTransparency' => sub {
    my $img = _make_img(
        2, 2,
        [   [ 0, 0, 255, 255 ],    # (0,0) blue
            [ 0, 0, 128, 255 ],    # (0,1) dark blue
            [ 0, 0, 255, 128 ],    # (1,0) semi-transparent blue
            [ 0, 0, 255, 0 ],      # (1,1) fully transparent blue
        ]
    );
    my $expected = {
        'just the right number of colors' => [ _sc( 0, 0, 100, 100 ), _sc( 0, 0, 50,  100 ), _sc( 0, 0, 100, 50 ), _sc( 0, 0, 100, 0 ), ],
        'color reduction'                 => [ _sc( 0, 0, 75,  100 ), _sc( 0, 0, 100, 25 ), ],
    };
    for my $name ( sort keys %$expected ) {
        my $expect = $expected->{$name};
        my $max    = scalar @$expect;
        my $result = _new_sixel_palette( $img, $max );
        my $pal    = $result->{palette};
        ok scalar(@$pal) == scalar(@$expect), "$name: palette count (got " . scalar(@$pal) . ", want " . scalar(@$expect) . ")";
        for my $ec (@$expect) {
            ok _sc_in( $ec, $pal ), "$name: expected color " . $ec->stringify . " in palette";
        }
        for my $k ( keys %{ $result->{convert} } ) {
            my $mapped = $result->{convert}{$k};
            my $idx    = $result->{indexes}{$k};
            ok defined $idx,                       "$name: color has palette index";
            ok $idx >= 0 && $idx < @$pal,          "$name: palette index $idx in range";
            ok _sc_equal( $pal->[$idx], $mapped ), "$name: palette[$idx] matches mapped color";
        }
    }
};
done_testing;
