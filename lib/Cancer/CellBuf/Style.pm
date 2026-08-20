use v5.42;
use experimental 'class';
class Cancer::CellBuf::Style v0.0.1 {
    use Cancer::Ansi qw[
        ResetStyle SGR UnderlineNone UnderlineSingle UnderlineDouble
        UnderlineCurly UnderlineDotted UnderlineDashed AttrBold AttrFaint
        AttrItalic AttrUnderline AttrNoBlink AttrBlink AttrRapidBlink
        AttrReverse AttrConceal AttrStrikethrough AttrNormalIntensity
        AttrNoItalic AttrNoUnderline AttrNoReverse AttrNoConceal
        AttrNoStrikethrough
    ];
    use constant {
        BOLD_ATTR          => 0x01,
        FAINT_ATTR         => 0x02,
        ITALIC_ATTR        => 0x04,
        SLOW_BLINK_ATTR    => 0x08,
        RAPID_BLINK_ATTR   => 0x10,
        REVERSE_ATTR       => 0x20,
        CONCEAL_ATTR       => 0x40,
        STRIKETHROUGH_ATTR => 0x80,
        RESET_ATTR         => 0x00
    };
    use constant {
        NO_UNDERLINE     => UnderlineNone(),
        SINGLE_UNDERLINE => UnderlineSingle(),
        DOUBLE_UNDERLINE => UnderlineDouble(),
        CURLY_UNDERLINE  => UnderlineCurly(),
        DOTTED_UNDERLINE => UnderlineDotted(),
        DASHED_UNDERLINE => UnderlineDashed()
    };
    field $fg       : param : reader //= undef;
    field $bg       : param : reader //= undef;
    field $ul       : param : reader //= undef;
    field $attrs    : param : reader = RESET_ATTR;
    field $ul_style : param : reader = NO_UNDERLINE;
    method set_fg              ($c) { $fg = $c; return $self }
    method set_bg              ($c) { $bg = $c; return $self }
    method set_ul              ($c) { $ul = $c; return $self }
    method set_bold            ($v) { $v ? ( $attrs |= BOLD_ATTR )          : ( $attrs &= ~BOLD_ATTR );          return $self }
    method set_faint           ($v) { $v ? ( $attrs |= FAINT_ATTR )         : ( $attrs &= ~FAINT_ATTR );         return $self }
    method set_italic          ($v) { $v ? ( $attrs |= ITALIC_ATTR )        : ( $attrs &= ~ITALIC_ATTR );        return $self }
    method set_slow_blink      ($v) { $v ? ( $attrs |= SLOW_BLINK_ATTR )    : ( $attrs &= ~SLOW_BLINK_ATTR );    return $self }
    method set_rapid_blink     ($v) { $v ? ( $attrs |= RAPID_BLINK_ATTR )   : ( $attrs &= ~RAPID_BLINK_ATTR );   return $self }
    method set_reverse         ($v) { $v ? ( $attrs |= REVERSE_ATTR )       : ( $attrs &= ~REVERSE_ATTR );       return $self }
    method set_conceal         ($v) { $v ? ( $attrs |= CONCEAL_ATTR )       : ( $attrs &= ~CONCEAL_ATTR );       return $self }
    method set_strikethrough   ($v) { $v ? ( $attrs |= STRIKETHROUGH_ATTR ) : ( $attrs &= ~STRIKETHROUGH_ATTR ); return $self }
    method set_underline_style ($s) { $ul_style = $s; return $self }

    method set_underline ($v) {
        $v ? $self->set_underline_style(SINGLE_UNDERLINE) : $self->set_underline_style(NO_UNDERLINE);
    }
    method contains ($attr) { ( $attrs & $attr ) == $attr }

    method empty () {
        !defined $fg && !defined $bg && !defined $ul && $attrs == RESET_ATTR && $ul_style == NO_UNDERLINE;
    }

    method clear () {
        $ul_style == NO_UNDERLINE                                                                            &&
            ( $attrs & ~( BOLD_ATTR | FAINT_ATTR | ITALIC_ATTR | SLOW_BLINK_ATTR | RAPID_BLINK_ATTR ) ) == 0 &&
            !defined $fg                                                                                     &&
            !defined $bg                                                                                     &&
            !defined $ul;
    }

    method reset () {
        $fg       = undef;
        $bg       = undef;
        $ul       = undef;
        $attrs    = RESET_ATTR;
        $ul_style = NO_UNDERLINE;
        return $self;
    }

    method sequence () {
        return ResetStyle() if $self->empty;
        my @codes;
        my $a = $attrs;
        push @codes, 1 if $a & BOLD_ATTR;
        push @codes, 2 if $a & FAINT_ATTR;
        push @codes, 3 if $a & ITALIC_ATTR;
        push @codes, 5 if $a & SLOW_BLINK_ATTR;
        push @codes, 6 if $a & RAPID_BLINK_ATTR;
        push @codes, 7 if $a & REVERSE_ATTR;
        push @codes, 8 if $a & CONCEAL_ATTR;
        push @codes, 9 if $a & STRIKETHROUGH_ATTR;

        if ( $ul_style != NO_UNDERLINE ) {
            push @codes, 4, $ul_style;
        }
        if ( defined $fg ) {
            push @codes, _color_codes( 38, $fg );
        }
        if ( defined $bg ) {
            push @codes, _color_codes( 48, $bg );
        }
        if ( defined $ul ) {
            push @codes, _color_codes( 58, $ul );
        }
        return ResetStyle() unless @codes;
        return SGR(@codes);
    }

    method diff_sequence ($old) {
        return $self->sequence if $old->empty;
        my @codes;
        if ( !_color_eq( $fg, $old->fg ) ) {
            push @codes, _color_codes( 38, $fg ) if defined $fg;
            push @codes, 39                      if !defined $fg;
        }
        if ( !_color_eq( $bg, $old->bg ) ) {
            push @codes, _color_codes( 48, $bg ) if defined $bg;
            push @codes, 49                      if !defined $bg;
        }
        if ( !_color_eq( $ul, $old->ul ) ) {
            push @codes, _color_codes( 58, $ul ) if defined $ul;
            push @codes, 59                      if !defined $ul;
        }
        my ( $no_blink, $is_normal );
        my $sa = $attrs;
        my $oa = $old->attrs;
        if ( $sa != $oa ) {
            for my $check (
                [   BOLD_ATTR,        sub { push @codes, 1 }, FAINT_ATTR,         sub { push @codes, 2 },
                    ITALIC_ATTR,      sub { push @codes, 3 }, SLOW_BLINK_ATTR,    sub { push @codes, 5 },
                    RAPID_BLINK_ATTR, sub { push @codes, 6 }, REVERSE_ATTR,       sub { push @codes, 7 },
                    CONCEAL_ATTR,     sub { push @codes, 8 }, STRIKETHROUGH_ATTR, sub { push @codes, 9 }
                ]
            ) {
                my ( $attr, $set ) = @$check;
                if ( ( $sa & $attr ) != ( $oa & $attr ) ) {
                    if ( $sa & $attr ) {
                        $set->();
                    }
                    elsif ( !$is_normal && ( $attr == BOLD_ATTR || $attr == FAINT_ATTR ) ) {
                        $is_normal = 1;
                        push @codes, 22;
                    }
                    elsif ( !$no_blink && ( $attr == SLOW_BLINK_ATTR || $attr == RAPID_BLINK_ATTR ) ) {
                        $no_blink = 1;
                        push @codes, 25;
                    }
                }
            }
        }
        if ( $ul_style != $old->ul_style ) {
            push @codes, 4, $ul_style;
        }
        return ResetStyle() unless @codes;
        return SGR(@codes);
    }

    method equal ($other) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $attrs == $other->attrs           &&
            $ul_style == $other->ul_style &&
            _color_eq( $fg, $other->fg )  &&
            _color_eq( $bg, $other->bg )  &&
            _color_eq( $ul, $other->ul );
    }

    method clone () {
        my $c_fg = defined $fg ? {%$fg} : undef;
        my $c_bg = defined $bg ? {%$bg} : undef;
        my $c_ul = defined $ul ? {%$ul} : undef;
        return __PACKAGE__->new( fg => $c_fg, bg => $c_bg, ul => $c_ul, attrs => $attrs, ul_style => $ul_style );
    }
    my %BASIC_FG = (
        0  => 30,
        1  => 31,
        2  => 32,
        3  => 33,
        4  => 34,
        5  => 35,
        6  => 36,
        7  => 37,
        8  => 90,
        9  => 91,
        10 => 92,
        11 => 93,
        12 => 94,
        13 => 95,
        14 => 96,
        15 => 97
    );
    my %BASIC_BG = (
        0  => 40,
        1  => 41,
        2  => 42,
        3  => 43,
        4  => 44,
        5  => 45,
        6  => 46,
        7  => 47,
        8  => 100,
        9  => 101,
        10 => 102,
        11 => 103,
        12 => 104,
        13 => 105,
        14 => 106,
        15 => 107
    );
    my %BASIC_UL = ( 0 => 58, 1 => 59 );

    sub _color_eq ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        return 0 unless ref $a eq 'HASH' && ref $b eq 'HASH';
        $a->{type} eq $b->{type} &&
            ( $a->{type} ne 'rgb' || ( $a->{r} == $b->{r} && $a->{g} == $b->{g} && $a->{b} == $b->{b} ) ) &&
            ( $a->{type} ne '256' || $a->{index} == $b->{index} ) &&
            ( $a->{type} ne 'basic' || $a->{code} == $b->{code} );
    }

    sub _color_codes ( $prefix, $c ) {
        return () unless defined $c;
        if ( $c->{type} eq 'basic' ) {
            if ( $prefix == 38 ) {
                return ( $BASIC_FG{ $c->{code} } // 39 );
            }
            elsif ( $prefix == 48 ) {
                return ( $BASIC_BG{ $c->{code} } // 49 );
            }
            return ( $prefix, $c->{code} );
        }
        elsif ( $c->{type} eq '256' ) {
            return ( $prefix, 5, $c->{index} );
        }
        elsif ( $c->{type} eq 'rgb' ) {
            return ( $prefix, 2, $c->{r}, $c->{g}, $c->{b} );
        }
        return ();
    }
} 1;
