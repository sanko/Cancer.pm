use v5.42;

package Cancer::CellBuf::Wrap v0.0.1 {
    use Exporter qw[import];
    use Encode;
    our @EXPORT_OK = qw[wrap_text _read_style _read_link];
    use Cancer::Ansi::Parser qw[
        new_parser parser_reset DecodeSequence HasCsiPrefix HasOscPrefix
        param command params data MissingParam ParamVal HasMore
        _read_style_color
    ];
    use Cancer::Ansi qw[ResetStyle set_hyperlink reset_hyperlink];
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;
    use utf8;
    my $NBSP = 0x00A0;

    sub _is_space ($r) {
        return 0 if $r == $NBSP;
        return ( chr($r) =~ /^\s/ ) ? 1 : 0;
    }

    sub _read_style ( $params, $style ) {
        return $style->reset unless @$params;
        my $i = 0;
        while ( $i <= $#$params ) {
            my ( $val, $has_more ) = param( { params => $params, paramsLen => scalar @$params }, $i, 0 );
            if ( $val == 0 ) {
                $style->reset;
            }
            elsif ( $val == 1 ) { $style->set_bold(1) }
            elsif ( $val == 2 ) { $style->set_faint(1) }
            elsif ( $val == 3 ) { $style->set_italic(1) }
            elsif ( $val == 4 ) {
                if ( $has_more && $i + 1 <= $#$params ) {
                    my ( $sub_val, $sub_more ) = param( { params => $params, paramsLen => scalar @$params }, $i + 1, 0 );
                    if ( !$sub_more ) {
                        $style->set_underline(1);
                    }
                    else {
                        $i++;
                        if    ( $sub_val == 0 ) { $style->set_underline_style(Cancer::CellBuf::Style::NO_UNDERLINE) }
                        elsif ( $sub_val == 1 ) { $style->set_underline_style(Cancer::CellBuf::Style::SINGLE_UNDERLINE) }
                        elsif ( $sub_val == 2 ) { $style->set_underline_style(Cancer::CellBuf::Style::DOUBLE_UNDERLINE) }
                        elsif ( $sub_val == 3 ) { $style->set_underline_style(Cancer::CellBuf::Style::CURLY_UNDERLINE) }
                        elsif ( $sub_val == 4 ) { $style->set_underline_style(Cancer::CellBuf::Style::DOTTED_UNDERLINE) }
                        elsif ( $sub_val == 5 ) { $style->set_underline_style(Cancer::CellBuf::Style::DASHED_UNDERLINE) }
                    }
                }
                else {
                    $style->set_underline(1);
                }
            }
            elsif ( $val == 5 )  { $style->set_slow_blink(1) }
            elsif ( $val == 6 )  { $style->set_rapid_blink(1) }
            elsif ( $val == 7 )  { $style->set_reverse(1) }
            elsif ( $val == 8 )  { $style->set_conceal(1) }
            elsif ( $val == 9 )  { $style->set_strikethrough(1) }
            elsif ( $val == 22 ) { $style->set_bold(0); $style->set_faint(0) }
            elsif ( $val == 23 ) { $style->set_italic(0) }
            elsif ( $val == 24 ) { $style->set_underline(0) }
            elsif ( $val == 25 ) { $style->set_slow_blink(0); $style->set_rapid_blink(0) }
            elsif ( $val == 27 ) { $style->set_reverse(0) }
            elsif ( $val == 28 ) { $style->set_conceal(0) }
            elsif ( $val == 29 ) { $style->set_strikethrough(0) }
            elsif ( $val == 30 ) { $style->set_fg( { type => 'basic', code => 0 } ) }
            elsif ( $val == 31 ) { $style->set_fg( { type => 'basic', code => 1 } ) }
            elsif ( $val == 32 ) { $style->set_fg( { type => 'basic', code => 2 } ) }
            elsif ( $val == 33 ) { $style->set_fg( { type => 'basic', code => 3 } ) }
            elsif ( $val == 34 ) { $style->set_fg( { type => 'basic', code => 4 } ) }
            elsif ( $val == 35 ) { $style->set_fg( { type => 'basic', code => 5 } ) }
            elsif ( $val == 36 ) { $style->set_fg( { type => 'basic', code => 6 } ) }
            elsif ( $val == 37 ) { $style->set_fg( { type => 'basic', code => 7 } ) }
            elsif ( $val == 38 ) {
                my ( $c, $n ) = _read_style_color( [ @{$params}[ $i .. $#$params ] ] );
                $style->set_fg($c) if defined $c;
                $i += $n - 1       if $n > 0;
            }
            elsif ( $val == 39 ) { $style->set_fg(undef) }
            elsif ( $val == 40 ) { $style->set_bg( { type => 'basic', code => 0 } ) }
            elsif ( $val == 41 ) { $style->set_bg( { type => 'basic', code => 1 } ) }
            elsif ( $val == 42 ) { $style->set_bg( { type => 'basic', code => 2 } ) }
            elsif ( $val == 43 ) { $style->set_bg( { type => 'basic', code => 3 } ) }
            elsif ( $val == 44 ) { $style->set_bg( { type => 'basic', code => 4 } ) }
            elsif ( $val == 45 ) { $style->set_bg( { type => 'basic', code => 5 } ) }
            elsif ( $val == 46 ) { $style->set_bg( { type => 'basic', code => 6 } ) }
            elsif ( $val == 47 ) { $style->set_bg( { type => 'basic', code => 7 } ) }
            elsif ( $val == 48 ) {
                my ( $c, $n ) = _read_style_color( [ @{$params}[ $i .. $#$params ] ] );
                $style->set_bg($c) if defined $c;
                $i += $n - 1       if $n > 0;
            }
            elsif ( $val == 49 ) { $style->set_bg(undef) }
            elsif ( $val == 58 ) {
                my ( $c, $n ) = _read_style_color( [ @{$params}[ $i .. $#$params ] ] );
                $style->set_ul($c) if defined $c;
                $i += $n - 1       if $n > 0;
            }
            elsif ( $val == 59 )  { $style->set_ul(undef) }
            elsif ( $val == 90 )  { $style->set_fg( { type => 'basic', code => 8 } ) }
            elsif ( $val == 91 )  { $style->set_fg( { type => 'basic', code => 9 } ) }
            elsif ( $val == 92 )  { $style->set_fg( { type => 'basic', code => 10 } ) }
            elsif ( $val == 93 )  { $style->set_fg( { type => 'basic', code => 11 } ) }
            elsif ( $val == 94 )  { $style->set_fg( { type => 'basic', code => 12 } ) }
            elsif ( $val == 95 )  { $style->set_fg( { type => 'basic', code => 13 } ) }
            elsif ( $val == 96 )  { $style->set_fg( { type => 'basic', code => 14 } ) }
            elsif ( $val == 97 )  { $style->set_fg( { type => 'basic', code => 15 } ) }
            elsif ( $val == 100 ) { $style->set_bg( { type => 'basic', code => 8 } ) }
            elsif ( $val == 101 ) { $style->set_bg( { type => 'basic', code => 9 } ) }
            elsif ( $val == 102 ) { $style->set_bg( { type => 'basic', code => 10 } ) }
            elsif ( $val == 103 ) { $style->set_bg( { type => 'basic', code => 11 } ) }
            elsif ( $val == 104 ) { $style->set_bg( { type => 'basic', code => 12 } ) }
            elsif ( $val == 105 ) { $style->set_bg( { type => 'basic', code => 13 } ) }
            elsif ( $val == 106 ) { $style->set_bg( { type => 'basic', code => 14 } ) }
            elsif ( $val == 107 ) { $style->set_bg( { type => 'basic', code => 15 } ) }
            $i++;
        }
        return $style;
    }

    sub _read_link ( $data, $link ) {
        my @parts = split /;/, $data, 3;
        return $link unless @parts == 3;
        $link->set_params( $parts[1] );
        $link->set_url( $parts[2] );
        return $link;
    }

    sub wrap_text ( $str, $limit, $breakpoints = '' ) {
        return '' unless defined $str && length $str;
        return $str if $limit < 1;

        # DecodeSequence expects raw bytes; ensure we have them
        my $was_utf8 = utf8::is_utf8($str);
        $str = Encode::encode( 'UTF-8', $str ) if $was_utf8;
        my $p = new_parser();
        my ( $buf, $word, $space )   = ( '', '', '' );
        my ( $style, $cur_style )    = ( Cancer::CellBuf::Style->new, Cancer::CellBuf::Style->new );
        my ( $link, $cur_link )      = ( Cancer::CellBuf::Link->new, Cancer::CellBuf::Link->new );
        my ( $cur_width, $word_len ) = ( 0, 0 );
        my $state           = 0;
        my $has_blank_style = sub {
            return !$style->contains( Cancer::CellBuf::Style::REVERSE_ATTR() ) &&
                !defined $style->bg &&
                $style->ul_style == Cancer::CellBuf::Style::NO_UNDERLINE();
        };
        my $add_space = sub {
            $cur_width += length($space);
            $buf .= $space;
            $space = '';
        };
        my $add_word = sub {
            return unless length $word;
            $cur_link  = $link->clone;
            $cur_style = $style->clone;
            $add_space->();
            $cur_width += $word_len;
            $buf .= $word;
            $word     = '';
            $word_len = 0;
        };
        my $add_newline = sub {
            if ( !$cur_style->empty ) {
                $buf .= ResetStyle();
            }
            if ( !$cur_link->empty ) {
                $buf .= reset_hyperlink();
            }
            $buf .= "\n";
            if ( !$cur_link->empty ) {
                $buf .= set_hyperlink( $cur_link->url, $cur_link->params );
            }
            if ( !$cur_style->empty ) {
                $buf .= $cur_style->sequence;
            }
            $cur_width = 0;
            $space     = '';
        };
        my $bps = [ split //, $breakpoints ];

        # Offset-based walk: passing $pos into DecodeSequence avoids the
        # quadratic substr-chop loop (each chop copies the whole remainder).
        my $slen = length $str;
        my $pos  = 0;
        while ( $pos < $slen ) {
            my ( $seq, $width, $n, $new_state ) = DecodeSequence( $str, $state, $p, $pos );
            $pos += $n;
            $state = $new_state;
            if ( $width == 0 ) {
                if ( $seq eq "\t" ) {
                    $add_word->();
                    $space .= $seq;
                }
                elsif ( $seq eq "\n" ) {
                    if ( $word_len == 0 ) {
                        if ( $cur_width + length($space) > $limit ) {
                            $cur_width = 0;
                        }
                        else {
                            $buf .= $space;
                        }
                        $space = '';
                    }
                    $add_word->();
                    $add_newline->();
                }
                elsif ( HasCsiPrefix($seq) && command($p) == ord('m') ) {
                    _read_style( [ params($p) ], $style );
                    $word .= $seq;
                }
                elsif ( HasOscPrefix($seq) && command($p) == 8 ) {
                    _read_link( data($p), $link );
                    $word .= $seq;
                }
                else {
                    $word .= $seq;
                }
            }
            else {
                my $r = ord($seq);
                if ( length($seq) == 1 && _is_space($r) && $has_blank_style->() ) {
                    $add_word->();
                    $space .= $seq;
                }
                elsif ( length($seq) == 1 && ( $r == ord('-') || grep { $_ eq $seq } @$bps ) ) {
                    $add_space->();
                    if ( $cur_width + $word_len + $width <= $limit ) {
                        $add_word->();
                        $buf .= $seq;
                        $cur_width += $width;
                    }
                    else {
                        if ( $word_len + $width > $limit ) {
                            $add_word->();
                        }
                        $word .= $seq;
                        $word_len += $width;
                        if ( $cur_width + $word_len + length($space) > $limit ) {
                            $add_newline->();
                        }
                    }
                }
                else {
                    if ( $word_len + $width > $limit ) {
                        $add_word->();
                    }
                    $word .= $seq;
                    $word_len += $width;
                    if ( $cur_width + $word_len + length($space) > $limit ) {
                        $add_newline->();
                    }
                }
            }
        }
        if ( $word_len == 0 ) {
            if ( $cur_width + length($space) > $limit ) {
                $cur_width = 0;
            }
            else {
                $buf .= $space;
            }
            $space = '';
        }
        $add_word->();
        if ( !$cur_link->empty ) {
            $buf .= reset_hyperlink();
        }
        if ( !$cur_style->empty ) {
            $buf .= ResetStyle();
        }
        $buf = Encode::decode( 'UTF-8', $buf ) if $was_utf8;
        return $buf;
    }
}
#
1;
