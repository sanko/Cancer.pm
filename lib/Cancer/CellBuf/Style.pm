use v5.42;

package Cancer::CellBuf::Style v0.0.1 {
    use Exporter     qw[import];
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

    sub new ( $class, %args ) {
        bless {
            fg       => $args{fg}       // undef,
            bg       => $args{bg}       // undef,
            ul       => $args{ul}       // undef,
            attrs    => $args{attrs}    // RESET_ATTR,
            ul_style => $args{ul_style} // NO_UNDERLINE
        }, $class;
    }
    sub fg                ($self)       { $self->{fg} }
    sub bg                ($self)       { $self->{bg} }
    sub ul                ($self)       { $self->{ul} }
    sub attrs             ($self)       { $self->{attrs} }
    sub ul_style          ($self)       { $self->{ul_style} }
    sub set_fg            ( $self, $c ) { $self->{fg} = $c; $self }
    sub set_bg            ( $self, $c ) { $self->{bg} = $c; $self }
    sub set_ul            ( $self, $c ) { $self->{ul} = $c; $self }
    sub set_bold          ( $self, $v ) { $v ? ( $self->{attrs} |= BOLD_ATTR )          : ( $self->{attrs} &= ~BOLD_ATTR );          $self }
    sub set_faint         ( $self, $v ) { $v ? ( $self->{attrs} |= FAINT_ATTR )         : ( $self->{attrs} &= ~FAINT_ATTR );         $self }
    sub set_italic        ( $self, $v ) { $v ? ( $self->{attrs} |= ITALIC_ATTR )        : ( $self->{attrs} &= ~ITALIC_ATTR );        $self }
    sub set_slow_blink    ( $self, $v ) { $v ? ( $self->{attrs} |= SLOW_BLINK_ATTR )    : ( $self->{attrs} &= ~SLOW_BLINK_ATTR );    $self }
    sub set_rapid_blink   ( $self, $v ) { $v ? ( $self->{attrs} |= RAPID_BLINK_ATTR )   : ( $self->{attrs} &= ~RAPID_BLINK_ATTR );   $self }
    sub set_reverse       ( $self, $v ) { $v ? ( $self->{attrs} |= REVERSE_ATTR )       : ( $self->{attrs} &= ~REVERSE_ATTR );       $self }
    sub set_conceal       ( $self, $v ) { $v ? ( $self->{attrs} |= CONCEAL_ATTR )       : ( $self->{attrs} &= ~CONCEAL_ATTR );       $self }
    sub set_strikethrough ( $self, $v ) { $v ? ( $self->{attrs} |= STRIKETHROUGH_ATTR ) : ( $self->{attrs} &= ~STRIKETHROUGH_ATTR ); $self }
    sub set_underline_style( $self, $s ) { $self->{ul_style} = $s; $self }

    sub set_underline ( $self, $v ) {
        $v ? $self->set_underline_style(SINGLE_UNDERLINE) : $self->set_underline_style(NO_UNDERLINE);
    }
    sub contains ( $self, $attr ) { ( $self->{attrs} & $attr ) == $attr }

    sub empty ($self) {
        !defined $self->{fg} && !defined $self->{bg} && !defined $self->{ul} && $self->{attrs} == RESET_ATTR && $self->{ul_style} == NO_UNDERLINE;
    }

    sub clear ($self) {
        $self->{ul_style} == NO_UNDERLINE                                                                            &&
            ( $self->{attrs} & ~( BOLD_ATTR | FAINT_ATTR | ITALIC_ATTR | SLOW_BLINK_ATTR | RAPID_BLINK_ATTR ) ) == 0 &&
            !defined $self->{fg}                                                                                     &&
            !defined $self->{bg}                                                                                     &&
            !defined $self->{ul};
    }

    sub reset ($self) {
        $self->{fg}       = undef;
        $self->{bg}       = undef;
        $self->{ul}       = undef;
        $self->{attrs}    = RESET_ATTR;
        $self->{ul_style} = NO_UNDERLINE;
        $self;
    }

    sub sequence ($self) {
        return ResetStyle() if $self->empty;
        my @codes;
        my $a = $self->{attrs};
        push @codes, 1 if $a & BOLD_ATTR;
        push @codes, 2 if $a & FAINT_ATTR;
        push @codes, 3 if $a & ITALIC_ATTR;
        push @codes, 5 if $a & SLOW_BLINK_ATTR;
        push @codes, 6 if $a & RAPID_BLINK_ATTR;
        push @codes, 7 if $a & REVERSE_ATTR;
        push @codes, 8 if $a & CONCEAL_ATTR;
        push @codes, 9 if $a & STRIKETHROUGH_ATTR;

        if ( $self->{ul_style} != NO_UNDERLINE ) {
            push @codes, 4, $self->{ul_style};
        }
        if ( defined $self->{fg} ) {
            push @codes, _color_codes( 38, $self->{fg} );
        }
        if ( defined $self->{bg} ) {
            push @codes, _color_codes( 48, $self->{bg} );
        }
        if ( defined $self->{ul} ) {
            push @codes, _color_codes( 58, $self->{ul} );
        }
        return ResetStyle() unless @codes;
        return SGR(@codes);
    }

    sub diff_sequence ( $self, $old ) {
        return $self->sequence if $old->empty;
        my @codes;
        if ( !_color_eq( $self->{fg}, $old->{fg} ) ) {
            push @codes, _color_codes( 38, $self->{fg} ) if defined $self->{fg};
            push @codes, 39                              if !defined $self->{fg};
        }
        if ( !_color_eq( $self->{bg}, $old->{bg} ) ) {
            push @codes, _color_codes( 48, $self->{bg} ) if defined $self->{bg};
            push @codes, 49                              if !defined $self->{bg};
        }
        if ( !_color_eq( $self->{ul}, $old->{ul} ) ) {
            push @codes, _color_codes( 58, $self->{ul} ) if defined $self->{ul};
            push @codes, 59                              if !defined $self->{ul};
        }
        my ( $no_blink, $is_normal );
        my $sa = $self->{attrs};
        my $oa = $old->{attrs};
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
                        push @codes, 22;    # Normal intensity
                    }
                    elsif ( !$no_blink && ( $attr == SLOW_BLINK_ATTR || $attr == RAPID_BLINK_ATTR ) ) {
                        $no_blink = 1;
                        push @codes, 25;    # Blink off
                    }
                }
            }
        }
        if ( $self->{ul_style} != $old->{ul_style} ) {
            push @codes, 4, $self->{ul_style};
        }
        return ResetStyle() unless @codes;
        return SGR(@codes);
    }

    sub equal ( $self, $other ) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $self->{attrs} == $other->{attrs}           &&
            $self->{ul_style} == $other->{ul_style} &&
            _color_eq( $self->{fg}, $other->{fg} )  &&
            _color_eq( $self->{bg}, $other->{bg} )  &&
            _color_eq( $self->{ul}, $other->{ul} );
    }

    sub _color_eq ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        return 0 unless ref $a eq 'HASH' && ref $b eq 'HASH';
        $a->{type} eq $b->{type} &&
            ( $a->{type} ne 'rgb' || ( $a->{r} == $b->{r} && $a->{g} == $b->{g} && $a->{b} == $b->{b} ) ) &&
            ( $a->{type} ne '256' || $a->{index} == $b->{index} ) &&
            ( $a->{type} ne 'basic' || $a->{code} == $b->{code} );
    }

    # Maps (prefix_type, basic_color_code) to the correct SGR code.
    # prefix_type: 38=fg, 48=bg, 58=underline
    # basic_color_code: 0-7 (black..white), 8-15 (bright variants)
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
    my %BASIC_UL = ( 0 => 58, 1 => 59 );    # underline color has no basic preset, fall through

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

    sub clone ($self) {
        my $clone = {%$self};

        # Deep copy colors
        for my $k (qw[fg bg ul]) {
            $clone->{$k} = { %{ $clone->{$k} } } if defined $clone->{$k};
        }
        bless $clone, ref $self;
    }
}
1;
