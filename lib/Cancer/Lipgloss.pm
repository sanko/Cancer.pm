use v5.42;

package Cancer::Lipgloss v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[
        NewStyle NoColor Color LightDark Complete AdaptiveColor
        NormalBorder RoundedBorder BlockBorder ThickBorder DoubleBorder
        HiddenBorder MarkdownBorder ASCIIBorder NoBorder
        OuterHalfBlockBorder InnerHalfBlockBorder
        Left Center Right Top Bottom
        JoinHorizontal JoinVertical Place PlaceHorizontal PlaceVertical
        StyleRanges NewRange StyleRunes
        blend_1d blend_2d
        has_dark_background query_terminal_bg
        NBSP
        string_width width height
        Print Println Printf Fprint Fprintln Fprintf Sprint Sprintln Sprintf
        NewCanvas NewLayer NewLayerHit NewCompositor
        WithWhitespaceStyle WithWhitespaceChars
        Black Red Green Yellow Blue Magenta Cyan White
        BrightBlack BrightRed BrightGreen BrightYellow BrightBlue BrightMagenta BrightCyan BrightWhite
        UnderlineNone UnderlineSingle UnderlineDouble UnderlineCurly UnderlineDotted UnderlineDashed
        NoTabConversion
    ];
    use Carp         qw[carp];
    use Scalar::Util qw[blessed];
    use Cancer::Ansi qw[
        x_parse_color
        set_hyperlink reset_hyperlink
        request_background_color
    ];
    use Cancer::CellBuf::Wrap qw[wrap_text];
    use Cancer::Color::Blend  qw[
        blend_new blend_from_color blend_from_hsv blend_lab
        blend_hsl blend_hsv to_rgb clamped
        is_dark_color complementary darken lighten alpha blend_1d blend_2d
    ];
    use Cancer::ColorProfile qw[:constants];
    use Cancer::Util         qw[string_width grapheme_width width height];
    use Cancer::Util         qw[visual_truncate];
    use Cancer::Lipgloss::Canvas;
    use Cancer::Lipgloss::Layer;
    use Cancer::Lipgloss::Compositor;
    use utf8;

    # ---- Constants ------------------------------------------------------------------------------------------------------------
    use constant NBSP              => 0x00A0;
    use constant TAB_WIDTH_DEFAULT => 4;
    use constant NoTabConversion   => -1;

    # ---- Basic color constants ----------------------------------------------------------------------------------
    use constant Black         => 0;
    use constant Red           => 1;
    use constant Green         => 2;
    use constant Yellow        => 3;
    use constant Blue          => 4;
    use constant Magenta       => 5;
    use constant Cyan          => 6;
    use constant White         => 7;
    use constant BrightBlack   => 8;
    use constant BrightRed     => 9;
    use constant BrightGreen   => 10;
    use constant BrightYellow  => 11;
    use constant BrightBlue    => 12;
    use constant BrightMagenta => 13;
    use constant BrightCyan    => 14;
    use constant BrightWhite   => 15;

    # ---- Underline style constants --------------------------------------------------------------------------
    use constant UnderlineNone   => 0;
    use constant UnderlineSingle => 1;
    use constant UnderlineDouble => 2;
    use constant UnderlineCurly  => 3;
    use constant UnderlineDotted => 4;
    use constant UnderlineDashed => 5;

    # ---- Position enum ----------------------------------------------------------------------------------------------------
    # Position is a float64 (0.0=Left/Top, 0.5=Center, 1.0=Right/Bottom)
    # matching Go lipgloss Position type.
    use constant { Left => 0.0, Center => 0.5, Right => 1.0, Top => 0.0, Bottom => 1.0 };

    sub _pos_value ($p) {
        $p = 0 if $p < 0;
        $p = 1 if $p > 1;
        return $p;
    }

    # ---- Property keys (bitmask) --------------------------------------------------------------------------------
    # Boolean props
    use constant {
        BOLD_KEY                 => 1 << 0,
        ITALIC_KEY               => 1 << 1,
        STRIKETHROUGH_KEY        => 1 << 2,
        REVERSE_KEY              => 1 << 3,
        BLINK_KEY                => 1 << 4,
        FAINT_KEY                => 1 << 5,
        UNDERLINE_SPACES_KEY     => 1 << 6,
        STRIKETHROUGH_SPACES_KEY => 1 << 7,
        COLOR_WHITESPACE_KEY     => 1 << 8
    };

    # Value props
    use constant {
        UNDERLINE_KEY              => 1 << 9,
        FOREGROUND_KEY             => 1 << 10,
        BACKGROUND_KEY             => 1 << 11,
        UNDERLINE_COLOR_KEY        => 1 << 12,
        WIDTH_KEY                  => 1 << 13,
        HEIGHT_KEY                 => 1 << 14,
        ALIGN_HORIZONTAL_KEY       => 1 << 15,
        ALIGN_VERTICAL_KEY         => 1 << 16,
        PADDING_TOP_KEY            => 1 << 17,
        PADDING_RIGHT_KEY          => 1 << 18,
        PADDING_BOTTOM_KEY         => 1 << 19,
        PADDING_LEFT_KEY           => 1 << 20,
        PADDING_CHAR_KEY           => 1 << 21,
        MARGIN_TOP_KEY             => 1 << 22,
        MARGIN_RIGHT_KEY           => 1 << 23,
        MARGIN_BOTTOM_KEY          => 1 << 24,
        MARGIN_LEFT_KEY            => 1 << 25,
        MARGIN_BACKGROUND_KEY      => 1 << 26,
        MARGIN_CHAR_KEY            => 1 << 27,
        BORDER_STYLE_KEY           => 1 << 28,
        BORDER_TOP_KEY             => 1 << 29,
        BORDER_RIGHT_KEY           => 1 << 30,
        BORDER_BOTTOM_KEY          => 1 << 31,
        BORDER_LEFT_KEY            => 1 << 32,
        BORDER_TOP_FG_KEY          => 1 << 33,
        BORDER_RIGHT_FG_KEY        => 1 << 34,
        BORDER_BOTTOM_FG_KEY       => 1 << 35,
        BORDER_LEFT_FG_KEY         => 1 << 36,
        BORDER_BLEND_FG_KEY        => 1 << 37,
        BORDER_BLEND_FG_OFFSET_KEY => 1 << 38,
        BORDER_TOP_BG_KEY          => 1 << 39,
        BORDER_RIGHT_BG_KEY        => 1 << 40,
        BORDER_BOTTOM_BG_KEY       => 1 << 41,
        BORDER_LEFT_BG_KEY         => 1 << 42,
        INLINE_KEY                 => 1 << 43,
        MAX_WIDTH_KEY              => 1 << 44,
        MAX_HEIGHT_KEY             => 1 << 45,
        TAB_WIDTH_KEY              => 1 << 46,
        TRANSFORM_KEY              => 1 << 47,
        LINK_KEY                   => 1 << 48,
        LINK_PARAMS_KEY            => 1 << 49
    };

    # ---- NoColor ----------------------------------------------------------------------------------------------------------------
    package Cancer::Lipgloss::NoColor {
        sub new         { bless {}, shift }
        sub RGBA        { ( 0, 0, 0, 0xFFFF ) }
        sub is_no_color {1}
    }
    my $NoColor = Cancer::Lipgloss::NoColor->new;
    sub NoColor () {$NoColor}

    # ---- Color constructor --------------------------------------------------------------------------------------------
    sub Color ($s) {
        return $NoColor unless defined $s && length $s;
        if ( $s =~ /^#/ ) {
            my $c = parse_hex($s);
            return $NoColor unless defined $c;
            return bless $c, 'Cancer::Lipgloss::RGBColor';
        }
        my $i = int($s);
        $i = -$i if $i < 0;
        if ( $i < 16 ) {
            return bless { index => $i }, 'Cancer::Lipgloss::BasicColor';
        }
        elsif ( $i < 256 ) {
            return bless { index => $i }, 'Cancer::Lipgloss::IndexedColor';
        }
        my $r = ( $i >> 16 ) & 0xFF;
        my $g = ( $i >> 8 ) & 0xFF;
        my $b = $i & 0xFF;
        return bless { R => $r, G => $g, B => $b, A => 255 }, 'Cancer::Lipgloss::RGBColor';
    }

    package Cancer::Lipgloss::BasicColor {
        sub new { bless { index => $_[1] }, shift }

        sub RGBA {
            my $i = $_[0]->{index};

            # Map to 16-color RGB (standard VGA palette)
            my @basic = (
                [ 0,   0,   0 ],
                [ 128, 0,   0 ],
                [ 0,   128, 0 ],
                [ 128, 128, 0 ],
                [ 0,   0,   128 ],
                [ 128, 0,   128 ],
                [ 0,   128, 128 ],
                [ 192, 192, 192 ],
                [ 128, 128, 128 ],
                [ 255, 0,   0 ],
                [ 0,   255, 0 ],
                [ 255, 255, 0 ],
                [ 0,   0,   255 ],
                [ 255, 0,   255 ],
                [ 0,   255, 255 ],
                [ 255, 255, 255 ]
            );
            my $c = $basic[$i] // [ 0, 0, 0 ];
            return ( $c->[0] << 8, $c->[1] << 8, $c->[2] << 8, 0xFFFF );
        }
        sub is_no_color {0}
        sub index       { $_[0]->{index} }
    }

    package Cancer::Lipgloss::IndexedColor {
        sub new { bless { index => $_[1] }, shift }

        sub RGBA {

            # Convert 256-color index to RGB (simplified)
            my $i   = $_[0]->{index};
            my @rgb = Cancer::ColorProfile::_do_convert( 3, $i );    # TrueColor profile = passthrough
            return ( $rgb[0] << 8, $rgb[1] << 8, $rgb[2] << 8, 0xFFFF ) if @rgb;
            return ( 0,            0,            0,            0xFFFF );
        }
        sub is_no_color {0}
        sub index       { $_[0]->{index} }
    }

    package Cancer::Lipgloss::RGBColor {
        sub new { bless { R => $_[1], G => $_[2], B => $_[3], A => $_[4] // 255 }, shift }

        sub RGBA {
            my $c = $_[0];
            return ( $c->{R} << 8, $c->{G} << 8, $c->{B} << 8, ( $c->{A} // 255 ) << 8 );
        }
        sub is_no_color {0}
    }

    # ---- Hex parser ----------------------------------------------------------------------------------------------------------
    sub parse_hex ($s) {
        return undef unless $s =~ /^#/;
        my $hex = substr( $s, 1 );
        my $len = length($hex);
        if ( $len == 3 ) {
            my @h = split //, $hex;
            return { R => hex( $h[0] x 2 ), G => hex( $h[1] x 2 ), B => hex( $h[2] x 2 ), A => 255 };
        }
        elsif ( $len == 6 ) {
            my @h = unpack( "A2A2A2", $hex );
            return { R => hex( $h[0] ), G => hex( $h[1] ), B => hex( $h[2] ), A => 255 };
        }
        return undef;
    }

    # ---- LightDark ------------------------------------------------------------------------------------------------------------
    sub LightDark ($is_dark) {
        return sub ( $light, $dark ) { $is_dark ? $dark : $light };
    }

    sub AdaptiveColor (%args) {
        my $dark = has_dark_background();
        return $dark ? ( $args{dark} // $args{light} ) : ( $args{light} // $args{dark} );
    }

    # ---- Complete --------------------------------------------------------------------------------------------------------------
    sub Complete ($profile) {
        return sub ( $ansi_color, $ansi256_color, $truecolor_color ) {
            if    ( $profile eq 'ANSI' )      { return $ansi_color }
            elsif ( $profile eq 'ANSI256' )   { return $ansi256_color }
            elsif ( $profile eq 'TrueColor' ) { return $truecolor_color }
            return $NoColor;
        };
    }

    # ---- Ensure color helper ----------------------------------------------------------------------------------------
    sub _ensure_not_transparent ($c) {
        return $c unless defined $c;
        my ( undef, undef, undef, $a ) = $c->RGBA;
        return $c if defined $a && $a != 0;
        return alpha( $c, 1 );
    }

    # ---- Style class --------------------------------------------------------------------------------------------------------
    package Cancer::Lipgloss::Style {

        sub new {
            my ( $class, %args ) = @_;
            return bless {
                props                  => $args{props}       // 0,
                value                  => $args{value}       // '',
                attrs                  => $args{attrs}       // 0,
                link                   => $args{link}        // '',
                link_params            => $args{link_params} // '',
                fg                     => $args{fg},
                bg                     => $args{bg},
                ul                     => $args{ul},
                underline_style        => $args{underline_style} // 0,
                width                  => $args{width}           // 0,
                height                 => $args{height}          // 0,
                align_h                => $args{align_h}         // 0,
                align_v                => $args{align_v}         // 0,
                padding_top            => $args{padding_top}     // 0,
                padding_right          => $args{padding_right}   // 0,
                padding_bottom         => $args{padding_bottom}  // 0,
                padding_left           => $args{padding_left}    // 0,
                padding_char           => $args{padding_char}    // 0,
                margin_top             => $args{margin_top}      // 0,
                margin_right           => $args{margin_right}    // 0,
                margin_bottom          => $args{margin_bottom}   // 0,
                margin_left            => $args{margin_left}     // 0,
                margin_bg              => $args{margin_bg},
                margin_char            => $args{margin_char} // 0,
                border                 => $args{border},
                border_top_fg          => $args{border_top_fg},
                border_right_fg        => $args{border_right_fg},
                border_bottom_fg       => $args{border_bottom_fg},
                border_left_fg         => $args{border_left_fg},
                border_blend_fg        => $args{border_blend_fg},
                border_blend_fg_offset => $args{border_blend_fg_offset} // 0,
                border_top_bg          => $args{border_top_bg},
                border_right_bg        => $args{border_right_bg},
                border_bottom_bg       => $args{border_bottom_bg},
                border_left_bg         => $args{border_left_bg},
                max_width              => $args{max_width}  // 0,
                max_height             => $args{max_height} // 0,
                tab_width              => $args{tab_width}  // 0,
                transform              => $args{transform}
            }, $class;
        }

        sub clone {
            my $self = shift;
            my %copy = %$self;

            # Deep-copy mutable reference members so clones never share state:
            # - border: a hashref that _apply_border mutates (corner fill-in)
            # - border_blend_fg: an arrayref of per-cell colors
            # Color objects (fg/bg/ul/border_*_fg/...) are immutable value
            # objects and transform is a coderef, so sharing those is safe.
            $copy{border} = { %{ $self->{border} } } if ref $self->{border};
            if ( ref $self->{border_blend_fg} ) {
                $copy{border_blend_fg} = [ @{ $self->{border_blend_fg} } ];
            }
            return bless \%copy, ref $self;
        }

        # ---- Property check ------------------------------------------------------------------------------------------
        sub is_set {
            my ( $self, $key ) = @_;
            return $self->{props} & $key ? 1 : 0;
        }

        sub _set {
            my ( $self, $key, $value ) = @_;
            $self->{props} |= $key;
            return $self;
        }

        sub _unset {
            my ( $self, $key ) = @_;
            $self->{props} &= ~$key;
            return $self;
        }

        # ---- Getters --------------------------------------------------------------------------------------------------------
        sub get_bold                 { $_[0]->{attrs} & Cancer::Lipgloss::BOLD_KEY          ? 1 : 0 }
        sub get_italic               { $_[0]->{attrs} & Cancer::Lipgloss::ITALIC_KEY        ? 1 : 0 }
        sub get_strikethrough        { $_[0]->{attrs} & Cancer::Lipgloss::STRIKETHROUGH_KEY ? 1 : 0 }
        sub get_reverse              { $_[0]->{attrs} & Cancer::Lipgloss::REVERSE_KEY       ? 1 : 0 }
        sub get_blink                { $_[0]->{attrs} & Cancer::Lipgloss::BLINK_KEY         ? 1 : 0 }
        sub get_faint                { $_[0]->{attrs} & Cancer::Lipgloss::FAINT_KEY         ? 1 : 0 }
        sub get_underline            { $_[0]->{underline_style} != 0 }
        sub get_underline_style      { $_[0]->{underline_style} }
        sub get_color_whitespace     { $_[0]->is_set(Cancer::Lipgloss::COLOR_WHITESPACE_KEY) }
        sub get_inline               { $_[0]->is_set(Cancer::Lipgloss::INLINE_KEY) }
        sub get_underline_spaces     { $_[0]->is_set(Cancer::Lipgloss::UNDERLINE_SPACES_KEY) }
        sub get_strikethrough_spaces { $_[0]->is_set(Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY) }
        sub get_foreground           { $_[0]->{fg} // $NoColor }
        sub get_background           { $_[0]->{bg} // $NoColor }
        sub get_underline_color      { $_[0]->{ul} // $NoColor }
        sub get_width                { $_[0]->{width} }
        sub get_height               { $_[0]->{height} }
        sub get_max_width            { $_[0]->{max_width} }
        sub get_max_height           { $_[0]->{max_height} }
        sub get_tab_width            { $_[0]->{tab_width} // Cancer::Lipgloss::TAB_WIDTH_DEFAULT }
        sub get_transform            { $_[0]->{transform} }

        sub get_align_horizontal {
            my $v = $_[0]->{align_h};
            return Cancer::Lipgloss::Left unless defined $v && $v;
            return $v;
        }

        sub get_align_vertical {
            my $v = $_[0]->{align_v};
            return Cancer::Lipgloss::Top unless defined $v && $v;
            return $v;
        }
        sub get_align              { $_[0]->get_align_horizontal }
        sub get_padding_top        { $_[0]->{padding_top}    // 0 }
        sub get_padding_right      { $_[0]->{padding_right}  // 0 }
        sub get_padding_bottom     { $_[0]->{padding_bottom} // 0 }
        sub get_padding_left       { $_[0]->{padding_left}   // 0 }
        sub get_padding            { $_[0]->get_padding_top, $_[0]->get_padding_right, $_[0]->get_padding_bottom, $_[0]->get_padding_left }
        sub get_horizontal_padding { $_[0]->get_padding_left + $_[0]->get_padding_right }
        sub get_vertical_padding   { $_[0]->get_padding_top + $_[0]->get_padding_bottom }

        sub get_padding_char {
            my $c = $_[0]->{padding_char};
            return ( defined $c && $c ) ? $c : 32;    # space
        }
        sub get_margin_top        { $_[0]->{margin_top}    // 0 }
        sub get_margin_right      { $_[0]->{margin_right}  // 0 }
        sub get_margin_bottom     { $_[0]->{margin_bottom} // 0 }
        sub get_margin_left       { $_[0]->{margin_left}   // 0 }
        sub get_margin            { $_[0]->get_margin_top, $_[0]->get_margin_right, $_[0]->get_margin_bottom, $_[0]->get_margin_left }
        sub get_margin_background { $_[0]->{margin_bg} }

        sub get_margin_char {
            my $c = $_[0]->{margin_char};
            return ( defined $c && $c ) ? $c : 32;    # space
        }
        sub get_border_style           { $_[0]->{border}                 // $Cancer::Lipgloss::no_border }
        sub get_border_top_fg          { $_[0]->{border_top_fg}          // $NoColor }
        sub get_border_right_fg        { $_[0]->{border_right_fg}        // $NoColor }
        sub get_border_bottom_fg       { $_[0]->{border_bottom_fg}       // $NoColor }
        sub get_border_left_fg         { $_[0]->{border_left_fg}         // $NoColor }
        sub get_border_top_bg          { $_[0]->{border_top_bg}          // $NoColor }
        sub get_border_right_bg        { $_[0]->{border_right_bg}        // $NoColor }
        sub get_border_bottom_bg       { $_[0]->{border_bottom_bg}       // $NoColor }
        sub get_border_left_bg         { $_[0]->{border_left_bg}         // $NoColor }
        sub get_border_blend_fg        { $_[0]->{border_blend_fg}        // [] }
        sub get_border_blend_fg_offset { $_[0]->{border_blend_fg_offset} // 0 }
        sub get_hyperlink              { $_[0]->{link}                   // '', $_[0]->{link_params} // '' }

        sub get_horizontal_border_size {
            my $self    = $_[0];
            my $b       = $self->get_border_style;
            my $left_w  = $self->is_set(Cancer::Lipgloss::BORDER_LEFT_KEY)  ? Cancer::Lipgloss::_max_rune_width( $b->{left}  // '' ) : 0;
            my $right_w = $self->is_set(Cancer::Lipgloss::BORDER_RIGHT_KEY) ? Cancer::Lipgloss::_max_rune_width( $b->{right} // '' ) : 0;
            return $left_w + $right_w;
        }

        sub get_vertical_border_size {
            my $self  = $_[0];
            my $b     = $self->get_border_style;
            my $top_h = $self->is_set(Cancer::Lipgloss::BORDER_TOP_KEY) ? ( Cancer::Lipgloss::_max_rune_width( $b->{top} // '' ) ? 1 : 0 ) : 0;
            my $bottom_h
                = $self->is_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) ? ( Cancer::Lipgloss::_max_rune_width( $b->{bottom} // '' ) ? 1 : 0 ) : 0;
            return $top_h + $bottom_h;
        }

        # Actual margins (margin_left + margin_right / margin_top + margin_bottom)
        sub get_horizontal_margins {
            my $self = shift;
            return $self->get_margin_left + $self->get_margin_right;
        }

        sub get_vertical_margins {
            my $self = shift;
            return $self->get_margin_top + $self->get_margin_bottom;
        }

        # Frame size = margins + padding + border (matches Go GetHorizontalFrameSize)
        sub get_horizontal_frame_size {
            my $self = shift;
            return $self->get_horizontal_margins + $self->get_horizontal_padding + $self->get_horizontal_border_size;
        }

        sub get_vertical_frame_size {
            my $self = shift;
            return $self->get_vertical_margins + $self->get_vertical_padding + $self->get_vertical_border_size;
        }
        sub get_frame_size { $_[0]->get_horizontal_frame_size, $_[0]->get_vertical_frame_size }

        # Border side visibility
        sub get_border_top    { $_[0]->is_set(Cancer::Lipgloss::BORDER_TOP_KEY) }
        sub get_border_right  { $_[0]->is_set(Cancer::Lipgloss::BORDER_RIGHT_KEY) }
        sub get_border_bottom { $_[0]->is_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) }
        sub get_border_left   { $_[0]->is_set(Cancer::Lipgloss::BORDER_LEFT_KEY) }

        # Border side sizes
        sub get_border_top_size {
            my $self = shift;
            return 0 unless $self->is_set(Cancer::Lipgloss::BORDER_TOP_KEY);
            my $b = $self->get_border_style;
            return Cancer::Lipgloss::_max_rune_width( $b->{top} // '' );
        }

        sub get_border_right_size {
            my $self = shift;
            return 0 unless $self->is_set(Cancer::Lipgloss::BORDER_RIGHT_KEY);
            my $b = $self->get_border_style;
            return Cancer::Lipgloss::_max_rune_width( $b->{right} // '' );
        }

        sub get_border_bottom_size {
            my $self = shift;
            return 0 unless $self->is_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY);
            my $b = $self->get_border_style;
            return Cancer::Lipgloss::_max_rune_width( $b->{bottom} // '' );
        }

        sub get_border_left_size {
            my $self = shift;
            return 0 unless $self->is_set(Cancer::Lipgloss::BORDER_LEFT_KEY);
            my $b = $self->get_border_style;
            return Cancer::Lipgloss::_max_rune_width( $b->{left} // '' );
        }

        # ---- Setters --------------------------------------------------------------------------------------------------------
        sub set_string {
            my ( $self, @strs ) = @_;
            my $s = $self->clone;
            $s->{value} = join ' ', @strs;
            return $s;
        }
        sub value { $_[0]->{value} }

        sub bold {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{attrs} |= Cancer::Lipgloss::BOLD_KEY if $v;
            $s->{attrs} &= ~Cancer::Lipgloss::BOLD_KEY unless $v;
            $s->_set(Cancer::Lipgloss::BOLD_KEY);
            return $s;
        }

        sub italic {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) { $s->{attrs} |= Cancer::Lipgloss::ITALIC_KEY }
            else    { $s->{attrs} &= ~Cancer::Lipgloss::ITALIC_KEY }
            $s->_set(Cancer::Lipgloss::ITALIC_KEY);
            return $s;
        }

        sub strikethrough {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) { $s->{attrs} |= Cancer::Lipgloss::STRIKETHROUGH_KEY }
            else    { $s->{attrs} &= ~Cancer::Lipgloss::STRIKETHROUGH_KEY }
            $s->_set(Cancer::Lipgloss::STRIKETHROUGH_KEY);
            return $s;
        }

        sub reverse {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) { $s->{attrs} |= Cancer::Lipgloss::REVERSE_KEY }
            else    { $s->{attrs} &= ~Cancer::Lipgloss::REVERSE_KEY }
            $s->_set(Cancer::Lipgloss::REVERSE_KEY);
            return $s;
        }

        sub blink {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) { $s->{attrs} |= Cancer::Lipgloss::BLINK_KEY }
            else    { $s->{attrs} &= ~Cancer::Lipgloss::BLINK_KEY }
            $s->_set(Cancer::Lipgloss::BLINK_KEY);
            return $s;
        }

        sub faint {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) { $s->{attrs} |= Cancer::Lipgloss::FAINT_KEY }
            else    { $s->{attrs} &= ~Cancer::Lipgloss::FAINT_KEY }
            $s->_set(Cancer::Lipgloss::FAINT_KEY);
            return $s;
        }

        sub _normalize_color {
            my ($c) = @_;
            return $c if !defined $c || !ref $c;
            return $c if blessed($c) && $c->isa('Cancer::Lipgloss::RGBColor');
            return $c if blessed($c) && $c->isa('Cancer::Lipgloss::BasicColor');
            return $c if blessed($c) && $c->isa('Cancer::Lipgloss::IndexedColor');
            if ( blessed($c) && $c->can('RGBA') ) {
                my ( $r, $g, $b, $a ) = $c->RGBA;
                return Cancer::Lipgloss::RGBColor->new( $r, $g, $b, $a // 255 );
            }
            if ( ref $c eq 'ARRAY' && @$c >= 3 ) {
                return Cancer::Lipgloss::RGBColor->new( $c->[0], $c->[1], $c->[2], $c->[3] // 255 );
            }
            return $c;
        }

        sub foreground {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{fg} = _normalize_color($c);
            $s->_set(Cancer::Lipgloss::FOREGROUND_KEY);
            return $s;
        }

        sub background {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{bg} = _normalize_color($c);
            $s->_set(Cancer::Lipgloss::BACKGROUND_KEY);
            return $s;
        }

        sub underline {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{underline_style} = $v ? 1 : 0;
            $s->_set(Cancer::Lipgloss::UNDERLINE_KEY);
            return $s;
        }

        sub underline_style {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{underline_style} = $v;
            $s->_set(Cancer::Lipgloss::UNDERLINE_KEY);
            return $s;
        }

        sub underline_color {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{ul} = $c;
            $s->_set(Cancer::Lipgloss::UNDERLINE_COLOR_KEY);
            return $s;
        }

        sub width {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{width} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::WIDTH_KEY);
            return $s;
        }

        sub height {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{height} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::HEIGHT_KEY);
            return $s;
        }

        sub max_width {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{max_width} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MAX_WIDTH_KEY);
            return $s;
        }

        sub max_height {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{max_height} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MAX_HEIGHT_KEY);
            return $s;
        }

        sub tab_width {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{tab_width} = $v;
            $s->_set(Cancer::Lipgloss::TAB_WIDTH_KEY);
            return $s;
        }

        sub inline {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::INLINE_KEY) }
            else      { $s->_unset(Cancer::Lipgloss::INLINE_KEY) }
            return $s;
        }

        sub color_whitespace {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::COLOR_WHITESPACE_KEY);   delete $s->{color_ws_disabled} }
            else      { $s->_unset(Cancer::Lipgloss::COLOR_WHITESPACE_KEY); $s->{color_ws_disabled} = 1 }
            return $s;
        }

        sub underline_spaces {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) {
                $s->{attrs} |= Cancer::Lipgloss::UNDERLINE_SPACES_KEY;
                $s->_set(Cancer::Lipgloss::UNDERLINE_SPACES_KEY);
            }
            else {
                $s->{attrs} &= ~Cancer::Lipgloss::UNDERLINE_SPACES_KEY;
                $s->_unset(Cancer::Lipgloss::UNDERLINE_SPACES_KEY);
            }
            return $s;
        }

        sub strikethrough_spaces {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            if ($v) {
                $s->{attrs} |= Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY;
                $s->_set(Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY);
            }
            else {
                $s->{attrs} &= ~Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY;
                $s->_unset(Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY);
            }
            return $s;
        }

        # Alignment
        sub align {
            my ( $self, $h, $v ) = @_;
            my $s = $self->clone;
            $s->{align_h} = $h if defined $h;
            $s->{align_v} = $v if defined $v;
            $s->_set(Cancer::Lipgloss::ALIGN_HORIZONTAL_KEY) if defined $h;
            $s->_set(Cancer::Lipgloss::ALIGN_VERTICAL_KEY)   if defined $v;
            return $s;
        }

        sub align_horizontal {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{align_h} = $v;
            $s->_set(Cancer::Lipgloss::ALIGN_HORIZONTAL_KEY);
            return $s;
        }

        sub align_vertical {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{align_v} = $v;
            $s->_set(Cancer::Lipgloss::ALIGN_VERTICAL_KEY);
            return $s;
        }

        # Padding (CSS-style shorthand: top right bottom left)
        sub padding {
            my ( $self, @args ) = @_;
            my $s = $self->clone;
            my ( $t, $r, $b, $l );
            if    ( @args == 1 ) { $t = $r = $b = $l = $args[0] }
            elsif ( @args == 2 ) { $t = $b = $args[0]; $r = $l = $args[1] }
            elsif ( @args == 3 ) { $t = $args[0]; $r = $l = $args[1]; $b = $args[2] }
            elsif ( @args == 4 ) { ( $t, $r, $b, $l ) = @args }
            $s->{padding_top}    = $t // 0;
            $s->{padding_right}  = $r // 0;
            $s->{padding_bottom} = $b // 0;
            $s->{padding_left}   = $l // 0;
            $s->{padding_char}   = $args[-1] if @args && ref $args[-1] eq '' && $args[-1] !~ /^\d/ && length( $args[-1] ) > 0;
            $s->_set(Cancer::Lipgloss::PADDING_TOP_KEY);
            $s->_set(Cancer::Lipgloss::PADDING_RIGHT_KEY);
            $s->_set(Cancer::Lipgloss::PADDING_BOTTOM_KEY);
            $s->_set(Cancer::Lipgloss::PADDING_LEFT_KEY);
            return $s;
        }

        sub padding_top {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{padding_top} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::PADDING_TOP_KEY);
            return $s;
        }

        sub padding_right {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{padding_right} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::PADDING_RIGHT_KEY);
            return $s;
        }

        sub padding_bottom {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{padding_bottom} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::PADDING_BOTTOM_KEY);
            return $s;
        }

        sub padding_left {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{padding_left} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::PADDING_LEFT_KEY);
            return $s;
        }

        sub padding_char {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{padding_char} = ord($v);
            $s->_set(Cancer::Lipgloss::PADDING_CHAR_KEY);
            return $s;
        }

        # Margins (CSS-style shorthand)
        sub margin {
            my ( $self, @args ) = @_;
            my $s = $self->clone;
            my ( $t, $r, $b, $l );
            if    ( @args == 1 ) { $t = $r = $b = $l = $args[0] }
            elsif ( @args == 2 ) { $t = $b = $args[0]; $r = $l = $args[1] }
            elsif ( @args == 3 ) { $t = $args[0]; $r = $l = $args[1]; $b = $args[2] }
            elsif ( @args == 4 ) { ( $t, $r, $b, $l ) = @args }
            $s->{margin_top}    = $t // 0;
            $s->{margin_right}  = $r // 0;
            $s->{margin_bottom} = $b // 0;
            $s->{margin_left}   = $l // 0;
            $s->_set(Cancer::Lipgloss::MARGIN_TOP_KEY);
            $s->_set(Cancer::Lipgloss::MARGIN_RIGHT_KEY);
            $s->_set(Cancer::Lipgloss::MARGIN_BOTTOM_KEY);
            $s->_set(Cancer::Lipgloss::MARGIN_LEFT_KEY);
            return $s;
        }

        sub margin_top {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{margin_top} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MARGIN_TOP_KEY);
            return $s;
        }

        sub margin_right {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{margin_right} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MARGIN_RIGHT_KEY);
            return $s;
        }

        sub margin_bottom {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{margin_bottom} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MARGIN_BOTTOM_KEY);
            return $s;
        }

        sub margin_left {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{margin_left} = $v > 0 ? $v : 0;
            $s->_set(Cancer::Lipgloss::MARGIN_LEFT_KEY);
            return $s;
        }

        sub margin_background {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{margin_bg} = $c;
            $s->_set(Cancer::Lipgloss::MARGIN_BACKGROUND_KEY);
            return $s;
        }

        sub margin_char {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{margin_char} = ord($v);
            $s->_set(Cancer::Lipgloss::MARGIN_CHAR_KEY);
            return $s;
        }

        # Borders
        sub border {
            my ( $self, $border, @sides ) = @_;
            my $s = $self->clone;
            $s->{border} = $border;
            $s->_set(Cancer::Lipgloss::BORDER_STYLE_KEY);
            if (@sides) {

                # Check if first arg is boolean (Go-style: border($b, $top, $right, $bottom, $left))
                if ( $sides[0] eq '0' || $sides[0] eq '1' || ref \$sides[0] eq 'SCALAR' ) {
                    my ( $t, $r, $b, $l );
                    my $n = scalar @sides;
                    if    ( $n == 1 ) { $t = $r            = $b            = $l            = $sides[0] }
                    elsif ( $n == 2 ) { $t = $b            = $sides[0]; $l = $r            = $sides[1] }
                    elsif ( $n == 3 ) { $t = $sides[0]; $l = $r            = $sides[1]; $b = $sides[2] }
                    elsif ( $n >= 4 ) { $t = $sides[0]; $r = $sides[1]; $b = $sides[2]; $l = $sides[3] }
                    $s->_set(Cancer::Lipgloss::BORDER_TOP_KEY)    if $t;
                    $s->_set(Cancer::Lipgloss::BORDER_RIGHT_KEY)  if $r;
                    $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) if $b;
                    $s->_set(Cancer::Lipgloss::BORDER_LEFT_KEY)   if $l;
                }
                else {
                    for my $side (@sides) {
                        if    ( $side eq 'top' )    { $s->_set(Cancer::Lipgloss::BORDER_TOP_KEY) }
                        elsif ( $side eq 'right' )  { $s->_set(Cancer::Lipgloss::BORDER_RIGHT_KEY) }
                        elsif ( $side eq 'bottom' ) { $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) }
                        elsif ( $side eq 'left' )   { $s->_set(Cancer::Lipgloss::BORDER_LEFT_KEY) }
                    }
                }
            }
            else {
                # No side args: enable all four sides explicitly (matches Go behavior)
                $s->_set(Cancer::Lipgloss::BORDER_TOP_KEY);
                $s->_set(Cancer::Lipgloss::BORDER_RIGHT_KEY);
                $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY);
                $s->_set(Cancer::Lipgloss::BORDER_LEFT_KEY);
            }
            return $s;
        }

        sub border_top {
            my ( $self, $v ) = @_;
            $v = 1 unless defined $v;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::BORDER_TOP_KEY) }
            else      { $s->_unset(Cancer::Lipgloss::BORDER_TOP_KEY) }
            return $s;
        }

        sub border_right {
            my ( $self, $v ) = @_;
            $v = 1 unless defined $v;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::BORDER_RIGHT_KEY) }
            else      { $s->_unset(Cancer::Lipgloss::BORDER_RIGHT_KEY) }
            return $s;
        }

        sub border_bottom {
            my ( $self, $v ) = @_;
            $v = 1 unless defined $v;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) }
            else      { $s->_unset(Cancer::Lipgloss::BORDER_BOTTOM_KEY) }
            return $s;
        }

        sub border_left {
            my ( $self, $v ) = @_;
            $v = 1 unless defined $v;
            my $s = $self->clone;
            if   ($v) { $s->_set(Cancer::Lipgloss::BORDER_LEFT_KEY) }
            else      { $s->_unset(Cancer::Lipgloss::BORDER_LEFT_KEY) }
            return $s;
        }

        sub border_style {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{border} = $v;
            $s->_set(Cancer::Lipgloss::BORDER_STYLE_KEY);
            return $s;
        }

        # Border colors
        sub _set_border_color {
            my ( $self, $key, $color_key, $c ) = @_;
            my $s = $self->clone;
            $s->{$color_key} = _normalize_color($c);
            $s->_set($key);
            return $s;
        }
        sub border_top_foreground    { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_TOP_FG_KEY,    'border_top_fg',    $_[1] ) }
        sub border_right_foreground  { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_RIGHT_FG_KEY,  'border_right_fg',  $_[1] ) }
        sub border_bottom_foreground { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_BOTTOM_FG_KEY, 'border_bottom_fg', $_[1] ) }
        sub border_left_foreground   { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_LEFT_FG_KEY,   'border_left_fg',   $_[1] ) }
        sub border_top_background    { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_TOP_BG_KEY,    'border_top_bg',    $_[1] ) }
        sub border_right_background  { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_RIGHT_BG_KEY,  'border_right_bg',  $_[1] ) }
        sub border_bottom_background { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_BOTTOM_BG_KEY, 'border_bottom_bg', $_[1] ) }
        sub border_left_background   { $_[0]->_set_border_color( Cancer::Lipgloss::BORDER_LEFT_BG_KEY,   'border_left_bg',   $_[1] ) }

        sub border_foreground {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{border_top_fg}    = $c;
            $s->{border_right_fg}  = $c;
            $s->{border_bottom_fg} = $c;
            $s->{border_left_fg}   = $c;
            $s->_set(Cancer::Lipgloss::BORDER_TOP_FG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_RIGHT_FG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_FG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_LEFT_FG_KEY);
            return $s;
        }

        sub border_background {
            my ( $self, $c ) = @_;
            my $s = $self->clone;
            $s->{border_top_bg}    = $c;
            $s->{border_right_bg}  = $c;
            $s->{border_bottom_bg} = $c;
            $s->{border_left_bg}   = $c;
            $s->_set(Cancer::Lipgloss::BORDER_TOP_BG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_RIGHT_BG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_BOTTOM_BG_KEY);
            $s->_set(Cancer::Lipgloss::BORDER_LEFT_BG_KEY);
            return $s;
        }

        sub border_foreground_blend {
            my ( $self, @colors ) = @_;
            my $s = $self->clone;
            $s->{border_blend_fg} = \@colors;
            $s->_set(Cancer::Lipgloss::BORDER_BLEND_FG_KEY);
            return $s;
        }

        sub border_foreground_blend_offset {
            my ( $self, $v ) = @_;
            my $s = $self->clone;
            $s->{border_blend_fg_offset} = $v;
            $s->_set(Cancer::Lipgloss::BORDER_BLEND_FG_OFFSET_KEY);
            return $s;
        }

        # Hyperlink
        sub hyperlink {
            my ( $self, $url, $params ) = @_;
            my $s = $self->clone;
            $s->{link}        = $url    // '';
            $s->{link_params} = $params // '';
            $s->_set(Cancer::Lipgloss::LINK_KEY);
            $s->_set(Cancer::Lipgloss::LINK_PARAMS_KEY) if defined $params;
            return $s;
        }

        sub transform {
            my ( $self, $fn ) = @_;
            my $s = $self->clone;
            $s->{transform} = $fn;
            $s->_set(Cancer::Lipgloss::TRANSFORM_KEY);
            return $s;
        }

        # ---- Inherit --------------------------------------------------------------------------------------------------------
        sub inherit {
            my ( $self, $i ) = @_;
            my $s = $self->clone;
            my $k = Cancer::Lipgloss::BOLD_KEY;
            while ( $k <= Cancer::Lipgloss::TRANSFORM_KEY ) {
                if ( $i->is_set($k) ) {

                    # Margins and padding are not inherited
                    my $is_margin
                        = ( $k == Cancer::Lipgloss::MARGIN_TOP_KEY ||
                            $k == Cancer::Lipgloss::MARGIN_RIGHT_KEY  ||
                            $k == Cancer::Lipgloss::MARGIN_BOTTOM_KEY ||
                            $k == Cancer::Lipgloss::MARGIN_LEFT_KEY );
                    my $is_padding
                        = ( $k == Cancer::Lipgloss::PADDING_TOP_KEY ||
                            $k == Cancer::Lipgloss::PADDING_RIGHT_KEY  ||
                            $k == Cancer::Lipgloss::PADDING_BOTTOM_KEY ||
                            $k == Cancer::Lipgloss::PADDING_LEFT_KEY );
                    if ( !$is_margin && !$is_padding && !$s->is_set($k) ) {
                        _copy_prop( $s, $i, $k );
                    }
                    if ( $k == Cancer::Lipgloss::BACKGROUND_KEY ) {

                        # The margins also inherit the background color
                        if ( !$s->is_set(Cancer::Lipgloss::MARGIN_BACKGROUND_KEY) && !$i->is_set(Cancer::Lipgloss::MARGIN_BACKGROUND_KEY) ) {
                            $s->{props} |= Cancer::Lipgloss::MARGIN_BACKGROUND_KEY;
                            $s->{margin_bg} = $i->{bg};
                        }
                    }
                }
                $k <<= 1;
            }
            return $s;
        }

        sub _copy_prop {
            my ( $dst, $src, $k ) = @_;
            $dst->{props} |= $k;
            if    ( $k == Cancer::Lipgloss::BOLD_KEY ) { $dst->{attrs} |= Cancer::Lipgloss::BOLD_KEY if $src->{attrs} & Cancer::Lipgloss::BOLD_KEY }
            elsif ( $k == Cancer::Lipgloss::ITALIC_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::ITALIC_KEY if $src->{attrs} & Cancer::Lipgloss::ITALIC_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::STRIKETHROUGH_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::STRIKETHROUGH_KEY if $src->{attrs} & Cancer::Lipgloss::STRIKETHROUGH_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::REVERSE_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::REVERSE_KEY if $src->{attrs} & Cancer::Lipgloss::REVERSE_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::BLINK_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::BLINK_KEY if $src->{attrs} & Cancer::Lipgloss::BLINK_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::FAINT_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::FAINT_KEY if $src->{attrs} & Cancer::Lipgloss::FAINT_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::UNDERLINE_SPACES_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::UNDERLINE_SPACES_KEY if $src->{attrs} & Cancer::Lipgloss::UNDERLINE_SPACES_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY if $src->{attrs} & Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::COLOR_WHITESPACE_KEY ) {
                $dst->{attrs} |= Cancer::Lipgloss::COLOR_WHITESPACE_KEY if $src->{attrs} & Cancer::Lipgloss::COLOR_WHITESPACE_KEY;
            }
            elsif ( $k == Cancer::Lipgloss::UNDERLINE_KEY )              { $dst->{underline_style}        = $src->{underline_style} }
            elsif ( $k == Cancer::Lipgloss::FOREGROUND_KEY )             { $dst->{fg}                     = $src->{fg} }
            elsif ( $k == Cancer::Lipgloss::BACKGROUND_KEY )             { $dst->{bg}                     = $src->{bg} }
            elsif ( $k == Cancer::Lipgloss::UNDERLINE_COLOR_KEY )        { $dst->{ul}                     = $src->{ul} }
            elsif ( $k == Cancer::Lipgloss::WIDTH_KEY )                  { $dst->{width}                  = $src->{width} }
            elsif ( $k == Cancer::Lipgloss::HEIGHT_KEY )                 { $dst->{height}                 = $src->{height} }
            elsif ( $k == Cancer::Lipgloss::ALIGN_HORIZONTAL_KEY )       { $dst->{align_h}                = $src->{align_h} }
            elsif ( $k == Cancer::Lipgloss::ALIGN_VERTICAL_KEY )         { $dst->{align_v}                = $src->{align_v} }
            elsif ( $k == Cancer::Lipgloss::PADDING_TOP_KEY )            { $dst->{padding_top}            = $src->{padding_top} }
            elsif ( $k == Cancer::Lipgloss::PADDING_RIGHT_KEY )          { $dst->{padding_right}          = $src->{padding_right} }
            elsif ( $k == Cancer::Lipgloss::PADDING_BOTTOM_KEY )         { $dst->{padding_bottom}         = $src->{padding_bottom} }
            elsif ( $k == Cancer::Lipgloss::PADDING_LEFT_KEY )           { $dst->{padding_left}           = $src->{padding_left} }
            elsif ( $k == Cancer::Lipgloss::PADDING_CHAR_KEY )           { $dst->{padding_char}           = $src->{padding_char} }
            elsif ( $k == Cancer::Lipgloss::BORDER_STYLE_KEY )           { $dst->{border}                 = $src->{border} }
            elsif ( $k == Cancer::Lipgloss::BORDER_TOP_FG_KEY )          { $dst->{border_top_fg}          = $src->{border_top_fg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_RIGHT_FG_KEY )        { $dst->{border_right_fg}        = $src->{border_right_fg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_BOTTOM_FG_KEY )       { $dst->{border_bottom_fg}       = $src->{border_bottom_fg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_LEFT_FG_KEY )         { $dst->{border_left_fg}         = $src->{border_left_fg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_BLEND_FG_KEY )        { $dst->{border_blend_fg}        = $src->{border_blend_fg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_BLEND_FG_OFFSET_KEY ) { $dst->{border_blend_fg_offset} = $src->{border_blend_fg_offset} }
            elsif ( $k == Cancer::Lipgloss::BORDER_TOP_BG_KEY )          { $dst->{border_top_bg}          = $src->{border_top_bg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_RIGHT_BG_KEY )        { $dst->{border_right_bg}        = $src->{border_right_bg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_BOTTOM_BG_KEY )       { $dst->{border_bottom_bg}       = $src->{border_bottom_bg} }
            elsif ( $k == Cancer::Lipgloss::BORDER_LEFT_BG_KEY )         { $dst->{border_left_bg}         = $src->{border_left_bg} }
            elsif ( $k == Cancer::Lipgloss::INLINE_KEY )                 { }    # already set
            elsif ( $k == Cancer::Lipgloss::MAX_WIDTH_KEY )              { $dst->{max_width}   = $src->{max_width} }
            elsif ( $k == Cancer::Lipgloss::MAX_HEIGHT_KEY )             { $dst->{max_height}  = $src->{max_height} }
            elsif ( $k == Cancer::Lipgloss::TAB_WIDTH_KEY )              { $dst->{tab_width}   = $src->{tab_width} }
            elsif ( $k == Cancer::Lipgloss::TRANSFORM_KEY )              { $dst->{transform}   = $src->{transform} }
            elsif ( $k == Cancer::Lipgloss::LINK_KEY )                   { $dst->{link}        = $src->{link} }
            elsif ( $k == Cancer::Lipgloss::LINK_PARAMS_KEY )            { $dst->{link_params} = $src->{link_params} }
            elsif ( $k == Cancer::Lipgloss::MARGIN_BACKGROUND_KEY )      { $dst->{margin_bg}   = $src->{margin_bg} }
            elsif ( $k == Cancer::Lipgloss::MARGIN_CHAR_KEY )            { $dst->{margin_char} = $src->{margin_char} }
        }

        # ---- is_border_style_set_without_sides ----------------------------------------------------
        sub is_border_style_set_without_sides {
            my $s = shift;
            return 0 unless $s->is_set(Cancer::Lipgloss::BORDER_STYLE_KEY);
            return !$s->is_set(Cancer::Lipgloss::BORDER_TOP_KEY) &&
                !$s->is_set(Cancer::Lipgloss::BORDER_RIGHT_KEY)  &&
                !$s->is_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY) &&
                !$s->is_set(Cancer::Lipgloss::BORDER_LEFT_KEY);
        }

        # ---- String / Render ----------------------------------------------------------------------------------------
        sub string { $_[0]->render() }

        sub render {
            my ( $self, @strs ) = @_;
            unshift @strs, $self->{value} if $self->{value};
            my $str = join ' ', @strs;

            # Extract property values
            my $bold          = $self->get_bold;
            my $italic        = $self->get_italic;
            my $strikethrough = $self->get_strikethrough;
            my $reverse       = $self->get_reverse;
            my $blink         = $self->get_blink;
            my $faint         = $self->get_faint;
            my $fg            = $self->get_foreground;
            my $bg            = $self->get_background;
            my $ul            = $self->get_underline_color;
            my $underline_on  = $self->{underline_style} != 0;
            my $width         = $self->{width};
            my $height        = $self->{height};
            my $halign        = $self->get_align_horizontal;
            my $valign        = $self->get_align_vertical;
            my $top_pad       = $self->get_padding_top;
            my $right_pad     = $self->get_padding_right;
            my $bottom_pad    = $self->get_padding_bottom;
            my $left_pad      = $self->get_padding_left;
            my $hborder       = $self->get_horizontal_border_size;
            my $vborder       = $self->get_vertical_border_size;
            my $color_ws
                = $self->is_set(Cancer::Lipgloss::COLOR_WHITESPACE_KEY) || ( !$self->{color_ws_disabled} && !Cancer::Lipgloss::_is_no_color($bg) );
            my $inline           = $self->get_inline;
            my $max_width        = $self->{max_width};
            my $max_height       = $self->{max_height};
            my $underline_spaces = ( $self->{attrs} & Cancer::Lipgloss::UNDERLINE_SPACES_KEY ) ||
                ( $underline_on && !( $self->{attrs} & Cancer::Lipgloss::UNDERLINE_SPACES_KEY ) );
            my $strikethrough_spaces = ( $self->{attrs} & Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY ) ||
                ( $strikethrough && !( $self->{attrs} & Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY ) );
            my $style_ws         = $reverse;
            my $use_space_styler = $underline_on || $strikethrough;
            my $transform        = $self->{transform};
            my ( $link, $link_params ) = $self->get_hyperlink;

            # Apply transform
            $str = $transform->($str) if $transform;

            # Early return if no style props set
            if ( $self->{props} == 0 ) {
                return Cancer::Lipgloss::_maybe_convert_tabs( $str, $self );
            }

            # Build SGR sequences — collect params then join into single \e[...m
            my @sgr;
            my @sgr_ws;
            my @sgr_sp;
            push @sgr, 1 if $bold;
            push @sgr, 3 if $italic;
            push @sgr, 4 if $underline_on;
            push @sgr, 7 if $reverse;
            push @sgr, 5 if $blink;
            push @sgr, 2 if $faint;

            if ( !Cancer::Lipgloss::_is_no_color($fg) ) {
                my $fg_sgr = Cancer::Lipgloss::_color_sgr_fg($fg);
                push @sgr,    $fg_sgr if $fg_sgr;
                push @sgr_ws, $fg_sgr if $style_ws         && $fg_sgr;
                push @sgr_sp, $fg_sgr if $use_space_styler && $fg_sgr;
            }
            if ( !Cancer::Lipgloss::_is_no_color($bg) ) {
                my $bg_sgr = Cancer::Lipgloss::_color_sgr_bg($bg);
                push @sgr,    $bg_sgr if $bg_sgr;
                push @sgr_ws, $bg_sgr if ( $color_ws || $style_ws ) && $bg_sgr;
                push @sgr_sp, $bg_sgr if $use_space_styler          && $bg_sgr;
            }
            if ( !Cancer::Lipgloss::_is_no_color($ul) ) {
                my $ul_sgr = Cancer::Lipgloss::_color_sgr_ul($ul);
                push @sgr,    $ul_sgr if $ul_sgr;
                push @sgr_ws, $ul_sgr if ( $color_ws || $style_ws ) && $ul_sgr;
                push @sgr_sp, $ul_sgr if $use_space_styler          && $ul_sgr;
            }
            push @sgr,    9 if $strikethrough;
            push @sgr_sp, 4 if $underline_spaces;
            push @sgr_sp, 9 if $strikethrough_spaces;
            my $te    = @sgr    ? "\e[" . join( ';', @sgr ) . "m"    : '';
            my $te_ws = @sgr_ws ? "\e[" . join( ';', @sgr_ws ) . "m" : '';
            my $te_sp = @sgr_sp ? "\e[" . join( ';', @sgr_sp ) . "m" : '';

            # Convert tabs
            $str = Cancer::Lipgloss::_maybe_convert_tabs( $str, $self );
            $str =~ s/\r\n/\n/g;

            # Strip newlines in inline mode
            $str =~ s/\n//g if $inline;

            # Include borders in block size
            $width  -= $hborder if $width;
            $height -= $vborder if $height;

            # Word wrap
            if ( !$inline && $width > 0 ) {
                my $wrap_at = $width - $left_pad - $right_pad;
                $str = Cancer::CellBuf::Wrap::wrap_text( $str, $wrap_at, '' );
            }

            # Render core text
            {
                my $out   = '';
                my @lines = split /\n/, $str, -1;
                @lines = ('') unless @lines;
                for my $i ( 0 .. $#lines ) {
                    $out .= "\n" if $i > 0;
                    my $line = $lines[$i];
                    if ($use_space_styler) {

                        # \X: style whole grapheme clusters so combining marks
                        # and ZWJ emoji stay glued to their base character.
                        while ( $line =~ /(\X)/gc ) {
                            my $r = $1;
                            if ( $r =~ /^\s/ ) {
                                $out .= $te_sp . $r . "\e[m";
                            }
                            else {
                                $out .= $te . $r . "\e[m";
                            }
                        }
                    }
                    else {
                        $out .= $te . $line . "\e[m" if length($te);
                        $out .= $line unless length($te);
                    }
                }
                $str = $out;
                if ( defined $link && length $link ) {
                    $str = Cancer::Ansi::set_hyperlink( $link, $link_params ) . $str . Cancer::Ansi::reset_hyperlink();
                }
            }

            # Padding
            if ( !$inline ) {
                my $pad_char = $self->get_padding_char;
                my $pad_str  = chr($pad_char);
                my $ws_style = ( $color_ws || $style_ws ) ? $te_ws : undef;
                if ( $left_pad > 0 ) {
                    $str = Cancer::Lipgloss::_pad_left( $str, $left_pad, $ws_style, $pad_str );
                }
                if ( $right_pad > 0 ) {
                    $str = Cancer::Lipgloss::_pad_right( $str, $right_pad, $ws_style, $pad_str );
                }
                if ( $top_pad > 0 ) {
                    $str = "\n" x $top_pad . $str;
                }
                if ( $bottom_pad > 0 ) {
                    $str .= "\n" x $bottom_pad;
                }
            }

            # Vertical alignment
            if ( $height > 0 ) {
                $str = Cancer::Lipgloss::_align_vertical( $str, $valign, $height );
            }

            # Horizontal alignment
            {
                my $num_lines = ( $str =~ tr/\n// );
                if ( $num_lines || $width ) {
                    my $ws_style = ( $color_ws || $style_ws ) ? $te_ws : undef;
                    $str = Cancer::Lipgloss::_align_horizontal( $str, $halign, $width, $ws_style );
                }
            }

            # Borders
            if ( !$inline ) {
                $str = Cancer::Lipgloss::_apply_border( $self, $str );
                $str = Cancer::Lipgloss::_apply_margins( $self, $str, $inline );
            }

            # MaxWidth truncation
            if ( $max_width > 0 ) {
                my @lines = split /\n/, $str, -1;
                for my $line (@lines) {
                    $line = Cancer::Util::visual_truncate( $line, $max_width );
                }
                $str = join "\n", @lines;
            }

            # MaxHeight truncation
            if ( $max_height > 0 ) {
                my @lines = split /\n/, $str, -1;
                my $h     = $max_height < scalar @lines ? $max_height : scalar @lines;
                if (@lines) {
                    $str = join "\n", @lines[ 0 .. $h - 1 ];
                }
            }
            return $str;
        }

        # ---- Unset methods --------------------------------------------------------------------------------------------
        sub unset_bold   { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BOLD_KEY);   $s->{attrs} &= ~Cancer::Lipgloss::BOLD_KEY;   return $s }
        sub unset_italic { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::ITALIC_KEY); $s->{attrs} &= ~Cancer::Lipgloss::ITALIC_KEY; return $s }

        sub unset_strikethrough {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::STRIKETHROUGH_KEY);
            $s->{attrs} &= ~Cancer::Lipgloss::STRIKETHROUGH_KEY;
            return $s;
        }

        sub unset_reverse {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::REVERSE_KEY);
            $s->{attrs} &= ~Cancer::Lipgloss::REVERSE_KEY;
            return $s;
        }
        sub unset_blink      { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BLINK_KEY); $s->{attrs} &= ~Cancer::Lipgloss::BLINK_KEY; return $s }
        sub unset_faint      { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::FAINT_KEY); $s->{attrs} &= ~Cancer::Lipgloss::FAINT_KEY; return $s }
        sub unset_foreground { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::FOREGROUND_KEY); $s->{fg}              = undef; return $s }
        sub unset_background { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BACKGROUND_KEY); $s->{bg}              = undef; return $s }
        sub unset_underline  { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::UNDERLINE_KEY);  $s->{underline_style} = 0;     return $s }
        sub unset_underline_color { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::UNDERLINE_COLOR_KEY); $s->{ul}     = undef; return $s }
        sub unset_width           { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::WIDTH_KEY);           $s->{width}  = 0;     return $s }
        sub unset_height          { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::HEIGHT_KEY);          $s->{height} = 0;     return $s }

        sub unset_align {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::ALIGN_HORIZONTAL_KEY);
            $s->_unset(Cancer::Lipgloss::ALIGN_VERTICAL_KEY);
            $s->{align_h} = 0;
            $s->{align_v} = 0;
            return $s;
        }
        sub unset_align_horizontal { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::ALIGN_HORIZONTAL_KEY); $s->{align_h} = 0; return $s }
        sub unset_align_vertical   { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::ALIGN_VERTICAL_KEY);   $s->{align_v} = 0; return $s }

        sub unset_padding {
            my $s = shift->clone;
            for my $k (
                Cancer::Lipgloss::PADDING_TOP_KEY,    Cancer::Lipgloss::PADDING_RIGHT_KEY,
                Cancer::Lipgloss::PADDING_BOTTOM_KEY, Cancer::Lipgloss::PADDING_LEFT_KEY,
                Cancer::Lipgloss::PADDING_CHAR_KEY
            ) {
                $s->_unset($k);
            }
            $s->{padding_top} = $s->{padding_right} = $s->{padding_bottom} = $s->{padding_left} = $s->{padding_char} = 0;
            return $s;
        }
        sub unset_padding_top    { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::PADDING_TOP_KEY);    $s->{padding_top}    = 0; return $s }
        sub unset_padding_right  { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::PADDING_RIGHT_KEY);  $s->{padding_right}  = 0; return $s }
        sub unset_padding_bottom { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::PADDING_BOTTOM_KEY); $s->{padding_bottom} = 0; return $s }
        sub unset_padding_left   { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::PADDING_LEFT_KEY);   $s->{padding_left}   = 0; return $s }
        sub unset_padding_char   { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::PADDING_CHAR_KEY);   $s->{padding_char}   = 0; return $s }

        sub unset_margins {
            my $s = shift->clone;
            for my $k (
                Cancer::Lipgloss::MARGIN_TOP_KEY,    Cancer::Lipgloss::MARGIN_RIGHT_KEY,
                Cancer::Lipgloss::MARGIN_BOTTOM_KEY, Cancer::Lipgloss::MARGIN_LEFT_KEY
            ) {
                $s->_unset($k);
            }
            $s->{margin_top} = $s->{margin_right} = $s->{margin_bottom} = $s->{margin_left} = 0;
            return $s;
        }
        sub unset_margin_top        { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MARGIN_TOP_KEY);        $s->{margin_top}    = 0; return $s }
        sub unset_margin_right      { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MARGIN_RIGHT_KEY);      $s->{margin_right}  = 0; return $s }
        sub unset_margin_bottom     { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MARGIN_BOTTOM_KEY);     $s->{margin_bottom} = 0; return $s }
        sub unset_margin_left       { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MARGIN_LEFT_KEY);       $s->{margin_left}   = 0; return $s }
        sub unset_margin_background { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MARGIN_BACKGROUND_KEY); $s->{margin_bg} = undef; return $s }
        sub unset_border_style      { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BORDER_STYLE_KEY);      $s->{border}    = undef; return $s }
        sub unset_border_top        { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BORDER_TOP_KEY);        return $s }
        sub unset_border_right      { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BORDER_RIGHT_KEY);      return $s }
        sub unset_border_bottom     { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BORDER_BOTTOM_KEY);     return $s }
        sub unset_border_left       { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::BORDER_LEFT_KEY);       return $s }

        sub unset_border_top_foreground {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_TOP_FG_KEY);
            $s->{border_top_fg} = undef;
            return $s;
        }

        sub unset_border_right_foreground {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_RIGHT_FG_KEY);
            $s->{border_right_fg} = undef;
            return $s;
        }

        sub unset_border_bottom_foreground {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_BOTTOM_FG_KEY);
            $s->{border_bottom_fg} = undef;
            return $s;
        }

        sub unset_border_left_foreground {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_LEFT_FG_KEY);
            $s->{border_left_fg} = undef;
            return $s;
        }

        sub unset_border_top_background {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_TOP_BG_KEY);
            $s->{border_top_bg} = undef;
            return $s;
        }

        sub unset_border_right_background {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_RIGHT_BG_KEY);
            $s->{border_right_bg} = undef;
            return $s;
        }

        sub unset_border_bottom_background {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_BOTTOM_BG_KEY);
            $s->{border_bottom_bg} = undef;
            return $s;
        }

        sub unset_border_left_background {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_LEFT_BG_KEY);
            $s->{border_left_bg} = undef;
            return $s;
        }
        sub unset_color_whitespace     { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::COLOR_WHITESPACE_KEY);     return $s }
        sub unset_inline               { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::INLINE_KEY);               return $s }
        sub unset_underline_spaces     { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::UNDERLINE_SPACES_KEY);     return $s }
        sub unset_strikethrough_spaces { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::STRIKETHROUGH_SPACES_KEY); return $s }

        sub unset_hyperlink {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::LINK_KEY);
            $s->_unset(Cancer::Lipgloss::LINK_PARAMS_KEY);
            $s->{link}        = '';
            $s->{link_params} = '';
            return $s;
        }
        sub unset_string     { my $s = shift->clone; $s->{value} = ''; return $s }
        sub unset_max_width  { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MAX_WIDTH_KEY);  $s->{max_width}  = 0;     return $s }
        sub unset_max_height { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::MAX_HEIGHT_KEY); $s->{max_height} = 0;     return $s }
        sub unset_tab_width  { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::TAB_WIDTH_KEY);  $s->{tab_width}  = 0;     return $s }
        sub unset_transform  { my $s = shift->clone; $s->_unset(Cancer::Lipgloss::TRANSFORM_KEY);  $s->{transform}  = undef; return $s }

        sub unset_border_foreground {
            my $s = shift->clone;
            for my $k (
                Cancer::Lipgloss::BORDER_TOP_FG_KEY,    Cancer::Lipgloss::BORDER_RIGHT_FG_KEY,
                Cancer::Lipgloss::BORDER_BOTTOM_FG_KEY, Cancer::Lipgloss::BORDER_LEFT_FG_KEY
            ) {
                $s->_unset($k);
            }
            $s->{border_top_fg} = $s->{border_right_fg} = $s->{border_bottom_fg} = $s->{border_left_fg} = undef;
            return $s;
        }

        sub unset_border_background {
            my $s = shift->clone;
            for my $k (
                Cancer::Lipgloss::BORDER_TOP_BG_KEY,    Cancer::Lipgloss::BORDER_RIGHT_BG_KEY,
                Cancer::Lipgloss::BORDER_BOTTOM_BG_KEY, Cancer::Lipgloss::BORDER_LEFT_BG_KEY
            ) {
                $s->_unset($k);
            }
            $s->{border_top_bg} = $s->{border_right_bg} = $s->{border_bottom_bg} = $s->{border_left_bg} = undef;
            return $s;
        }

        sub unset_border_foreground_blend {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_BLEND_FG_KEY);
            $s->{border_blend_fg} = [];
            return $s;
        }

        sub unset_border_foreground_blend_offset {
            my $s = shift->clone;
            $s->_unset(Cancer::Lipgloss::BORDER_BLEND_FG_OFFSET_KEY);
            $s->{border_blend_fg_offset} = 0;
            return $s;
        }
    }

    # ---- Border presets --------------------------------------------------------------------------------------------------
    my %border_presets;

    sub _make_border (%args) {
        return bless {
            top           => $args{top}           // '',
            bottom        => $args{bottom}        // '',
            left          => $args{left}          // '',
            right         => $args{right}         // '',
            top_left      => $args{top_left}      // '',
            top_right     => $args{top_right}     // '',
            bottom_left   => $args{bottom_left}   // '',
            bottom_right  => $args{bottom_right}  // '',
            middle_left   => $args{middle_left}   // '',
            middle_right  => $args{middle_right}  // '',
            middle        => $args{middle}        // '',
            middle_top    => $args{middle_top}    // '',
            middle_bottom => $args{middle_bottom} // ''
            },
            'Cancer::Lipgloss::Border';
    }

    package Cancer::Lipgloss::Border {
        sub new { _make_border(@_) }
    }
    my $no_border = _make_border();
    $Cancer::Lipgloss::no_border = $no_border;
    sub NoBorder () {$no_border}

    sub NormalBorder () {
        _make_border(
            top           => '─',
            bottom        => '─',
            left          => '│',
            right         => '│',
            top_left      => '┌',
            top_right     => '┐',
            bottom_left   => '└',
            bottom_right  => '┘',
            middle_left   => '├',
            middle_right  => '┤',
            middle        => '┼',
            middle_top    => '┬',
            middle_bottom => '┴'
        );
    }

    sub RoundedBorder () {
        _make_border(
            top           => '─',
            bottom        => '─',
            left          => '│',
            right         => '│',
            top_left      => '╭',
            top_right     => '╮',
            bottom_left   => '╰',
            bottom_right  => '╯',
            middle_left   => '├',
            middle_right  => '┤',
            middle        => '┼',
            middle_top    => '┬',
            middle_bottom => '┴'
        );
    }

    sub BlockBorder () {
        _make_border(
            top           => '█',
            bottom        => '█',
            left          => '█',
            right         => '█',
            top_left      => '█',
            top_right     => '█',
            bottom_left   => '█',
            bottom_right  => '█',
            middle_left   => '█',
            middle_right  => '█',
            middle        => '█',
            middle_top    => '█',
            middle_bottom => '█'
        );
    }

    sub ThickBorder () {
        _make_border(
            top           => '━',
            bottom        => '━',
            left          => '┃',
            right         => '┃',
            top_left      => '┏',
            top_right     => '┓',
            bottom_left   => '┗',
            bottom_right  => '┛',
            middle_left   => '┣',
            middle_right  => '┫',
            middle        => '╋',
            middle_top    => '┳',
            middle_bottom => '┻'
        );
    }

    sub DoubleBorder () {
        _make_border(
            top           => '═',
            bottom        => '═',
            left          => '║',
            right         => '║',
            top_left      => '╔',
            top_right     => '╗',
            bottom_left   => '╚',
            bottom_right  => '╝',
            middle_left   => '╠',
            middle_right  => '╣',
            middle        => '╬',
            middle_top    => '╦',
            middle_bottom => '╩'
        );
    }

    sub HiddenBorder () {
        _make_border(
            top           => ' ',
            bottom        => ' ',
            left          => ' ',
            right         => ' ',
            top_left      => ' ',
            top_right     => ' ',
            bottom_left   => ' ',
            bottom_right  => ' ',
            middle_left   => ' ',
            middle_right  => ' ',
            middle        => ' ',
            middle_top    => ' ',
            middle_bottom => ' '
        );
    }

    sub MarkdownBorder () {
        _make_border(
            top           => "-",
            bottom        => "-",
            left          => "|",
            right         => "|",
            top_left      => "|",
            top_right     => "|",
            bottom_left   => "|",
            bottom_right  => "|",
            middle_left   => "|",
            middle_right  => "|",
            middle        => "|",
            middle_top    => "|",
            middle_bottom => "|"
        );
    }

    sub ASCIIBorder () {
        _make_border(
            top           => "-",
            bottom        => "-",
            left          => "|",
            right         => "|",
            top_left      => "+",
            top_right     => "+",
            bottom_left   => "+",
            bottom_right  => "+",
            middle_left   => "+",
            middle_right  => "+",
            middle        => "+",
            middle_top    => "+",
            middle_bottom => "+"
        );
    }

    sub OuterHalfBlockBorder () {
        _make_border(
            top           => '▀',
            bottom        => '▄',
            left          => '▌',
            right         => '▐',
            top_left      => '▛',
            top_right     => '▜',
            bottom_left   => '▙',
            bottom_right  => '▟'
        );
    }

    sub InnerHalfBlockBorder () {
        _make_border(
            top           => '▄',
            bottom        => '▀',
            left          => '▐',
            right         => '▌',
            top_left      => '▗',
            top_right     => '▖',
            bottom_left   => '▝',
            bottom_right  => '▘'
        );
    }

    # ---- Constructor --------------------------------------------------------------------------------------------------------
    sub NewStyle () {
        Cancer::Lipgloss::Style->new;
    }

    # ---- Internal helpers ----------------------------------------------------------------------------------------------
    sub _is_no_color ($c) {
        return 1 unless defined $c;
        return 0 unless ref $c;
        return $c->isa('Cancer::Lipgloss::NoColor') if blessed($c);
        return 0;
    }

    sub _maybe_convert_tabs {
        my ( $str, $style ) = @_;
        my $tw = Cancer::Lipgloss::TAB_WIDTH_DEFAULT;
        $tw = $style->{tab_width} if $style && $style->is_set(Cancer::Lipgloss::TAB_WIDTH_KEY);
        return $str if $tw == -1;
        return $str =~ s/\t//gr if $tw == 0;
        return $str =~ s/\t/(' ' x $tw)/ger;
    }

    # Split a string into extended grapheme clusters (\X) instead of code
    # points, so emoji ZWJ sequences and combining marks stay intact.
    sub _graphemes {
        my @g;
        push @g, $1 while $_[0] =~ /(\X)/gc;
        return @g;
    }

    sub _max_rune_width {
        my $s = shift;
        return 0 unless defined $s && length($s);
        my $max = 0;

        # \X so multi-code-point graphemes (emoji, combining marks) measure as
        # one cell-wide unit instead of being torn into code points.
        while ( $s =~ /(\X)/gc ) {
            my $w = grapheme_width($1);
            $max = $w if $w > $max;
        }
        return $max;
    }

    # Build SGR sequence for foreground color
    # Return SGR param string only (no \e[ or m wrapper)
    sub _color_sgr_fg {
        my $c = shift;
        return '' if _is_no_color($c);
        if ( $c->isa('Cancer::Lipgloss::BasicColor') ) {
            my $i = $c->index;
            return $i < 8 ? ( 30 + $i ) : ( 82 + $i );
        }
        if ( $c->isa('Cancer::Lipgloss::IndexedColor') ) {
            return "38;5;" . $c->index;
        }
        if ( $c->isa('Cancer::Lipgloss::RGBColor') ) {
            return "38;2;" . $c->{R} . ";" . $c->{G} . ";" . $c->{B};
        }
        if ( $c->can('RGBA') ) {
            my ( $r, $g, $b ) = $c->RGBA;
            return "38;2;$r;$g;$b";
        }
        return '';
    }

    sub _color_sgr_bg {
        my $c = shift;
        return '' if _is_no_color($c);
        if ( $c->isa('Cancer::Lipgloss::BasicColor') ) {
            my $i = $c->index;
            return $i < 8 ? ( 40 + $i ) : ( 92 + $i );
        }
        if ( $c->isa('Cancer::Lipgloss::IndexedColor') ) {
            return "48;5;" . $c->index;
        }
        if ( $c->isa('Cancer::Lipgloss::RGBColor') ) {
            return "48;2;" . $c->{R} . ";" . $c->{G} . ";" . $c->{B};
        }
        if ( $c->can('RGBA') ) {
            my ( $r, $g, $b ) = $c->RGBA;
            return "48;2;$r;$g;$b";
        }
        return '';
    }

    sub _color_sgr_ul {
        my $c = shift;
        return '' if _is_no_color($c);
        if ( $c->isa('Cancer::Lipgloss::RGBColor') ) {
            return "58;2;" . $c->{R} . ";" . $c->{G} . ";" . $c->{B};
        }
        if ( $c->isa('Cancer::Lipgloss::IndexedColor') ) {
            return "58;5;" . $c->index;
        }
        return '';
    }

    # ---- Alignment ------------------------------------------------------------------------------------------------------------
    sub _align_horizontal {
        my ( $str, $pos, $width, $style ) = @_;
        my @lines = split /\n/, $str, -1;
        @lines = ('') unless @lines;
        my $widest = 0;
        for my $l (@lines) {
            my $w = string_width($l);
            $widest = $w if $w > $widest;
        }
        my $out = '';
        for my $i ( 0 .. $#lines ) {
            my $l     = $lines[$i];
            my $lw    = string_width($l);
            my $short = $widest - $lw;
            $short += _max( 0, $width - ( $short + $lw ) );
            if ( $short > 0 ) {
                my $sp = ' ' x $short;
                $sp = $style . $sp . "\e[m" if $style;
                if ( $pos >= 0.99 ) {    # Right (1.0)
                    $l = $sp . $l;
                }
                elsif ( $pos > 0.01 && $pos < 0.99 ) {    # Center (0.5)
                    my $left  = int( $short / 2 );
                    my $right = $left + $short % 2;
                    my $ls    = ' ' x $left;
                    my $rs    = ' ' x $right;
                    $ls = $style . $ls . "\e[m" if $style;
                    $rs = $style . $rs . "\e[m" if $style;
                    $l  = $ls . $l . $rs;
                }
                else {                                    # Left (0.0)
                    $l .= $sp;
                }
            }
            $out .= $l;
            $out .= "\n" if $i < $#lines;
        }
        return $out;
    }

    sub _align_vertical {
        my ( $str, $pos, $height ) = @_;
        my $str_height = ( $str =~ tr/\n// ) + 1;
        return $str if $height < $str_height;
        my $extra = $height - $str_height;
        if ( $pos >= 0.99 ) {    # Bottom
            $str = "\n" x $extra . $str;
        }
        elsif ( $pos > 0.01 && $pos < 0.99 ) {    # Center
            my $top = int( $extra / 2 );
            my $bot = $extra - $top;
            $str = "\n" x $top . $str . "\n" x $bot;
        }
        else {                                    # Top
            $str .= "\n" x $extra;
        }
        return $str;
    }

    # ---- Padding helpers ------------------------------------------------------------------------------------------------
    sub _pad_left {
        my ( $str, $n, $style, $pad_char ) = @_;
        my $sp = $pad_char x $n;
        $sp = $style . $sp . "\e[m" if $style;
        my @lines = split /\n/, $str, -1;
        @lines = ('') unless @lines;
        my $out = '';
        for my $i ( 0 .. $#lines ) {
            $out .= "\n" if $i > 0;
            $out .= $sp . $lines[$i];
        }
        return $out;
    }

    sub _pad_right {
        my ( $str, $n, $style, $pad_char ) = @_;
        my $sp = $pad_char x $n;
        $sp = $style . $sp . "\e[m" if $style;
        my @lines = split /\n/, $str, -1;
        @lines = ('') unless @lines;
        my $out = '';
        for my $i ( 0 .. $#lines ) {
            $out .= "\n" if $i > 0;
            $out .= $lines[$i] . $sp;
        }
        return $out;
    }

    # ---- Border rendering ----------------------------------------------------------------------------------------------
    sub _render_horizontal_edge {
        my ( $left, $middle, $right, $width ) = @_;
        $middle = ' ' unless defined $middle && length $middle;
        my $left_w  = string_width($left);
        my $right_w = string_width($right);
        my @runes   = _graphemes($middle);
        my $j       = 0;
        my $out     = $left;
        for ( my $i = 0; $i < $width - $left_w - $right_w; ) {
            my $r = $runes[$j];
            $out .= $r;
            $i += grapheme_width($r);
            $j++;
            $j = 0 if $j >= @runes;
        }
        $out .= $right;
        return $out;
    }

    sub _apply_border {
        my ( $self, $str ) = @_;

        # Local copy: corner fill-in below mutates the border table, which is
        # often a shared constant (e.g. RoundedBorder()) that must stay clean.
        my $border     = { %{ $self->get_border_style } };
        my $has_top    = $self->is_set(Cancer::Lipgloss::BORDER_TOP_KEY);
        my $has_right  = $self->is_set(Cancer::Lipgloss::BORDER_RIGHT_KEY);
        my $has_bottom = $self->is_set(Cancer::Lipgloss::BORDER_BOTTOM_KEY);
        my $has_left   = $self->is_set(Cancer::Lipgloss::BORDER_LEFT_KEY);
        if ( $self->is_border_style_set_without_sides ) {
            $has_top = $has_right = $has_bottom = $has_left = 1;
        }
        return $str if !defined $border || ( !$has_top && !$has_right && !$has_bottom && !$has_left );
        my @lines = split /\n/, $str, -1;
        @lines = ('') unless @lines;
        my $w = 0;
        for my $l (@lines) { my $lw = string_width($l); $w = $lw if $lw > $w }
        if ($has_left) {
            my $lw = Cancer::Lipgloss::_max_rune_width( $border->{left} // '' );
            $w += $lw if $lw;
        }
        if ($has_right) {
            my $rw = Cancer::Lipgloss::_max_rune_width( $border->{right} // '' );
            $w += $rw if $rw;
        }

        # Fill in empty corners
        $border->{top_left}     = ' ' if $has_top    && $has_left  && !length( $border->{top_left}     // '' );
        $border->{top_right}    = ' ' if $has_top    && $has_right && !length( $border->{top_right}    // '' );
        $border->{bottom_left}  = ' ' if $has_bottom && $has_left  && !length( $border->{bottom_left}  // '' );
        $border->{bottom_right} = ' ' if $has_bottom && $has_right && !length( $border->{bottom_right} // '' );

        # Remove corners for missing sides
        if ($has_top) {
            $border->{top_left}  = '' unless $has_left;
            $border->{top_right} = '' unless $has_right;
        }
        if ($has_bottom) {
            $border->{bottom_left}  = '' unless $has_left;
            $border->{bottom_right} = '' unless $has_right;
        }
        my $top_fg    = $self->get_border_top_fg;
        my $right_fg  = $self->get_border_right_fg;
        my $bottom_fg = $self->get_border_bottom_fg;
        my $left_fg   = $self->get_border_left_fg;
        my $top_bg    = $self->get_border_top_bg;
        my $right_bg  = $self->get_border_right_bg;
        my $bottom_bg = $self->get_border_bottom_bg;
        my $left_bg   = $self->get_border_left_bg;
        my $out       = '';

        # Check for blend colors
        my $blend_fg = $self->get_border_blend_fg;
        my $blend;
        if ( ref $blend_fg eq 'ARRAY' && @$blend_fg > 1 ) {
            $blend = Cancer::Lipgloss::_border_blend( $self, $w, scalar @lines, @$blend_fg );
        }

        # Calculate inner content width (total minus border columns)
        my $inner_w = $w;
        if ($has_left) {
            my $lw = Cancer::Lipgloss::_max_rune_width( $border->{left} // '' );
            $inner_w -= $lw if $lw;
        }
        if ($has_right) {
            my $rw = Cancer::Lipgloss::_max_rune_width( $border->{right} // '' );
            $inner_w -= $rw if $rw;
        }

        # Top border
        if ($has_top) {
            my $top = Cancer::Lipgloss::_render_horizontal_edge( $border->{top_left} // '', $border->{top} // '', $border->{top_right} // '', $w );
            if ($blend) {
                $out .= Cancer::Lipgloss::_style_border_blend( $top, $blend->{top}, $top_bg ) . "\n";
            }
            else {
                $out .= Cancer::Lipgloss::_style_border( $top, $top_fg, $top_bg ) . "\n";
            }
        }

        # Sides
        my @left_runes  = _graphemes( $border->{left}  // ' ' );
        my @right_runes = _graphemes( $border->{right} // ' ' );
        my $li          = 0;
        my $ri          = 0;
        for my $i ( 0 .. $#lines ) {
            if ($has_left) {
                my $ch = $left_runes[ $li % @left_runes ];
                $li++;
                if ($blend) {
                    my $lc = $blend->{left}[$i] // $left_fg;
                    $out .= Cancer::Lipgloss::_style_border( $ch, $lc, $left_bg );
                }
                else {
                    $out .= Cancer::Lipgloss::_style_border( $ch, $left_fg, $left_bg );
                }
            }
            my $line_width = string_width( $lines[$i] );
            my $pad        = $inner_w - $line_width;
            $out .= $lines[$i];
            $out .= ' ' x $pad if $pad > 0;
            if ($has_right) {
                my $ch = $right_runes[ $ri % @right_runes ];
                $ri++;
                if ($blend) {
                    my $rc = $blend->{right}[$i] // $right_fg;
                    $out .= Cancer::Lipgloss::_style_border( $ch, $rc, $right_bg );
                }
                else {
                    $out .= Cancer::Lipgloss::_style_border( $ch, $right_fg, $right_bg );
                }
            }
            $out .= "\n" if $i < $#lines;
        }

        # Bottom border
        if ($has_bottom) {
            my $bottom
                = Cancer::Lipgloss::_render_horizontal_edge( $border->{bottom_left} // '', $border->{bottom} // '', $border->{bottom_right} // '',
                $w );
            $out .= "\n" if length $out && $out !~ /\n$/;
            if ($blend) {
                $out .= Cancer::Lipgloss::_style_border_blend( $bottom, $blend->{bottom}, $bottom_bg );
            }
            else {
                $out .= Cancer::Lipgloss::_style_border( $bottom, $bottom_fg, $bottom_bg );
            }
        }
        return $out;
    }

    sub _style_border {
        my ( $border, $fg, $bg ) = @_;
        return $border if _is_no_color($fg) && _is_no_color($bg);
        my @params;
        push @params, _color_sgr_fg($fg) unless _is_no_color($fg);
        push @params, _color_sgr_bg($bg) unless _is_no_color($bg);
        return ( @params ? "\e[" . join( ';', @params ) . "m" : '' ) . $border . "\e[m";
    }

    sub _style_border_blend {
        my ( $border_str, $fg_colors, $bg ) = @_;

        # \X: one color per grapheme cluster so blend gradients stay aligned
        # with the actual cells they paint.
        my @graphemes = _graphemes($border_str);
        my $out       = '';
        my $i         = 0;
        for my $g (@graphemes) {
            next if $g eq '';
            my @params;
            if ( $i < scalar @$fg_colors && !_is_no_color( $fg_colors->[$i] ) ) {
                push @params, _color_sgr_fg( $fg_colors->[$i] );
            }
            push @params, _color_sgr_bg($bg) if !_is_no_color($bg);
            my $s = @params ? "\e[" . join( ';', @params ) . "m" : '';
            $out .= $s . $g . "\e[m" if length $s;
            $out .= $g unless length $s;
            $i++;
        }
        return $out;
    }

    sub _border_blend {
        my ( $self, $width, $num_lines, @colors ) = @_;
        my $total    = ( $num_lines + $width + 2 ) * 2;
        my $gradient = blend_1d( $total, @colors );

        # Rotate by offset
        my $offset = $self->get_border_blend_fg_offset;
        if ($offset) {
            my $r = -$offset;
            my $n = scalar @$gradient;
            $r %= $n;
            $r += $n if $r < 0;
            my @arr = @$gradient;
            @arr[ 0 .. $r - 1 ]  = reverse @arr[ 0 .. $r - 1 ];
            @arr[ $r .. $n - 1 ] = reverse @arr[ $r .. $n - 1 ];
            @arr                 = reverse @arr;
            $gradient            = \@arr;
        }
        my $pos  = 0;
        my $take = sub {
            my $size = shift;
            my @s    = @$gradient[ $pos .. $pos + $size - 1 ];
            $pos += $size;
            return \@s;
        };
        my $blend = { top => $take->( $width + 2 ), right => $take->($num_lines), bottom => $take->( $width + 2 ), left => $take->($num_lines) };

        # bottom and left are reversed because they are drawn in reverse order
        $blend->{bottom} = [ reverse @{ $blend->{bottom} } ];
        $blend->{left}   = [ reverse @{ $blend->{left} } ];
        return $blend;
    }

    # ---- Margin rendering ----------------------------------------------------------------------------------------------
    sub _apply_margins {
        my ( $self, $str, $inline ) = @_;
        my $tm    = $self->get_margin_top;
        my $rm    = $self->get_margin_right;
        my $bm    = $self->get_margin_bottom;
        my $lm    = $self->get_margin_left;
        my $bgc   = $self->get_margin_background;
        my $style = '';
        if ( !Cancer::Lipgloss::_is_no_color($bgc) ) {
            my $bg_param = Cancer::Lipgloss::_color_sgr_bg($bgc);
            $style = $bg_param ? "\e[${bg_param}m" : '';
        }
        my $mchar = chr( $self->get_margin_char );
        my $msp   = $mchar x ( $lm > $rm ? $lm : $rm );
        $msp = $style . $msp . "\e[m" if $style && length $msp;

        # Left and right margin
        $str = Cancer::Lipgloss::_pad_left( $str, $lm, $style  ? $style : undef, $mchar ) if $lm;
        $str = Cancer::Lipgloss::_pad_right( $str, $rm, $style ? $style : undef, $mchar ) if $rm;

        # Top and bottom margin
        if ( !$inline ) {
            my ( undef, $w ) = Cancer::Lipgloss::_get_lines($str);
            my $spaces = ' ' x $w;
            $spaces = $style . $spaces . "\e[m" if $style;
            if ( $tm > 0 ) {
                $str = ( $spaces . "\n" ) x $tm . $str;
            }
            if ( $bm > 0 ) {
                $str .= ( "\n" . $spaces ) x $bm;
            }
        }
        return $str;
    }

    sub _get_lines {
        my $str   = shift;
        my @lines = split /\n/, $str, -1;
        @lines = ('') unless @lines;
        my $widest = 0;
        for my $l (@lines) {
            my $w = string_width($l);
            $widest = $w if $w > $widest;
        }
        return ( \@lines, $widest );
    }

    sub _max {
        my ( $a, $b ) = @_;
        return $a > $b ? $a : $b;
    }

    # ---- Layout: JoinHorizontal / JoinVertical ------------------------------------------------------
    sub JoinHorizontal {
        my ( $pos, @strs ) = @_;
        return '' unless @strs;
        return $strs[0] if @strs == 1;
        my @blocks;
        my @max_widths;
        my $max_height = 0;
        for my $str (@strs) {
            my ( $lines, $mw ) = _get_lines($str);
            push @blocks,     $lines;
            push @max_widths, $mw;
            $max_height = scalar @$lines if scalar @$lines > $max_height;
        }

        # Pad shorter blocks to same height
        for my $i ( 0 .. $#blocks ) {
            next if @{ $blocks[$i] } >= $max_height;
            my $extra = $max_height - scalar @{ $blocks[$i] };
            my @fill  = ('') x $extra;
            my $pv    = _pos_value($pos);
            if ( $pv <= 0.01 ) {    # Top
                push @{ $blocks[$i] }, @fill;
            }
            elsif ( $pv >= 0.99 ) {    # Bottom
                unshift @{ $blocks[$i] }, @fill;
            }
            else {                     # Middle
                my $split   = int( $extra * $pv + 0.5 );
                my $top     = $extra - $split;
                my $bottom  = $split;
                my @pad_top = ('') x $top;
                my @pad_bot = ('') x $bottom;
                unshift @{ $blocks[$i] }, @pad_top;
                push @{ $blocks[$i] }, @pad_bot;
            }
        }
        my $out = '';
        for my $row ( 0 .. $max_height - 1 ) {
            for my $col ( 0 .. $#blocks ) {
                my $line = $blocks[$col][$row] // '';
                $out .= $line;
                my $lw  = string_width($line);
                my $pad = $max_widths[$col] - $lw;
                $out .= ' ' x $pad if $pad > 0;
            }
            $out .= "\n" if $row < $max_height - 1;
        }
        return $out;
    }

    sub JoinVertical {
        my ( $pos, @strs ) = @_;
        return '' unless @strs;
        return $strs[0] if @strs == 1;
        my @blocks;
        my $max_width = 0;
        for my $str (@strs) {
            my ( $lines, $mw ) = _get_lines($str);
            push @blocks, $lines;
            $max_width = $mw if $mw > $max_width;
        }
        my $out = '';
        for my $bi ( 0 .. $#blocks ) {
            my $block = $blocks[$bi];
            for my $li ( 0 .. $#$block ) {
                my $line = $block->[$li];
                my $lw   = string_width($line);
                my $w    = $max_width - $lw;
                my $pv   = _pos_value($pos);
                if ( $pv <= 0.01 ) {    # Left
                    $out .= $line;
                    $out .= ' ' x $w if $w > 0;
                }
                elsif ( $pv >= 0.99 ) {    # Right
                    $out .= ' ' x $w if $w > 0;
                    $out .= $line;
                }
                else {                     # Center
                    if ( $w > 0 ) {
                        my $split = int( $w * $pv + 0.5 );
                        my $left  = $w - $split;
                        my $right = $split;
                        $out .= ' ' x $left;
                        $out .= $line;
                        $out .= ' ' x $right;
                    }
                    else {
                        $out .= $line;
                    }
                }
                my $is_last_line = ( $bi == $#blocks && $li == $#$block );
                $out .= "\n" unless $is_last_line;
            }
        }
        return $out;
    }

    # ---- Whitespace options ------------------------------------------------------------------------------------------
    package Cancer::Lipgloss::WhitespaceOpts {
        sub new { bless { style => undef, chars => undef }, shift }
        sub style : lvalue { $_[0]->{style} }
        sub chars : lvalue { $_[0]->{chars} }
    }

    sub WithWhitespaceStyle ($s) {
        return sub { $_[0]->style = $s }
    }

    sub WithWhitespaceChars ($c) {
        return sub { $_[0]->chars = $c }
    }

    # ---- Layout: Place / PlaceHorizontal / PlaceVertical --------------------------------
    sub PlaceHorizontal {
        my ( $width, $pos, $str, @opts ) = @_;
        my $ws_opts = _parse_ws_opts(@opts);
        my ( $lines, $content_width ) = _get_lines($str);
        my $gap = $width - $content_width;
        return $str if $gap <= 0;
        my $out = '';
        for my $i ( 0 .. $#$lines ) {
            my $line  = $lines->[$i];
            my $lw    = string_width($line);
            my $short = $content_width - $lw;
            my $total = $gap + $short;
            my $pv    = _pos_value($pos);
            my $ws    = _build_ws( $total, $ws_opts );
            if ( $pv <= 0.01 ) {    # Left
                $out .= $line . $ws;
            }
            elsif ( $pv >= 0.99 ) {    # Right
                $out .= $ws . $line;
            }
            else {                     # Center
                my $split = int( $total * $pv + 0.5 );
                my $left  = $total - $split;
                my $right = $split;
                $out .= _build_ws( $left, $ws_opts ) . $line . _build_ws( $right, $ws_opts );
            }
            $out .= "\n" if $i < $#$lines;
        }
        return $out;
    }

    sub PlaceVertical {
        my ( $height, $pos, $str, @opts ) = @_;
        my $ws_opts        = _parse_ws_opts(@opts);
        my $content_height = ( $str =~ tr/\n// ) + 1;
        my $gap            = $height - $content_height;
        return $str if $gap <= 0;
        my ( undef, $w ) = _get_lines($str);
        my $ws  = _build_ws( $w, $ws_opts );
        my $out = '';
        my $pv  = _pos_value($pos);

        if ( $pv <= 0.01 ) {    # Top
            $out .= $str;
            $out .= "\n" . $ws for 1 .. $gap;
        }
        elsif ( $pv >= 0.99 ) {    # Bottom
            $out .= ( $ws . "\n" ) x $gap;
            $out .= $str;
        }
        else {                     # Center
            my $split  = int( $gap * $pv + 0.5 );
            my $top    = $gap - $split;
            my $bottom = $split;
            $out .= ( $ws . "\n" ) x $top;
            $out .= $str;
            $out .= "\n" . $ws for 1 .. $bottom;
        }
        return $out;
    }

    sub Place {
        my ( $width, $height, $hpos, $vpos, $str, @opts ) = @_;
        return PlaceVertical( $height, $vpos, PlaceHorizontal( $width, $hpos, $str, @opts ), @opts );
    }

    sub _parse_ws_opts {
        my $wso   = Cancer::Lipgloss::WhitespaceOpts->new;
        my $found = 0;
        for my $o (@_) {
            if ( ref $o eq 'CODE' ) {
                $o->($wso);
                $found = 1;
            }
            elsif ( ref $o && $o->isa('Cancer::Lipgloss::WhitespaceOpts') ) {
                $wso   = $o;
                $found = 1;
            }
        }
        return $found ? $wso : undef;
    }

    sub _build_ws {
        my ( $total, $opts ) = @_;
        return ' ' x $total unless $opts;
        my $chars = $opts->chars;
        $chars = ' ' unless defined $chars && length $chars;
        my $result = '';
        my $i      = 0;
        my $cw     = Cancer::Util::string_width($chars);
        $cw = 1 unless $cw;

        while ( Cancer::Util::string_width($result) < $total ) {
            $result .= substr( $chars, $i % length($chars), 1 );
            $i++;
        }

        # Trim to exact display width by removing trailing chars that overflow
        while ( length($result) > 0 && Cancer::Util::string_width($result) > $total ) {
            $result = substr( $result, 0, length($result) - 1 );
        }
        if ( $opts->style ) {
            $result = $opts->style->render($result);
        }
        return $result;
    }

    # ---- Ranges / Runes --------------------------------------------------------------------------------------------------
    sub StyleRanges {
        my ( $str, @ranges ) = @_;
        return $str unless @ranges;
        my $out      = '';
        my $last     = 0;
        my $stripped = Cancer::Util::strip_ansi($str);
        for my $rng (@ranges) {
            if ( $rng->{start} > $last ) {
                $out .= Cancer::Util::cut( $str, $last, $rng->{start} );
            }
            my $content = substr( $stripped, $rng->{start}, $rng->{end} - $rng->{start} );
            $out .= $rng->{style}->render($content);
            $last = $rng->{end};
        }
        $out .= Cancer::Util::truncate_left( $str, $last, '' );
        return $out;
    }

    sub NewRange {
        my ( $start, $end, $style ) = @_;
        return { start => $start, end => $end, style => $style };
    }

    sub StyleRunes {
        my ( $str, $indices, $matched, $unmatched ) = @_;
        my %m     = map { $_ => 1 } @$indices;
        my $out   = '';
        my $group = '';

        # \X: indices address whole grapheme clusters, so styling a rune index
        # never tears an emoji or a letter with combining marks.
        my @runes = _graphemes($str);
        for my $i ( 0 .. $#runes ) {
            $group .= $runes[$i];
            my $matches    = exists $m{$i};
            my $next_match = exists $m{ $i + 1 };
            if ( $matches != $next_match || $i == $#runes ) {
                my $style = $matches ? $matched : $unmatched;
                $out .= $style->render($group);
                $group = '';
            }
        }
        return $out;
    }

    # ---- Print/Println family (colorprofile downsampling) ------------------------------
    my $_writer_profile;

    sub _ensure_writer_profile {
        return $_writer_profile if defined $_writer_profile;
        eval { require Cancer::ColorProfile };
        if ($@) { $_writer_profile = 'TrueColor' }
        else {
            my @profile = eval { Cancer::ColorProfile::Detect( \*STDOUT ) };
            $_writer_profile = @profile ? $profile[0] : 'TrueColor';
        }
        return $_writer_profile;
    }

    sub _downsample ($str) {
        my $profile = _ensure_writer_profile();
        return $str if $profile == TrueColor;

        # FAST PATH: nothing to strip or downsample without an escape byte.
        return $str if index( $str, "\e" ) == -1;
        if ( $profile == NoTTY || $profile == ASCII ) {
            $str =~ s/\e\[[0-9;]*m//g;
            return $str;
        }
        if ( $profile == ANSI ) {
            $str =~ s/\e\[38;2;(\d+);(\d+);(\d+)m/_downsample_fg_ansi($1,$2,$3)/ge;
            $str =~ s/\e\[48;2;(\d+);(\d+);(\d+)m/_downsample_bg_ansi($1,$2,$3)/ge;
            return $str;
        }
        if ( $profile == ANSI256 ) {
            $str =~ s/\e\[38;2;(\d+);(\d+);(\d+)m/_downsample_fg_256($1,$2,$3)/ge;
            $str =~ s/\e\[48;2;(\d+);(\d+);(\d+)m/_downsample_bg_256($1,$2,$3)/ge;
            return $str;
        }
        return $str;
    }

    sub _downsample_fg_ansi {
        my ( $r, $g, $b ) = @_;
        my $i = _rgb_to_16( $r, $g, $b );
        return $i < 8 ? "\e[" . ( 30 + $i ) . "m" : "\e[" . ( 82 + $i ) . "m";
    }

    sub _downsample_bg_ansi {
        my ( $r, $g, $b ) = @_;
        my $i = _rgb_to_16( $r, $g, $b );
        return $i < 8 ? "\e[" . ( 40 + $i ) . "m" : "\e[" . ( 92 + $i ) . "m";
    }

    sub _downsample_fg_256 {
        my ( $r, $g, $b ) = @_;
        my $i = _rgb_to_256( $r, $g, $b );
        return "\e[38;5;${i}m";
    }

    sub _downsample_bg_256 {
        my ( $r, $g, $b ) = @_;
        my $i = _rgb_to_256( $r, $g, $b );
        return "\e[48;5;${i}m";
    }

    sub _rgb_to_16 {
        my ( $r, $g, $b ) = @_;
        my $best  = 0;
        my $bestd = 1e30;
        my @basic = (
            [ 0,   0,   0 ],
            [ 128, 0,   0 ],
            [ 0,   128, 0 ],
            [ 128, 128, 0 ],
            [ 0,   0,   128 ],
            [ 128, 0,   128 ],
            [ 0,   128, 128 ],
            [ 192, 192, 192 ],
            [ 128, 128, 128 ],
            [ 255, 0,   0 ],
            [ 0,   255, 0 ],
            [ 255, 255, 0 ],
            [ 0,   0,   255 ],
            [ 255, 0,   255 ],
            [ 0,   255, 255 ],
            [ 255, 255, 255 ]
        );
        for my $i ( 0 .. 15 ) {
            my $dr = $r - $basic[$i][0];
            my $dg = $g - $basic[$i][1];
            my $db = $b - $basic[$i][2];
            my $d  = $dr * $dr + $dg * $dg + $db * $db;
            ( $best, $bestd ) = ( $i, $d ) if $d < $bestd;
        }
        return $best;
    }

    sub _rgb_to_256 {
        my ( $r, $g, $b ) = @_;
        if ( $r == $g && $g == $b ) {
            return 232 if $r < 8;
            return 255 if $r > 238;
            return 232 + int( ( $r - 8 ) / 10 );
        }
        my $ri = int( ( $r + 25 ) / 51 );
        my $gi = int( ( $g + 25 ) / 51 );
        my $bi = int( ( $b + 25 ) / 51 );
        return 16 + 36 * $ri + 6 * $gi + $bi;
    }

    sub _downsample_str {
        my $str = join ' ', @_;
        return _downsample($str);
    }
    my $_stdout_raw_set = 0;

    sub _ensure_raw_stdout {
        return if $_stdout_raw_set;
        if ( eval { require IO::Handle; 1 } ) {
            binmode STDOUT, ':raw';
        }
        if ( $^O eq 'MSWin32' ) {
            eval {
                require Win32::API;
                my $get_std_handle   = Win32::API->new( 'kernel32', 'GetStdHandle',       'N',  'N' );
                my $set_console_mode = Win32::API->new( 'kernel32', 'SetConsoleMode',     'NN', 'N' );
                my $set_console_cp   = Win32::API->new( 'kernel32', 'SetConsoleOutputCP', 'N',  'N' );
                my $hout             = $get_std_handle->Call(-11);

                # ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT
                $set_console_mode->Call( $hout, 0x0004 | 0x0001 );
                $set_console_cp->Call(65001);
            };
        }
        $_stdout_raw_set = 1;
    }

    sub _encode_utf8 {
        require Encode;
        return Encode::encode_utf8( $_[0] );
    }

    sub Print {
        my @args = @_;
        my $str  = _downsample_str(@args);
        _ensure_raw_stdout();
        print _encode_utf8($str);
        return length($str);
    }

    sub Println {
        my @args = @_;
        my $str  = _downsample_str(@args);
        _ensure_raw_stdout();
        print _encode_utf8( $str . "\n" );
        return length($str) + 1;
    }

    sub Printf {
        my ( $fmt, @args ) = @_;
        my $str = sprintf $fmt, @args;
        $str = _downsample($str);
        print $str;
        return length($str);
    }

    sub Fprint {
        my ( $fh, @args ) = @_;
        my $str = _downsample_str(@args);
        print $fh $str;
        return length($str);
    }

    sub Fprintln {
        my ( $fh, @args ) = @_;
        my $str = _downsample_str(@args);
        print $fh $str, "\n";
        return length($str) + 1;
    }

    sub Fprintf {
        my ( $fh, $fmt, @args ) = @_;
        my $str = sprintf $fmt, @args;
        $str = _downsample($str);
        print $fh $str;
        return length($str);
    }

    sub Sprint {
        my @args = @_;
        return _downsample_str(@args);
    }

    sub Sprintln {
        my @args = @_;
        return _downsample_str(@args) . "\n";
    }

    sub Sprintf {
        my ( $fmt, @args ) = @_;
        my $str = sprintf $fmt, @args;
        return _downsample($str);
    }

    # ---- Blending (delegated to Cancer::Color::Blend) --------------------------------------
    *blend_1d = \&Cancer::Color::Blend::blend_1d;
    *blend_2d = \&Cancer::Color::Blend::blend_2d;

    # ---- Terminal queries ----------------------------------------------------------------------------------------------
    sub query_terminal_bg {
        my ( $in_fh, $out_fh ) = @_;

        # Use Perl's alarm + eval for timeout
        my $bg;
        my $old_alarm = $SIG{ALRM};
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(2);
            print $out_fh request_background_color();

            # Read response - simplified for now
            my $buf = '';
            my $n   = sysread( $in_fh, $buf, 256 );
            alarm(0);
            if ( $buf =~ /\e\]11;([^\e]*)\e\\/ ) {
                my $color_str = $1;
                my @parts     = split /;/, $color_str;
                if ( @parts >= 2 ) {
                    $bg = Cancer::Ansi::x_parse_color( $parts[1] );
                }
            }
        };
        alarm(0);
        $SIG{ALRM} = $old_alarm if defined $old_alarm;
        return $bg;
    }

    sub has_dark_background {
        my ( $in_fh, $out_fh ) = @_;
        my $bg = query_terminal_bg( $in_fh, $out_fh );
        return 1 unless $bg;
        my $blend_color = Cancer::Color::Blend::blend_from_color( { r => $bg->[0], g => $bg->[1], b => $bg->[2] } );
        return is_dark_color($blend_color);
    }
}
1;
