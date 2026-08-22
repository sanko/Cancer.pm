use v5.42;

package Cancer::CellBuf::Writer v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[fill_rect fill clear_rect clear set_content_rect set_content render render_line];
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;
    use Cancer::CellBuf::Geom qw[Rect];
    use Cancer::Ansi          qw[ResetStyle set_hyperlink reset_hyperlink];

    sub fill_rect ( $buf, $cell, $rect ) {
        for my $y ( $rect->min_y .. $rect->max_y - 1 ) {
            for my $x ( $rect->min_x .. $rect->max_x - 1 ) {
                $buf->set_cell( $x, $y, $cell );
            }
        }
    }

    sub fill ( $buf, $cell ) {
        fill_rect( $buf, $cell, $buf->bounds );
    }

    sub clear_rect ( $buf, $rect ) {
        fill_rect( $buf, undef, $rect );
    }

    sub clear ($buf) {
        fill( $buf, undef );
    }

    sub set_content_rect ( $buf, $str, $rect ) {
        $str =~ s/\r\n/\n/g;
        $str =~ s/\n/\r\n/g;
        clear_rect( $buf, $rect );
        _print_string( $buf, undef, $rect->min_x, $rect->min_y, $rect, $str, 1, '' );
    }

    sub set_content ( $buf, $str ) {
        set_content_rect( $buf, $str, $buf->bounds );
    }

    sub render ($buf) {
        my $height = $buf->height;
        my $result = '';
        for my $y ( 0 .. $height - 1 ) {
            my ( $w, $line ) = render_line( $buf, $y );
            $result .= $line;
            $result .= "\r\n" if $y < $height - 1;
        }
        return $result;
    }

    sub render_line ( $buf, $n ) {
        my $pen           = Cancer::CellBuf::Style->new;
        my $link          = Cancer::CellBuf::Link->new;
        my $result        = '';
        my $width         = 0;
        my $pending_line  = '';
        my $pending_width = 0;
        my $write_pending = sub {
            return unless $pending_line ne '';
            $result .= $pending_line;
            $width += $pending_width;
            $pending_width = 0;
            $pending_line  = '';
        };
        my $bounds = $buf->bounds;
        for my $x ( $bounds->min_x .. $bounds->max_x - 1 ) {
            my $cell = $buf->cell( $x, $n );
            if ( defined $cell && $cell->width > 0 ) {
                my $cell_style = $cell->style;
                my $cell_link  = $cell->link;
                if ( $cell_style && $cell_style->empty && !$pen->empty ) {
                    $write_pending->();
                    $result .= ResetStyle();
                    $pen->reset;
                }
                if ( $cell_style && !$cell_style->equal($pen) ) {
                    $write_pending->();
                    my $seq = $cell_style->style_diff($pen);
                    $result .= $seq;
                    $pen = $cell_style->clone;
                }
                if ( $cell_link && !$cell_link->equal($link) ) {
                    $write_pending->();
                    if ( !$link->empty ) {
                        $result .= reset_hyperlink();
                    }
                    $result .= set_hyperlink( $cell_link->url, $cell_link->params );
                    $link = $cell_link->clone;
                }
                if ( $cell->equal( Cancer::CellBuf::Cell::BlankCell() ) ) {
                    $pending_line .= $cell->string;
                    $pending_width += $cell->width;
                }
                else {
                    $write_pending->();
                    $result .= $cell->string;
                    $width += $cell->width;
                }
            }
        }
        if ( !$link->empty ) {
            $result .= ResetHyperlink();
        }
        if ( !$pen->empty ) {
            $result .= ResetStyle();
        }

        # Trim trailing spaces
        $result =~ s/ +$//;
        return ( $width, $result );
    }

    sub _print_string ( $buf, $method, $x, $y, $bounds, $str, $truncate, $tail ) {
        my $cell  = Cancer::CellBuf::Cell->new;
        my $style = Cancer::CellBuf::Style->new;
        my $link  = Cancer::CellBuf::Link->new;
        my @chars = split //, $str;
        my $i     = 0;
        while ( $i <= $#chars ) {
            my $ch = $chars[$i];
            if ( $ch eq "\n" ) {
                if ( !$cell->empty ) {
                    $buf->set_cell( $x, $y, $cell ) if _pos_in_bounds( $x, $y, $bounds );
                    $cell = Cancer::CellBuf::Cell->new;
                }
                $y++;
                $x = $bounds->min_x;
                $i++;
                next;
            }
            if ( $ch eq "\r" ) {
                if ( !$cell->empty ) {
                    $buf->set_cell( $x, $y, $cell ) if _pos_in_bounds( $x, $y, $bounds );
                    $cell = Cancer::CellBuf::Cell->new;
                }
                $x = $bounds->min_x;
                $i++;
                next;
            }

            # Parse ANSI escape sequences
            if ( $ch eq "\e" && $i + 1 <= $#chars && $chars[ $i + 1 ] eq '[' ) {
                my $j = $i + 2;
                my @params;
                my $num     = 0;
                my $has_num = 0;
                while ( $j <= $#chars ) {
                    my $c = $chars[$j];
                    if ( $c ge '0' && $c le '9' ) {
                        $num     = $num * 10 + ord($c) - 48;
                        $has_num = 1;
                        $j++;
                    }
                    elsif ( $c eq ';' ) {
                        push @params, $has_num ? $num : 0;
                        $num     = 0;
                        $has_num = 0;
                        $j++;
                    }
                    elsif ( $c eq 'm' ) {
                        push @params, $has_num ? $num : 0 if $has_num || !@params;
                        $j++;
                        _apply_sgr( $style, \@params );
                        last;
                    }
                    else {
                        # Unknown CSI sequence, skip to end
                        $j++ while $j <= $#chars && $chars[$j] =~ /[A-Z\\]/i;
                        $j++;
                        last;
                    }
                }
                $i = $j;
                next;
            }

            # Hyperlink ESC]8;;url\e\\
            if ( $ch eq "\e" && $i + 1 <= $#chars && $chars[ $i + 1 ] eq ']' ) {
                if ( $i + 3 <= $#chars && $chars[ $i + 2 ] eq '8' && $chars[ $i + 3 ] eq ';' ) {

                    # Skip to BEL or ST
                    my $j   = $i + 5;
                    my $url = '';
                    while ( $j <= $#chars ) {
                        if ( $chars[$j] eq "\a" ) {
                            $link->set_url($url);
                            $j++;
                            last;
                        }
                        if ( $chars[$j] eq "\e" && $j + 1 <= $#chars && $chars[ $j + 1 ] eq '\\' ) {
                            $link->set_url($url);
                            $j += 2;
                            last;
                        }
                        $url .= $chars[$j];
                        $j++;
                    }
                    $i = $j;
                    next;
                }

                # Other ESC sequences, skip
                my $j = $i + 2;
                $j++ while $j <= $#chars && $chars[$j] ne '\\' && $chars[$j] ne "\a";
                $j++;
                $i = $j;
                next;
            }

            # Build grapheme cluster
            my $grapheme = $ch;
            $i++;
            while ( $i <= $#chars ) {
                my $next_ord = ord( $chars[$i] );
                if ( ( $next_ord >= 0x0300 && $next_ord <= 0x036F ) ||
                    ( $next_ord >= 0x1DC0 && $next_ord <= 0x1DFF ) ||
                    ( $next_ord >= 0x20D0 && $next_ord <= 0x20FF ) ||
                    ( $next_ord >= 0xFE20 && $next_ord <= 0xFE2F ) ) {
                    $grapheme .= $chars[$i];
                    $i++;
                }
                else {
                    last;
                }
            }
            my $width = _char_width( ord($ch) );
            if ( $cell->width + $width > 0 ) {
                if ( !$truncate && $x + $cell->width + $width > $bounds->max_x && $y + 1 < $bounds->max_y ) {
                    $x = $bounds->min_x;
                    $y++;
                }
                if ( _pos_in_bounds( $x, $y, $bounds ) ) {
                    $cell->append( map {ord} split //, $grapheme );
                    $cell->set_width($width);
                    $cell->set_style( $style->clone );
                    $cell->set_link( $link->clone );
                    $buf->set_cell( $x, $y, $cell );
                    $x += $width;
                }
                $cell = Cancer::CellBuf::Cell->new;
            }
        }
        if ( !$cell->empty ) {
            $buf->set_cell( $x, $y, $cell ) if _pos_in_bounds( $x, $y, $bounds );
        }
    }

    sub _apply_sgr ( $style, $params ) {
        my @p = @$params;
        return if !@p;
        my $i = 0;
        while ( $i <= $#p ) {
            my $c = $p[$i];
            if ( $c == 0 ) {
                $style->reset;
            }
            elsif ( $c == 1 ) { $style->set_bold(1) }
            elsif ( $c == 2 ) { $style->set_faint(1) }
            elsif ( $c == 3 ) { $style->set_italic(1) }
            elsif ( $c == 4 ) {
                my $ul_param = $p[ $i + 1 ] // 1;
                if ( $ul_param >= 0 && $ul_param <= 5 ) {
                    $style->set_underline_style($ul_param);
                    $i++;
                }
                else {
                    $style->set_underline(1);
                }
            }
            elsif ( $c == 5 )  { $style->set_slow_blink(1) }
            elsif ( $c == 6 )  { $style->set_rapid_blink(1) }
            elsif ( $c == 7 )  { $style->set_reverse(1) }
            elsif ( $c == 8 )  { $style->set_conceal(1) }
            elsif ( $c == 9 )  { $style->set_strikethrough(1) }
            elsif ( $c == 21 ) { $style->set_bold(0); $style->set_faint(0) }
            elsif ( $c == 22 ) { $style->set_bold(0); $style->set_faint(0) }
            elsif ( $c == 23 ) { $style->set_italic(0) }
            elsif ( $c == 24 ) { $style->set_underline_style(0) }
            elsif ( $c == 25 ) { $style->set_slow_blink(0); $style->set_rapid_blink(0) }
            elsif ( $c == 27 ) { $style->set_reverse(0) }
            elsif ( $c == 28 ) { $style->set_conceal(0) }
            elsif ( $c == 29 ) { $style->set_strikethrough(0) }
            elsif ( $c == 39 ) { $style->set_fg(undef) }
            elsif ( $c == 49 ) { $style->set_bg(undef) }
            elsif ( $c == 59 ) { $style->set_ul(undef) }
            elsif ( $c == 38 ) {
                my ( $fg, $consumed ) = _parse_color( \@p, $i + 1 );
                $style->set_fg($fg) if defined $fg;
                $i += $consumed;
            }
            elsif ( $c == 48 ) {
                my ( $bg, $consumed ) = _parse_color( \@p, $i + 1 );
                $style->set_bg($bg) if defined $bg;
                $i += $consumed;
            }
            elsif ( $c == 58 ) {
                my ( $ul, $consumed ) = _parse_color( \@p, $i + 1 );
                $style->set_ul($ul) if defined $ul;
                $i += $consumed;
            }
            elsif ( $c >= 30 && $c <= 37 ) {
                $style->set_fg( { type => 'basic', code => $c - 30 } );
            }
            elsif ( $c >= 40 && $c <= 47 ) {
                $style->set_bg( { type => 'basic', code => $c - 40 } );
            }
            elsif ( $c >= 90 && $c <= 97 ) {
                $style->set_fg( { type => 'basic', code => $c - 82 } );
            }
            elsif ( $c >= 100 && $c <= 107 ) {
                $style->set_bg( { type => 'basic', code => $c - 92 } );
            }
            $i++;
        }
    }

    sub _parse_color ( $params, $start ) {
        return ( undef, 0 ) if $start > $#$params;
        my $type = $params->[$start];
        if ( $type == 5 && $start + 1 <= $#$params ) {
            return ( { type => '256', index => $params->[ $start + 1 ] }, 2 );
        }
        elsif ( $type == 2 && $start + 3 <= $#$params ) {
            return ( { type => 'rgb', r => $params->[ $start + 1 ], g => $params->[ $start + 2 ], b => $params->[ $start + 3 ] }, 4 );
        }
        return ( undef, 1 );
    }

    sub _pos_in_bounds ( $x, $y, $bounds ) {
        $x >= $bounds->min_x && $x < $bounds->max_x && $y >= $bounds->min_y && $y < $bounds->max_y;
    }

    sub _char_width ($ord) {

        # Simple width detection
        if    ( $ord >= 0x1100 && $ord <= 0x115F )                                     { return 2 }
        elsif ( $ord >= 0x2E80 && $ord <= 0xA4CF && $ord != 0x303F )                   { return 2 }
        elsif ( $ord >= 0xAC00 && $ord <= 0xD7A3 )                                     { return 2 }
        elsif ( $ord >= 0xF900 && $ord <= 0xFAFF )                                     { return 2 }
        elsif ( $ord >= 0xFE30 && $ord <= 0xFE4F )                                     { return 2 }
        elsif ( $ord >= 0xFF01 && $ord <= 0xFF60 )                                     { return 2 }
        elsif ( $ord >= 0xFFE0 && $ord <= 0xFFE6 )                                     { return 2 }
        elsif ( $ord >= 0x20000 && $ord <= 0x2FFFD )                                   { return 2 }
        elsif ( $ord >= 0x30000 && $ord <= 0x3FFFD )                                   { return 2 }
        elsif ( $ord == 0x200B || $ord == 0x200C || $ord == 0x200D || $ord == 0xFEFF ) { return 0 }
        else                                                                           { return 1 }
    }
}
#
1;
