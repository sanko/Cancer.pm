use v5.42;

package Cancer::Color::Blend v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[
        blend_new blend_from_color blend_from_hsv
        to_rgb clamped
        blend_lab blend_hsl blend_hsv
        is_dark_color complementary darken lighten alpha
        blend_1d blend_2d
    ];

    # Minimal subset of lucasb-eyer/go-colorful needed by lipgloss.
    # Implements CIELAB blending, HSL/HSV conversion, and luminance detection.
    use constant PI => 4 * atan2( 1, 1 );

    # D65 white point (sRGB standard)
    my $D65_X = 0.95047;
    my $D65_Y = 1.00000;
    my $D65_Z = 1.08883;

    sub _clamp ( $v, $lo = 0, $hi = 1 ) {
        return $lo if $v < $lo;
        return $hi if $v > $hi;
        return $v;
    }

    # sRGB gamma: linear -> sRGB
    sub _linear_to_srgb ($c) {
        return $c <= 0.0031308 ? 12.92 * $c : 1.055 * ( $c**( 1.0 / 2.4 ) ) - 0.055;
    }

    # sRGB gamma: sRGB -> linear
    sub _srgb_to_linear ($c) {
        return $c <= 0.04045 ? $c / 12.92 : ( ( $c + 0.055 ) / 1.055 )**2.4;
    }

    # --- Constructor / conversion ---
    # Create from 0-255 RGB values (like colorful.Color)
    sub blend_new ( $class, $r, $g, $b ) {
        return bless { R => $r / 255.0, G => $g / 255.0, B => $b / 255.0 }, $class;
    }

    # Convert from a color-like hashref {r,g,b} (0-255) or arrayref [r,g,b]
    # Also handles blessed color objects with ->RGBA() method (lipgloss colors)
    sub blend_from_color ($c) {
        if ( ref $c && ref $c ne 'HASH' && ref $c ne 'ARRAY' ) {

            # Already-normalized colorful-style objects pass through
            # untouched; re-scaling them would crush chained blends to black.
            return bless { R => $c->{R}, G => $c->{G}, B => $c->{B} }, __PACKAGE__
                if defined $c->{R} && defined $c->{G} && defined $c->{B} && ref($c) eq __PACKAGE__;
            if ( defined $c->{R} && defined $c->{G} && defined $c->{B} ) {
                return bless { R => $c->{R} / 255.0, G => $c->{G} / 255.0, B => $c->{B} / 255.0 }, __PACKAGE__;
            }
            if ( $c->can('RGBA') ) {
                my ( $r, $g, $b ) = $c->RGBA;
                my $scale = ( $r > 1 || $g > 1 || $b > 1 ) ? 65535.0 : 255.0;
                return bless { R => ( $r // 0 ) / $scale, G => ( $g // 0 ) / $scale, B => ( $b // 0 ) / $scale }, __PACKAGE__;
            }
        }
        if ( ref $c eq 'HASH' ) {
            return bless {
                R => ( $c->{r} // $c->{R} // 0 ) / 255.0,
                G => ( $c->{g} // $c->{G} // 0 ) / 255.0,
                B => ( $c->{b} // $c->{B} // 0 ) / 255.0
                },
                __PACKAGE__;
        }
        if ( ref $c eq 'ARRAY' ) {
            return bless { R => ( $c->[0] // 0 ) / 255.0, G => ( $c->[1] // 0 ) / 255.0, B => ( $c->[2] // 0 ) / 255.0 }, __PACKAGE__;
        }
        return bless { R => 0, G => 0, B => 0 }, __PACKAGE__;
    }

    # Create from HSV (h=0..360, s=0..1, v=0..1)
    sub blend_from_hsv ( $h, $s, $v ) {
        $h = $h % 360;
        my $c = $v * $s;
        my $x = $c * ( 1 - abs( ( $h / 60 ) % 2 - 1 ) );
        my $m = $v - $c;
        my ( $r, $g, $b );
        if    ( $h < 60 )  { ( $r, $g, $b ) = ( $c, $x, 0 ) }
        elsif ( $h < 120 ) { ( $r, $g, $b ) = ( $x, $c, 0 ) }
        elsif ( $h < 180 ) { ( $r, $g, $b ) = ( 0, $c, $x ) }
        elsif ( $h < 240 ) { ( $r, $g, $b ) = ( 0, $x, $c ) }
        elsif ( $h < 300 ) { ( $r, $g, $b ) = ( $x, 0, $c ) }
        else               { ( $r, $g, $b ) = ( $c, 0, $x ) }
        return bless { R => $r + $m, G => $g + $m, B => $b + $m }, __PACKAGE__;
    }

    # Return (r, g, b) as 0-255 integers, matching Go's RGBA() >> 8 path
    sub to_rgb ($self) {
        return ( int( $self->{R} * 65535 + 0.5 ) >> 8, int( $self->{G} * 65535 + 0.5 ) >> 8, int( $self->{B} * 65535 + 0.5 ) >> 8 );
    }

    # RGBA method for Lipgloss compatibility (returns 0-255 ints via Go's path)
    sub RGBA {
        my $self = $_[0];
        return ( int( $self->{R} * 65535 + 0.5 ) >> 8, int( $self->{G} * 65535 + 0.5 ) >> 8, int( $self->{B} * 65535 + 0.5 ) >> 8, 255 );
    }

    # Clamp values to 0-1
    sub clamped ($self) {
        return bless { R => _clamp( $self->{R} ), G => _clamp( $self->{G} ), B => _clamp( $self->{B} ) }, ref $self;
    }

    # Round-trip through the 16-bit RGBA grid, like Go's
    # colorful.MakeColor(colorful.Color) does before blending.
    sub _quantize16 ($self) {
        return bless {
            R => CORE::int( $self->{R} * 65535.0 + 0.5 ) / 65535.0,
            G => CORE::int( $self->{G} * 65535.0 + 0.5 ) / 65535.0,
            B => CORE::int( $self->{B} * 65535.0 + 0.5 ) / 65535.0
            },
            ref $self;
    }

    # --- RGB -> XYZ (D65) ---
    # Coefficients from go-colorful (IEC 61966-2-1 sRGB, full double precision)
    sub _to_xyz ($self) {
        my $rl = _srgb_to_linear( $self->{R} );
        my $gl = _srgb_to_linear( $self->{G} );
        my $bl = _srgb_to_linear( $self->{B} );
        return (
            0.41239079926595948 * $rl + 0.35758433938387796 * $gl + 0.18048078840183429 * $bl,
            0.21263900587151036 * $rl + 0.71516867876775593 * $gl + 0.072192315360733715 * $bl,
            0.019330818715591851 * $rl + 0.11919477979462599 * $gl + 0.95053215224966058 * $bl
        );
    }

    # --- XYZ -> Lab ---
    # go-colorful uses math.Cbrt; refine exp(log/3) with Newton iterations
    # so the result matches Go's fdlibm cbrt to within an ulp.
    sub _cbrt ($x) {
        return 0.0 if $x == 0;
        my $r = CORE::exp( CORE::log($x) / 3.0 );
        $r = $r - ( $r * $r * $r - $x ) / ( 3.0 * $r * $r );
        $r = $r - ( $r * $r * $r - $x ) / ( 3.0 * $r * $r );
        return $r;
    }

    sub _lab_f ($t) {
        return _cbrt($t) if $t > ( 6.0 / 29.0 )**3;
        return $t / ( 3.0 * ( 6.0 / 29.0 )**2 ) + 4.0 / 29.0;
    }

    sub _xyz_to_lab ( $x, $y, $z ) {
        my $fx = _lab_f( $x / $D65_X );
        my $fy = _lab_f( $y / $D65_Y );
        my $fz = _lab_f( $z / $D65_Z );
        return ( 1.16 * $fy - 0.16, 5.0 * ( $fx - $fy ), 2.0 * ( $fy - $fz ) );
    }

    # --- Lab -> XYZ ---
    sub _lab_finv ($t) {
        return $t * $t * $t if $t > 6.0 / 29.0;
        return 3.0 * ( 6.0 / 29.0 )**2 * ( $t - 4.0 / 29.0 );
    }

    sub _lab_to_xyz ( $l, $a, $b ) {
        my $l2 = ( $l + 0.16 ) / 1.16;
        my $fx = $l2 + $a / 5.0;
        my $fy = $l2;
        my $fz = $l2 - $b / 2.0;
        return ( $D65_X * _lab_finv($fx), $D65_Y * _lab_finv($fy), $D65_Z * _lab_finv($fz) );
    }

    # --- XYZ -> linear RGB ---
    # Coefficients from go-colorful (IEC 61966-2-1 sRGB, full double precision)
    sub _xyz_to_linear_rgb ( $x, $y, $z ) {
        return (
            3.2409699419045214 * $x - 1.5373831775700935 * $y - 0.49861076029300328 * $z,
            -0.96924363628087983 * $x + 1.8759675015077207 * $y + 0.041555057407175613 * $z,
            0.055630079696993609 * $x - 0.20397695888897657 * $y + 1.0569715142428786 * $z
        );
    }

    # --- Lab -> RGB color ---
    sub _lab_to_color ( $l, $a, $b ) {
        my ( $x,  $y,  $z )  = _lab_to_xyz( $l, $a, $b );
        my ( $rl, $gl, $bl ) = _xyz_to_linear_rgb( $x, $y, $z );
        return bless { R => _clamp( _linear_to_srgb($rl) ), G => _clamp( _linear_to_srgb($gl) ), B => _clamp( _linear_to_srgb($bl) ) }, __PACKAGE__;
    }

    # --- CIELAB interpolation ---
    sub blend_lab ( $self, $to, $t ) {
        my ( $l1, $a1, $b1 ) = _xyz_to_lab( _to_xyz($self) );
        my ( $l2, $a2, $b2 ) = _xyz_to_lab( _to_xyz($to) );
        return _lab_to_color( $l1 + ( $l2 - $l1 ) * $t, $a1 + ( $a2 - $a1 ) * $t, $b1 + ( $b2 - $b1 ) * $t );
    }

    # --- RGB -> HSL ---
    sub blend_hsl ($self) {
        my ( $r, $g, $b ) = ( $self->{R}, $self->{G}, $self->{B} );
        my $max = $r > $g ? ( $r > $b ? $r : $b ) : ( $g > $b ? $g : $b );
        my $min = $r < $g ? ( $r < $b ? $r : $b ) : ( $g < $b ? $g : $b );
        my $l   = ( $max + $min ) / 2.0;
        if ( $max == $min ) {
            return ( 0, 0, $l );    # achromatic
        }
        my $d = $max - $min;
        my $s = $l > 0.5 ? $d / ( 2.0 - $max - $min ) : $d / ( $max + $min );
        my $h;
        if ( $max == $r ) {
            $h = ( $g - $b ) / $d;
            $h += 6 if $g < $b;
        }
        elsif ( $max == $g ) {
            $h = ( $b - $r ) / $d + 2;
        }
        else {
            $h = ( $r - $g ) / $d + 4;
        }
        $h /= 6.0;
        return ( $h, $s, $l );
    }

    # --- RGB -> HSV ---
    sub blend_hsv ($self) {
        my ( $r, $g, $b ) = ( $self->{R}, $self->{G}, $self->{B} );
        my $max = $r > $g ? ( $r > $b ? $r : $b ) : ( $g > $b ? $g : $b );
        my $min = $r < $g ? ( $r < $b ? $r : $b ) : ( $g < $b ? $g : $b );
        my $d   = $max - $min;
        my $v   = $max;
        my $s   = $max == 0 ? 0 : $d / $max;
        if ( $d == 0 ) {
            return ( 0, $s, $v );    # achromatic
        }
        my $h;
        if ( $max == $r ) {
            $h = ( $g - $b ) / $d;
            $h += 6 if $g < $b;
        }
        elsif ( $max == $g ) {
            $h = ( $b - $r ) / $d + 2;
        }
        else {
            $h = ( $r - $g ) / $d + 4;
        }
        $h *= 60;
        return ( $h, $s, $v );
    }

    # --- Dark detection (HSL luminance) ---
    sub is_dark_color ($c) {
        my $color = ref $c ? $c : blend_from_color($c);
        my ( undef, undef, $l ) = blend_hsl($color);
        return $l < 0.5;
    }

    # --- Complementary color (180 deg on HSV wheel) ---
    sub complementary ($c) {
        my $color = ref $c ? $c : blend_from_color($c);
        my ( $h, $s, $v ) = blend_hsv($color);
        $h += 180;
        $h -= 360 if $h >= 360;
        $h += 360 if $h < 0;
        return blend_from_hsv( $h, $s, $v )->clamped;
    }

    # --- Darken (multiply RGB by 1-percent) ---
    sub darken ( $c, $percent ) {
        my $blend = blend_from_color($c);
        my $mult  = 1.0 - _clamp($percent);
        return bless { R => _clamp( $blend->{R} * $mult ), G => _clamp( $blend->{G} * $mult ), B => _clamp( $blend->{B} * $mult ) }, ref($blend);
    }

    # --- Lighten (add white proportionally) ---
    sub lighten ( $c, $percent ) {
        my $blend = blend_from_color($c);
        my $add   = _clamp($percent);
        return bless {
            R => _clamp( $blend->{R} + ( 1 - $blend->{R} ) * $add ),
            G => _clamp( $blend->{G} + ( 1 - $blend->{G} ) * $add ),
            B => _clamp( $blend->{B} + ( 1 - $blend->{B} ) * $add )
            },
            ref($blend);
    }

    # --- Alpha (set opacity, 0=transparent, 1=opaque) ---
    sub alpha ( $c, $a ) {
        my $blend = blend_from_color($c);
        return bless { R => $blend->{R}, G => $blend->{G}, B => $blend->{B}, A => _clamp($a) }, ref($blend);
    }

    # --- 1D gradient blending (CIELAB) ---
    sub blend_1d ( $steps, @stops ) {
        return () if $steps <= 0;
        @stops = grep {defined} @stops;
        return () unless @stops;
        if ( $steps <= scalar @stops ) {
            return [ @stops[ 0 .. $steps - 1 ] ];
        }
        if ( @stops == 1 ) {
            return [ ( $stops[0] ) x $steps ];
        }
        my @cstops       = map { blend_from_color($_)->_quantize16 } @stops;
        my $num_segments = @cstops - 1;
        my $default_size = int( $steps / $num_segments );
        my $remaining    = $steps % $num_segments;
        my @blended;
        my $idx = 0;
        for my $i ( 0 .. $num_segments - 1 ) {
            my $seg_size = $default_size + ( $i < $remaining ? 1 : 0 );
            my $divisor  = $seg_size > 1 ? $seg_size - 1 : 1;
            for my $j ( 0 .. $seg_size - 1 ) {
                my $t = $seg_size > 1 ? $j / $divisor : 0;
                $blended[ $idx++ ] = $cstops[$i]->blend_lab( $cstops[ $i + 1 ], $t )->clamped;
            }
        }
        return \@blended;
    }

    # --- 2D gradient blending ---
    sub blend_2d ( $width, $height, $angle, @stops ) {
        $width  = 1 if $width < 1;
        $height = 1 if $height < 1;
        $angle  = $angle % 360;
        $angle += 360 if $angle < 0;
        @stops = grep {defined} @stops;
        return () unless @stops;
        if ( @stops == 1 ) {
            return [ ( $stops[0] ) x ( $width * $height ) ];
        }
        my $diag_gradient = blend_1d( $width > $height ? $width : $height, @stops );
        my @result;
        my $center_x  = ( $width - 1 ) / 2.0;
        my $center_y  = ( $height - 1 ) / 2.0;
        my $angle_rad = $angle * PI / 180.0;
        my $cos_a     = cos($angle_rad);
        my $sin_a     = sin($angle_rad);
        my $diag_len  = sqrt( $width * $width + $height * $height );
        my $grad_len  = @$diag_gradient - 1;

        for my $y ( 0 .. $height - 1 ) {
            my $dy = $y - $center_y;
            for my $x ( 0 .. $width - 1 ) {
                my $dx    = $x - $center_x;
                my $rot_x = $dx * $cos_a - $dy * $sin_a;
                my $pos   = _clamp( ( $rot_x + $diag_len / 2.0 ) / $diag_len );
                my $gi    = int( $pos * $grad_len );
                $gi = $grad_len if $gi >= $grad_len;
                $result[ $y * $width + $x ] = $diag_gradient->[$gi];
            }
        }
        return \@result;
    }
}
1;
