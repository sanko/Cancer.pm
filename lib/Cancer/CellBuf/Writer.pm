use v5.42;

package Cancer::CellBuf::Writer v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[fill_rect fill clear_rect clear set_content_rect set_content render render_line];
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Geom qw[Rect];
    use Cancer::Ansi          qw[ResetStyle set_hyperlink reset_hyperlink];

    sub fill_rect ( $buf, $cell, $rect ) {
        for my $y ( $rect->{min}{y} .. $rect->{max}{y} - 1 ) {
            for my $x ( $rect->{min}{x} .. $rect->{max}{x} - 1 ) {
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
        _print_string( $buf, undef, $rect->{min}{x}, $rect->{min}{y}, $rect, $str, 1, '' );
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
        for my $x ( $bounds->{min}{x} .. $bounds->{max}{x} - 1 ) {
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
                    my $seq = $cell_style->diff_sequence($pen);
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

        # Simple string parsing - split by graphemes
        my @chars = split //, $str;
        my $i     = 0;
        while ( $i <= $#chars ) {
            my $ch = $chars[$i];
            if ( $ch eq "\n" ) {
                $y++;
                $i++;
                next;
            }
            if ( $ch eq "\r" ) {
                $x = $bounds->{min}{x};
                $i++;
                next;
            }

            # Try to build a grapheme cluster (simplified)
            my $grapheme = $ch;
            $i++;

            # Check for combining characters (simple check)
            while ( $i <= $#chars ) {
                my $next_ord = ord( $chars[$i] );

                # Combining marks are in various Unicode ranges
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
                if ( !$truncate && $x + $cell->width + $width > $bounds->{max}{x} && $y + 1 < $bounds->{max}{y} ) {
                    $x = $bounds->{min}{x};
                    $y++;
                }
                if ( _pos_in_bounds( $x, $y, $bounds ) ) {
                    $cell->append( map {ord} split //, $grapheme );
                    $cell->{style} = $style->clone;
                    $cell->{link}  = $link->clone;
                    $cell->{width} = $width;
                    $buf->set_cell( $x, $y, $cell );
                    $x += $width;
                }
                $cell = Cancer::CellBuf::Cell->new;
            }
        }

        # Set last cell if not empty
        if ( !$cell->empty ) {
            $buf->set_cell( $x, $y, $cell ) if _pos_in_bounds( $x, $y, $bounds );
        }
    }

    sub _pos_in_bounds ( $x, $y, $bounds ) {
        $x >= $bounds->{min}{x} && $x < $bounds->{max}{x} && $y >= $bounds->{min}{y} && $y < $bounds->{max}{y};
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
1;
