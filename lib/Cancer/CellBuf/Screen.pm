use v5.42;

package Cancer::CellBuf::Screen v0.0.1 {
    use Cancer::Ansi qw[
        CursorUp CursorDown CursorForward CursorBackward CursorPosition
        EraseLineRight EraseLineLeft EraseScreenBelow EraseEntireScreen
        CursorHomePosition ShowCursor HideCursor ReverseIndex
        ScrollUp ScrollDown InsertLine DeleteLine InsertCharacter DeleteCharacter
        EraseCharacter RepeatPreviousCharacter SetTopBottomMargins
        ModeAltScreenSaveCursor ModeAutoWrap ModeInsertReplace
        ResetStyle
        set_mode reset_mode set_hyperlink reset_hyperlink
    ];
    use Cancer::CellBuf::Buffer;
    use Cancer::CellBuf::TabStops;
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Geom qw[Rect];
    use Carp                  qw[carp];
    use IO::Handle;
    use constant {
        CAP_VPA  => 0x01,
        CAP_HPA  => 0x02,
        CAP_CHT  => 0x04,
        CAP_CBT  => 0x08,
        CAP_REP  => 0x10,
        CAP_ECH  => 0x20,
        CAP_ICH  => 0x40,
        CAP_SD   => 0x80,
        CAP_SU   => 0x100,
        NO_CAPS  => 0,
        ALL_CAPS => 0x1FF
    };

    sub new ( $class, %args ) {
        my $writer = delete $args{writer} // \*STDOUT;
        my $width  = delete $args{width}  // 0;
        my $height = delete $args{height} // 0;
        my $opts   = delete $args{opts}   // {};
        my $self   = bless {
            w           => $writer,
            buf         => '',
            curbuf      => undef,
            newbuf      => undef,
            tabs        => undef,
            touch       => {},
            queue_above => [],
            oldhash     => [],
            newhash     => [],
            hashtab     => [],
            oldnum      => [],
            cur_style   => Cancer::CellBuf::Style->new,
            cur_link    => Cancer::CellBuf::Link->new,
            cur_x       => -1,
            cur_y       => -1,
            saved_x     => -1,
            saved_y     => -1,
            opts        => {
                term            => $ENV{TERM} // '',
                relative_cursor => 0,
                alt_screen      => 0,
                show_cursor     => 1,
                hard_tabs       => 0,
                backspace       => 0,
                map_nl          => 0,
                %{$opts}
            },
            method          => undef,
            scroll_height   => 0,
            alt_screen_mode => 0,
            cursor_hidden   => 0,
            clear           => 1,
            caps            => NO_CAPS,
            queued_text     => 0,
            at_phantom      => 0
        }, $class;

        # Try to get terminal size if not provided
        if ( $width <= 0 || $height <= 0 ) {
            if ( ref $writer eq 'GLOB' || ( ref $writer && $writer->can('fileno') ) ) {
                my $size = _get_terminal_size($writer);
                ( $width, $height ) = @$size if $size;
            }
        }
        $width          = 0 if $width < 0;
        $height         = 0 if $height < 0;
        $self->{caps}   = _xterm_caps( $self->{opts}{term} );
        $self->{curbuf} = Cancer::CellBuf::Buffer->new( width => $width, height => $height );
        $self->{newbuf} = Cancer::CellBuf::Buffer->new( width => $width, height => $height );
        $self->_reset;
        return $self;
    }
    sub width  ($self)           { $self->{newbuf}->width }
    sub height ($self)           { $self->{newbuf}->height }
    sub bounds ($self)           { $self->{newbuf}->bounds }
    sub cell   ( $self, $x, $y ) { $self->{newbuf}->cell( $x, $y ) }

    sub set_cell ( $self, $x, $y, $cell ) {
        my $cell_width = defined $cell ? $cell->width : 1;
        my $prev       = $self->{curbuf}->cell( $x, $y );
        if ( !_cell_equal( $prev, $cell ) ) {
            my $chg = $self->{touch}{$y};
            if ( !defined $chg ) {
                $chg = { first_cell => $x, last_cell => $x + $cell_width };
            }
            else {
                $chg->{first_cell} = $x               if $x < $chg->{first_cell};
                $chg->{last_cell}  = $x + $cell_width if $x + $cell_width > $chg->{last_cell};
            }
            $self->{touch}{$y} = $chg;
        }
        return $self->{newbuf}->set_cell( $x, $y, $cell );
    }

    sub fill ( $self, $cell ) {
        return $self->fill_rect( $cell, $self->bounds );
    }

    sub fill_rect ( $self, $cell, $rect ) {
        $self->{newbuf}->fill_rect( $cell, $rect );
        for my $y ( $rect->min->y .. $rect->max->y - 1 ) {
            $self->{touch}{$y} = { first_cell => $rect->min->x, last_cell => $rect->max->x };
        }
        return 1;
    }
    sub clear       ($self)          { $self->clear_rect( $self->bounds ) }
    sub clear_rect  ( $self, $rect ) { $self->fill_rect( undef, $rect ) }
    sub redraw      ($self)          { $self->{clear}             = 1 }
    sub show_cursor ($self)          { $self->{opts}{show_cursor} = 1 }
    sub hide_cursor ($self)          { $self->{opts}{show_cursor} = 0 }

    sub enter_alt_screen ($self) {
        $self->{opts}{alt_screen} = 1;
        $self->{clear}            = 1;
        $self->{saved_x}          = $self->{cur_x};
        $self->{saved_y}          = $self->{cur_y};
    }

    sub exit_alt_screen ($self) {
        $self->{opts}{alt_screen} = 0;
        $self->{clear}            = 1;
        $self->{cur_x}            = $self->{saved_x};
        $self->{cur_y}            = $self->{saved_y};
    }

    sub resize ( $self, $width, $height ) {
        my $old_width  = $self->{newbuf}->width;
        my $old_height = $self->{newbuf}->height;
        $self->{clear} = 1 if $self->{opts}{alt_screen} || $width != $old_width;

        # Clear new columns/lines
        if ( $width > $old_width ) {
            $self->clear_rect( Rect( $old_width - 1, 0, $width - $old_width, $height ) );
        }
        elsif ( $width < $old_width ) {
            $self->clear_rect( Rect( $width - 1, 0, $old_width - $width, $height ) );
        }
        if ( $height > $old_height ) {
            $self->clear_rect( Rect( 0, $old_height, $width, $height - $old_height ) );
        }
        elsif ( $height < $old_height ) {
            $self->clear_rect( Rect( 0, $height, $width, $old_height - $height ) );
        }
        $self->{newbuf}->resize( $width, $height );
        $self->{tabs}->resize($width);
        $self->{oldhash}       = [];
        $self->{newhash}       = [];
        $self->{scroll_height} = 0;
        return 1;
    }

    sub render ($self) {
        return unless $self->_needs_render;

        # Handle alt screen mode
        if ( $self->{opts}{alt_screen} != $self->{alt_screen_mode} ) {
            if ( $self->{opts}{alt_screen} ) {
                $self->{buf} .= set_mode(ModeAltScreenSaveCursor);
            }
            else {
                $self->{buf} .= reset_mode(ModeAltScreenSaveCursor);
            }
            $self->{alt_screen_mode} = $self->{opts}{alt_screen};
        }

        # Handle cursor visibility
        if ( ( !$self->{opts}{show_cursor} ) != $self->{cursor_hidden} ) {
            $self->{cursor_hidden} = !$self->{opts}{show_cursor};
            $self->{buf} .= HideCursor() if $self->{cursor_hidden};
        }

        # Handle queued above
        if ( @{ $self->{queue_above} } ) {
            $self->_move( 0, $self->{newbuf}->height - 1 );
            $self->{buf} .= "\n" x scalar @{ $self->{queue_above} };
            $self->{cur_y} += scalar @{ $self->{queue_above} };
            $self->_move_cursor( 0, 0, 0 );
            $self->{buf} .= InsertLine( scalar @{ $self->{queue_above} } );
            for my $line ( @{ $self->{queue_above} } ) {
                $self->{buf} .= $line . "\r\n";
            }
            $self->{queue_above} = [];
        }
        my $non_empty;
        my $partial_clear
            = !$self->{opts}{alt_screen}                     &&
            $self->{cur_x} != -1                             &&
            $self->{cur_y} != -1                             &&
            $self->{curbuf}->width == $self->{newbuf}->width &&
            $self->{curbuf}->height > $self->{newbuf}->height;
        if ( !$self->{clear} && $partial_clear ) {
            $self->_clear_below( undef, $self->{newbuf}->height - 1 );
        }
        if ( $self->{clear} ) {
            $self->_clear_update;
            $self->{clear} = 0;
        }
        elsif ( %{ $self->{touch} } ) {
            if ( $self->{opts}{alt_screen} ) {
                $self->_scroll_optimize;
            }
            $non_empty = $self->{opts}{alt_screen} ? _min( $self->{curbuf}->height, $self->{newbuf}->height ) : $self->{newbuf}->height;
            $non_empty = $self->_clear_bottom($non_empty);
            for my $i ( 0 .. $non_empty - 1 ) {
                if ( exists $self->{touch}{$i} ) {
                    $self->_transform_line($i);
                }
            }
        }

        # Sync buffers
        $self->{touch} = {};
        if ( $self->{curbuf}->width != $self->{newbuf}->width || $self->{curbuf}->height != $self->{newbuf}->height ) {
            my $old_h = $self->{curbuf}->height;
            $self->{curbuf}->resize( $self->{newbuf}->width, $self->{newbuf}->height );
            for my $i ( $old_h .. $self->{newbuf}->height - 1 ) {
                $self->{curbuf}{lines}[$i] = $self->{newbuf}{lines}[$i] if defined $self->{newbuf}{lines}[$i];
            }
        }
        $self->_update_pen(undef);

        # Handle cursor flicker reduction
        if ( length $self->{buf} > 1 && $self->{opts}{show_cursor} && !$self->{cursor_hidden} && $self->{queued_text} ) {
            $self->{buf} = HideCursor() . $self->{buf} . ShowCursor();
        }
        $self->{queued_text} = 0;
    }

    sub flush ($self) {
        $self->render;
        if ( length $self->{buf} > 0 ) {
            if ( ref $self->{w} && $self->{w}->can('print') ) {
                $self->{w}->print( $self->{buf} );
            }
            else {
                print { $self->{w} } $self->{buf};
            }
            $self->{buf} = '';
        }
    }

    sub close ($self) {
        $self->render;
        $self->_update_pen(undef);
        $self->_move( 0, $self->{newbuf}->height - 1 );
        if ( $self->{alt_screen_mode} ) {
            $self->{buf} .= reset_mode(ModeAltScreenSaveCursor);
            $self->{alt_screen_mode} = 0;
        }
        if ( $self->{cursor_hidden} ) {
            $self->{buf} .= ShowCursor();
            $self->{cursor_hidden} = 0;
        }
        $self->flush;
        $self->_reset;
    }

    sub move_to ( $self, $x, $y ) {
        $self->_move( $x, $y );
    }

    sub insert_above ( $self, $str ) {
        return if $self->{opts}{alt_screen};
        for my $line ( split /\n/, $str ) {

            # Truncate line to width (simplified)
            my $w = $self->width;
            $line = substr( $line, 0, $w ) if length($line) > $w;
            push @{ $self->{queue_above} }, $line;
        }
    }

    # --- Internal methods ---
    sub _reset ($self) {
        $self->{scroll_height}   = 0;
        $self->{cursor_hidden}   = 0;
        $self->{alt_screen_mode} = 0;
        $self->{touch}           = {};
        $self->{curbuf}->clear if $self->{curbuf};
        $self->{newbuf}->clear if $self->{newbuf};
        $self->{buf}             = '';
        $self->{tabs}            = Cancer::CellBuf::TabStops->default( $self->{newbuf}->width ) if $self->{newbuf};
        $self->{oldhash}         = [];
        $self->{newhash}         = [];
        $self->{caps}            = _xterm_caps( $self->{opts}{term} ) if $self->{opts}{term} =~ /^linux/;
        $self->{opts}{hard_tabs} = 0                                  if $self->{opts}{term} =~ /^linux/;
    }

    sub _needs_render ($self) {
        return 0
            if $self->{opts}{alt_screen} == $self->{alt_screen_mode}  &&
            ( !$self->{opts}{show_cursor} ) == $self->{cursor_hidden} &&
            !$self->{clear}                                           &&
            !%{ $self->{touch} }                                      &&
            !@{ $self->{queue_above} };
        return 1;
    }

    sub _clear_blank ($self) {
        my $c = Cancer::CellBuf::Cell::BlankCell->clone;
        if ( !$self->{cur_style}->empty || !$self->{cur_link}->empty ) {
            $c->{style} = $self->{cur_style}->clone;
            $c->{link}  = $self->{cur_link}->clone;
        }
        return $c;
    }

    sub _update_pen ( $self, $cell ) {
        $cell //= Cancer::CellBuf::Cell::BlankCell;
        my $style = $cell->style // Cancer::CellBuf::Style->new;
        my $link  = $cell->link  // Cancer::CellBuf::Link->new;
        if ( !$style->equal( $self->{cur_style} ) ) {
            my $seq = $style->diff_sequence( $self->{cur_style} );
            $seq = ResetStyle() if $style->empty && length($seq) > length( ResetStyle() );
            $self->{buf} .= $seq;
            $self->{cur_style} = $style->clone;
        }
        if ( !$link->equal( $self->{cur_link} ) ) {
            $self->{buf} .= set_hyperlink( $link->url, $link->params );
            $self->{cur_link} = $link->clone;
        }
    }

    sub _move ( $self, $x, $y ) {
        my $width  = _max( $self->{newbuf}->width,  $self->{curbuf}->width );
        my $height = _max( $self->{newbuf}->height, $self->{curbuf}->height );
        if ( $width > 0 && $x >= $width ) {
            $y += int( $x / $width );
            $x %= $width;
        }
        $y = $height - 1 if $height > 0 && $y > $height - 1;
        $y = 0           if $y < 0;
        $x = 0           if $x < 0;
        return if $x == $self->{cur_x} && $y == $self->{cur_y};
        $self->_move_cursor( $x, $y, 1 );
    }

    sub _move_cursor ( $self, $x, $y, $overwrite ) {
        if ( !$self->{opts}{alt_screen} && $self->{cur_x} == -1 && $self->{cur_y} == -1 ) {
            $self->{buf} .= "\r";
            $self->{cur_x} = 0;
            $self->{cur_y} = 0;
        }
        my $seq = _relative_cursor_move( $self, $self->{cur_x}, $self->{cur_y}, $x, $y, $overwrite );
        $self->{buf} .= $seq;
        $self->{cur_x} = $x;
        $self->{cur_y} = $y;
    }

    sub _relative_cursor_move ( $self, $fx, $fy, $tx, $ty, $overwrite ) {
        my $seq = '';
        if ( $ty != $fy ) {
            my $yseq = '';
            if ( $ty > $fy ) {
                my $n   = $ty - $fy;
                my $cud = CursorDown($n);
                $yseq = $cud;
                my $should_scroll = !$self->{opts}{alt_screen} && $fy + $n >= $self->{scroll_height};
                my $lf            = "\n" x $n;
                if ( $should_scroll || ( $fy + $n < $self->{newbuf}->height && length($lf) < length($yseq) ) ) {
                    $yseq                  = $lf;
                    $self->{scroll_height} = _max( $self->{scroll_height}, $fy + $n );
                    $fx                    = 0 if $self->{opts}{map_nl};
                }
            }
            elsif ( $ty < $fy ) {
                my $n   = $fy - $ty;
                my $cuu = CursorUp($n);
                $yseq = $cuu;
                if ( $n == 1 && $fy - 1 > 0 ) {
                    $yseq = ReverseIndex();
                }
            }
            $seq .= $yseq;
        }
        if ( $tx != $fx ) {
            my $xseq = '';
            if ( $tx > $fx ) {
                my $n   = $tx - $fx;
                my $cuf = CursorForward($n);
                $xseq = $cuf;

                # Try overwrite optimization
                if ( $overwrite && $ty >= 0 ) {
                    my $ovw           = '';
                    my $can_overwrite = 1;
                    for my $i ( 0 .. $n - 1 ) {
                        my $cell = $self->{newbuf}->cell( $fx + $i, $ty );
                        if ( defined $cell && $cell->width > 0 ) {
                            $i += $cell->width - 1;
                            if ( !_style_equal( $cell->style, $self->{cur_style} ) || !_link_equal( $cell->link, $self->{cur_link} ) ) {
                                $can_overwrite = 0;
                                last;
                            }
                        }
                    }
                    if ( $can_overwrite && $ty >= 0 ) {
                        for my $i ( 0 .. $n - 1 ) {
                            my $cell = $self->{newbuf}->cell( $fx + $i, $ty );
                            if ( defined $cell && $cell->width > 0 ) {
                                $ovw .= $cell->string;
                                $i += $cell->width - 1;
                            }
                            else {
                                $ovw .= ' ';
                            }
                        }
                        $xseq = $ovw if length($ovw) < length($xseq);
                    }
                }
            }
            elsif ( $tx < $fx ) {
                my $n   = $fx - $tx;
                my $cub = CursorBackward($n);
                $xseq = $cub;
                if ( $self->{opts}{backspace} && $n < length($xseq) ) {
                    $xseq = "\b" x $n;
                }
            }
            $seq .= $xseq;
        }
        return $seq;
    }

    sub _clear_to_end ( $self, $blank, $force ) {
        if ( $self->{cur_y} >= 0 ) {
            my $curline = $self->{curbuf}->line( $self->{cur_y} );
            if ($curline) {
                for my $j ( $self->{cur_x} .. $self->{curbuf}->width - 1 ) {
                    if ( $j >= 0 ) {
                        my $c = $curline->at($j);
                        if ( !_cell_equal( $c, $blank ) ) {
                            $curline->set( $j, $blank );
                            $force = 1;
                        }
                    }
                }
            }
        }
        if ($force) {
            $self->_update_pen($blank);
            my $count = $self->{newbuf}->width - $self->{cur_x};
            $self->{buf} .= EraseLineRight();
        }
    }

    sub _clear_to_bottom ( $self, $blank ) {
        my $row = $self->{cur_y};
        $row = 0 if $row < 0;
        $self->_update_pen($blank);
        $self->{buf} .= EraseScreenBelow();
        $self->{curbuf}->clear_rect( Rect( $self->{cur_x}, $row,     $self->{curbuf}->width - $self->{cur_x}, 1 ) );
        $self->{curbuf}->clear_rect( Rect( 0,              $row + 1, $self->{curbuf}->width,                  $self->{curbuf}->height - $row - 1 ) );
    }

    sub _clear_below ( $self, $blank, $row ) {
        $self->_move( 0, $row );
        $self->_clear_to_bottom($blank);
    }

    sub _clear_screen ( $self, $blank ) {
        $self->_update_pen($blank);
        $self->{buf} .= CursorHomePosition() . EraseEntireScreen();
        $self->{cur_x} = 0;
        $self->{cur_y} = 0;
        $self->{curbuf}->fill($blank);
    }

    sub _clear_bottom ( $self, $total ) {
        return 0 if $total <= 0;
        my $top       = $total;
        my $blank     = $self->_clear_blank;
        my $can_clear = !$blank || $blank->clear;
        if ($can_clear) {
            for my $row ( reverse 0 .. $total - 1 ) {
                my $old_line = $self->{curbuf}->line($row);
                my $new_line = $self->{newbuf}->line($row);
                my $ok       = 1;
                for my $col ( 0 .. $self->{newbuf}->width - 1 ) {
                    $ok = _cell_equal( $new_line->at($col), $blank );
                    last unless $ok;
                }
                if ( !$ok ) {
                    last;
                }
                for my $col ( 0 .. $self->{newbuf}->width - 1 ) {
                    $ok = _cell_equal( $old_line->at($col), $blank );
                    last unless $ok;
                }
                $top = $row if !$ok;
            }
            if ( $top < $total ) {
                $self->_move( 0, $top - 1 );
                $self->_clear_to_bottom($blank);
                if ( @{ $self->{oldhash} } && @{ $self->{newhash} } ) {
                    for my $row ( $top .. $self->{newbuf}->height - 1 ) {
                        $self->{oldhash}[$row] = $self->{newhash}[$row] if defined $self->{newhash}[$row];
                    }
                }
            }
        }
        return $top;
    }

    sub _clear_update ($self) {
        my $blank = $self->_clear_blank;
        my $non_empty;
        if ( $self->{opts}{alt_screen} ) {
            $non_empty = _max( $self->{curbuf}->height, $self->{newbuf}->height );
            $self->_clear_screen($blank);
        }
        else {
            $non_empty = $self->{newbuf}->height;
            $self->_clear_below( $blank, 0 );
        }
        $non_empty = $self->_clear_bottom($non_empty);
        for my $i ( 0 .. $non_empty - 1 ) {
            $self->_transform_line($i);
        }
    }

    sub _transform_line ( $self, $y ) {
        my $old_line = $self->{curbuf}->line($y);
        my $new_line = $self->{newbuf}->line($y);
        return unless $old_line && $new_line;

        # Find first changed cell
        my $first_cell   = 0;
        my $line_changed = 0;
        for my $i ( 0 .. $self->{newbuf}->width - 1 ) {
            if ( !_cell_equal( $new_line->at($i), $old_line->at($i) ) ) {
                $line_changed = 1;
                last;
            }
            $first_cell++;
        }
        return unless $line_changed;

        # Find last changed cell
        my $last_cell = $self->{newbuf}->width - 1;
        while ( $last_cell > $first_cell && _cell_equal( $new_line->at($last_cell), $old_line->at($last_cell) ) ) {
            $last_cell--;
        }
        if ( $last_cell >= $first_cell ) {
            $self->_move( $first_cell, $y );
            $self->_put_range( $old_line, $new_line, $y, $first_cell, $last_cell );

            # Update old line
            for my $i ( $first_cell .. $last_cell ) {
                $old_line->set( $i, $new_line->at($i) );
            }
        }
    }

    sub _put_range ( $self, $old_line, $new_line, $y, $start, $end ) {
        for my $j ( $start .. $end ) {
            my $old_cell = $old_line->at($j);
            my $new_cell = $new_line->at($j);
            unless ( _cell_equal( $old_cell, $new_cell ) ) {
                $self->_put_cell($new_cell);
            }
            else {
                $self->_move( $j, $y ) if $j != $self->{cur_x};
            }
        }
    }

    sub _put_cell ( $self, $cell ) {
        my $width  = $self->{newbuf}->width;
        my $height = $self->{newbuf}->height;
        if ( $self->{opts}{alt_screen} && $self->{cur_x} == $width - 1 && $self->{cur_y} == $height - 1 ) {
            $self->_put_cell_lr($cell);
        }
        else {
            $self->_put_attr_cell($cell);
        }
    }

    sub _put_attr_cell ( $self, $cell ) {
        return if defined $cell && $cell->empty;
        $cell = $self->_clear_blank unless defined $cell;
        if ( $self->{at_phantom} ) {
            $self->{cur_x} = 0;
            $self->{cur_y}++;
            $self->{at_phantom} = 0;
        }
        $self->_update_pen($cell);
        $self->{buf} .= $cell->string;
        $self->{cur_x} += $cell->width;
        $self->{queued_text} = 1 if $cell->width > 0;
        $self->{at_phantom}  = 1 if $self->{cur_x} >= $self->{newbuf}->width;
    }

    sub _put_cell_lr ( $self, $cell ) {
        my $cur_x = $self->{cur_x};
        if ( !defined $cell || !$cell->empty ) {
            $self->{buf} .= reset_mode(ModeAutoWrap);
            $self->_put_attr_cell($cell);
            $self->{at_phantom} = 0;
            $self->{cur_x}      = $cur_x;
            $self->{buf} .= set_mode(ModeAutoWrap);
        }
    }

    # --- Hashmap / scroll optimization ---
    # newIndex sentinel: line was not matched in old buffer
    use constant newIndex => -1;

    sub _hash ( $self, $line ) {
        my $h = 0;
        for my $i ( 0 .. $self->{newbuf}->width - 1 ) {
            my $c = $line                      ? $line->at($i) : undef;
            my $r = ( defined $c && $c->rune ) ? $c->rune      : ord(' ');
            $h += ( $h << 5 ) + $r;
        }
        return $h;
    }

    sub _update_hashmap ($self) {
        my $height = $self->{newbuf}->height;
        if ( @{ $self->{oldhash} } >= $height && @{ $self->{newhash} } >= $height ) {
            for my $i ( 0 .. $height - 1 ) {
                if ( exists $self->{touch}{$i} ) {
                    $self->{oldhash}[$i] = $self->_hash( $self->{curbuf}->line($i) );
                    $self->{newhash}[$i] = $self->_hash( $self->{newbuf}->line($i) );
                }
            }
        }
        else {
            $self->{oldhash} = [];
            $self->{newhash} = [];
            for my $i ( 0 .. $height - 1 ) {
                $self->{oldhash}[$i] = $self->_hash( $self->{curbuf}->line($i) );
                $self->{newhash}[$i] = $self->_hash( $self->{newbuf}->line($i) );
            }
        }

        # Build hash table
        my @hashtab;
        for my $i ( 0 .. $height - 1 ) {
            my $hv  = $self->{oldhash}[$i];
            my $idx = 0;
            while ( $idx < @hashtab && $hashtab[$idx]{value} != $hv ) {
                $idx++;
            }
            if ( $idx >= @hashtab ) {
                $hashtab[$idx] = { value => $hv, oldcount => 0, newcount => 0, oldindex => 0, newindex => 0 };
            }
            $hashtab[$idx]{value} = $hv;
            $hashtab[$idx]{oldcount}++;
            $hashtab[$idx]{oldindex} = $i;
        }
        for my $i ( 0 .. $height - 1 ) {
            my $hv  = $self->{newhash}[$i];
            my $idx = 0;
            while ( $idx < @hashtab && $hashtab[$idx]{value} != $hv ) {
                $idx++;
            }
            if ( $idx >= @hashtab ) {
                $hashtab[$idx] = { value => $hv, oldcount => 0, newcount => 0, oldindex => 0, newindex => 0 };
            }
            $hashtab[$idx]{value} = $hv;
            $hashtab[$idx]{newcount}++;
            $hashtab[$idx]{newindex} = $i;
            $self->{oldnum}[$i] = newIndex;
        }
        $self->{hashtab} = \@hashtab;

        # Mark line pair corresponding to unique hash pairs
        for my $hsp ( @{ $self->{hashtab} } ) {
            next unless $hsp->{oldcount} == 1 && $hsp->{newcount} == 1 && $hsp->{oldindex} != $hsp->{newindex};
            $self->{oldnum}[ $hsp->{newindex} ] = $hsp->{oldindex};
        }
        $self->_grow_hunks;

        # Eliminate bad or impossible shifts
        my $i = 0;
        while ( $i < $height ) {
            while ( $i < $height && $self->{oldnum}[$i] == newIndex ) { $i++ }
            last if $i >= $height;
            my $start = $i;
            my $shift = $self->{oldnum}[$i] - $i;
            $i++;
            while ( $i < $height && $self->{oldnum}[$i] != newIndex && $self->{oldnum}[$i] - $i == $shift ) {
                $i++;
            }
            my $size = $i - $start;
            if ( $size < 3 || $size + _min( int( $size / 8 ), 2 ) < abs($shift) ) {
                for my $j ( $start .. $i - 1 ) {
                    $self->{oldnum}[$j] = newIndex;
                }
            }
        }
        $self->_grow_hunks;
    }

    sub _grow_hunks ($self) {
        my $height = $self->{newbuf}->height;
        my ( $back_limit, $back_ref_limit ) = ( 0, 0 );
        my $i = 0;
        while ( $i < $height && $self->{oldnum}[$i] == newIndex ) { $i++ }
        while ( $i < $height ) {
            my $start = $i;
            my $shift = $self->{oldnum}[$i] - $i;

            # Get forward limit
            $i = $start + 1;
            while ( $i < $height && $self->{oldnum}[$i] != newIndex && $self->{oldnum}[$i] - $i == $shift ) {
                $i++;
            }
            my $end = $i;
            while ( $i < $height && $self->{oldnum}[$i] == newIndex ) { $i++ }
            my $next_hunk     = $i;
            my $forward_limit = $i;
            my $forward_ref_limit;
            if ( $i >= $height || $self->{oldnum}[$i] >= $i ) {
                $forward_ref_limit = $i;
            }
            else {
                $forward_ref_limit = $self->{oldnum}[$i];
            }
            $i = $start - 1;

            # Grow back
            if ( $shift < 0 ) {
                $back_limit = $back_ref_limit + abs($shift);
            }
            while ( $i >= $back_limit ) {
                if ( $self->{newhash}[$i] == $self->{oldhash}[ $i + $shift ] || $self->_cost_effective( $i + $shift, $i, $shift < 0 ) ) {
                    $self->{oldnum}[$i] = $i + $shift;
                }
                else {
                    last;
                }
                $i--;
            }
            $i = $end;

            # Grow forward
            if ( $shift > 0 ) {
                $forward_limit = $forward_ref_limit - $shift;
            }
            while ( $i < $forward_limit ) {
                if ( $self->{newhash}[$i] == $self->{oldhash}[ $i + $shift ] || $self->_cost_effective( $i + $shift, $i, $shift > 0 ) ) {
                    $self->{oldnum}[$i] = $i + $shift;
                }
                else {
                    last;
                }
                $i++;
            }
            $back_limit     = $i;
            $back_ref_limit = $back_limit;
            $back_ref_limit += $shift if $shift > 0;
            $i = $next_hunk;
        }
    }

    sub _cost_effective ( $self, $from, $to, $blank ) {
        return 0 if $from == $to;
        my $new_from = $self->{oldnum}[$from];
        $new_from = $from if $new_from == newIndex;

        # Cost before move
        my $cost_before;
        if ($blank) {
            $cost_before = $self->_update_cost_blank( $self->{newbuf}->line($to) );
        }
        else {
            $cost_before = $self->_update_cost( $self->{curbuf}->line($to), $self->{newbuf}->line($to) );
        }
        $cost_before += $self->_update_cost( $self->{curbuf}->line($new_from), $self->{newbuf}->line($from) );

        # Cost after move
        my $cost_after;
        if ( $new_from == $from ) {
            $cost_after = $self->_update_cost_blank( $self->{newbuf}->line($from) );
        }
        else {
            $cost_after = $self->_update_cost( $self->{curbuf}->line($new_from), $self->{newbuf}->line($from) );
        }
        $cost_after += $self->_update_cost( $self->{newbuf}->line($from), $self->{newbuf}->line($to) );
        return $cost_before >= $cost_after;
    }

    sub _update_cost ( $self, $from_line, $to_line ) {
        my $cost = 0;
        for my $i ( 0 .. $self->{newbuf}->width - 1 ) {
            my $fc = $from_line ? $from_line->at($i) : undef;
            my $tc = $to_line   ? $to_line->at($i)   : undef;
            $cost++ unless _cell_equal( $fc, $tc );
        }
        return $cost;
    }

    sub _update_cost_blank ( $self, $to_line ) {
        my $cost = 0;
        for my $i ( 0 .. $self->{newbuf}->width - 1 ) {
            my $tc = $to_line ? $to_line->at($i) : undef;
            $cost++ unless _cell_equal( undef, $tc );
        }
        return $cost;
    }

    sub _scroll_oldhash ( $self, $n, $top, $bot ) {
        return unless @{ $self->{oldhash} };
        my $size = $bot - $top + 1 - abs($n);
        if ( $n > 0 ) {
            for my $i ( 0 .. $size - 1 ) {
                $self->{oldhash}[ $top + $i ] = $self->{oldhash}[ $top + $n + $i ];
            }
            for my $i ( reverse( $bot - $n + 1 .. $bot ) ) {
                $self->{oldhash}[$i] = $self->_hash( $self->{curbuf}->line($i) );
            }
        }
        elsif ( $n < 0 ) {
            my $an = abs($n);
            for my $i ( reverse( 0 .. $size - 1 ) ) {
                $self->{oldhash}[ $top + $an + $i ] = $self->{oldhash}[ $top + $i ];
            }
            for my $i ( $top .. $top + $an - 1 ) {
                $self->{oldhash}[$i] = $self->_hash( $self->{curbuf}->line($i) );
            }
        }
    }

    sub _scroll_optimize ($self) {
        my $height = $self->{newbuf}->height;
        $self->{oldnum} = [] unless $self->{oldnum} && @{ $self->{oldnum} } >= $height;
        $self->_update_hashmap;
        return if @{ $self->{hashtab} } < $height;

        # Pass 1 - from top to bottom scrolling up
        my $i = 0;
        while ( $i < $height ) {
            while ( $i < $height && ( $self->{oldnum}[$i] == newIndex || $self->{oldnum}[$i] <= $i ) ) {
                $i++;
            }
            last if $i >= $height;
            my $shift = $self->{oldnum}[$i] - $i;    # shift > 0
            my $start = $i;
            $i++;
            while ( $i < $height && $self->{oldnum}[$i] != newIndex && $self->{oldnum}[$i] - $i == $shift ) {
                $i++;
            }
            my $end = $i - 1 + $shift;
            $self->_scrolln( $shift, $start, $end, $height - 1 );
        }

        # Pass 2 - from bottom to top scrolling down
        $i = $height - 1;
        while ( $i >= 0 ) {
            while ( $i >= 0 && ( $self->{oldnum}[$i] == newIndex || $self->{oldnum}[$i] >= $i ) ) {
                $i--;
            }
            last if $i < 0;
            my $shift = $self->{oldnum}[$i] - $i;    # shift < 0
            my $end   = $i;
            $i--;
            while ( $i >= 0 && $self->{oldnum}[$i] != newIndex && $self->{oldnum}[$i] - $i == $shift ) {
                $i--;
            }
            my $start = $i + 1 - abs($shift);
            $self->_scrolln( $shift, $start, $end, $height - 1 );
        }
    }

    sub _scrolln ( $self, $n, $top, $bot, $max_y ) {
        my $blank = $self->_clear_blank;
        if ( $n > 0 ) {
            my $v = $self->_scroll_up( $n, $top, $bot, 0, $max_y, $blank );
            if ( !$v ) {
                $self->{buf} .= SetTopBottomMargins( $top + 1, $bot + 1 );
                ( $self->{cur_x}, $self->{cur_y} ) = ( -1, -1 );
                $v = $self->_scroll_up( $n, $top, $bot, $top, $bot, $blank );
                $self->{buf} .= SetTopBottomMargins( 1, $max_y + 1 );
                ( $self->{cur_x}, $self->{cur_y} ) = ( -1, -1 );
            }
            if ( !$v ) {
                $v = $self->_scroll_idl( $n, $top, $bot - $n + 1, $blank );
            }
            if ($v) {
                $self->_scroll_buffer( $self->{curbuf}, $n, $top, $bot, $blank );
                $self->_scroll_oldhash( $n, $top, $bot );
            }
        }
        elsif ( $n < 0 ) {
            my $an = abs($n);
            my $v  = $self->_scroll_down( $an, $top, $bot, 0, $max_y, $blank );
            if ( !$v ) {
                $self->{buf} .= SetTopBottomMargins( $top + 1, $bot + 1 );
                ( $self->{cur_x}, $self->{cur_y} ) = ( -1, -1 );
                $v = $self->_scroll_down( $an, $top, $bot, $top, $bot, $blank );
                $self->{buf} .= SetTopBottomMargins( 1, $max_y + 1 );
                ( $self->{cur_x}, $self->{cur_y} ) = ( -1, -1 );
            }
            if ( !$v ) {
                $v = $self->_scroll_idl( $an, $bot + $n + 1, $top, $blank );
            }
            if ($v) {
                $self->_scroll_buffer( $self->{curbuf}, $n, $top, $bot, $blank );
                $self->_scroll_oldhash( $n, $top, $bot );
            }
        }
        return 1;
    }

    sub _scroll_up ( $self, $n, $top, $bot, $min_y, $max_y, $blank ) {
        if ( $n == 1 && $top == $min_y && $bot == $max_y ) {
            $self->_move( 0, $bot );
            $self->_update_pen($blank);
            $self->{buf} .= "\n";
        }
        elsif ( $n == 1 && $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $self->{buf} .= DeleteLine(1);
        }
        elsif ( $top == $min_y && $bot == $max_y ) {
            my $supports_su = $self->{caps} & CAP_SU;
            if ($supports_su) {
                $self->_move( 0, $bot );
            }
            else {
                $self->_move( 0, $top );
            }
            $self->_update_pen($blank);
            if ($supports_su) {
                $self->{buf} .= ScrollUp($n);
            }
            else {
                $self->{buf} .= "\n" x $n;
            }
        }
        elsif ( $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $self->{buf} .= DeleteLine($n);
        }
        else {
            return 0;
        }
        return 1;
    }

    sub _scroll_down ( $self, $n, $top, $bot, $min_y, $max_y, $blank ) {
        if ( $n == 1 && $top == $min_y && $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $self->{buf} .= ReverseIndex();
        }
        elsif ( $n == 1 && $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $self->{buf} .= InsertLine(1);
        }
        elsif ( $top == $min_y && $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            if ( $self->{caps} & CAP_SD ) {
                $self->{buf} .= ScrollDown($n);
            }
            else {
                $self->{buf} .= ReverseIndex() x $n;
            }
        }
        elsif ( $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $self->{buf} .= InsertLine($n);
        }
        else {
            return 0;
        }
        return 1;
    }

    sub _scroll_idl ( $self, $n, $del, $ins, $blank ) {
        return 0 if $n < 0;
        $self->_move( 0, $del );
        $self->_update_pen($blank);
        $self->{buf} .= DeleteLine($n);
        $self->_move( 0, $ins );
        $self->_update_pen($blank);
        $self->{buf} .= InsertLine($n);
        return 1;
    }

    sub _scroll_buffer ( $self, $buf, $n, $top, $bot, $blank ) {
        return if $top < 0 || $bot < $top || $bot >= $buf->height;
        if ( $n < 0 ) {
            my $limit = $top - abs($n);
            for my $line ( reverse $limit .. $bot ) {
                $buf->{lines}[$line] = $buf->{lines}[ $line + $n ];
            }
            for my $line ( $top .. $limit - 1 ) {
                $buf->fill_rect( $blank, Rect( 0, $line, $buf->width, 1 ) );
            }
        }
        elsif ( $n > 0 ) {
            my $limit = $bot - $n;
            for my $line ( $top .. $limit ) {
                $buf->{lines}[$line] = $buf->{lines}[ $line + $n ];
            }
            for my $line ( reverse( $limit + 1 .. $bot ) ) {
                $buf->fill_rect( $blank, Rect( 0, $line, $buf->width, 1 ) );
            }
        }
        $self->_touch_line( $buf->width, $buf->height, $top, $bot - $top + 1, 1 );
    }

    sub _touch_line ( $self, $width, $height, $y, $n, $changed ) {
        return if $n < 0 || $y < 0 || $y >= $height;
        for my $i ( $y .. _min( $y + $n - 1, $height - 1 ) ) {
            if ($changed) {
                $self->{touch}{$i} = { first_cell => 0, last_cell => $width - 1 };
            }
            else {
                delete $self->{touch}{$i};
            }
        }
    }

    # --- Helper functions ---
    sub _cell_equal ( $a, $b ) {
        return 1 if defined $a  && defined $b && $a == $b;
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        $a->equal($b);
    }

    sub _style_equal ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        $a->equal($b);
    }

    sub _link_equal ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        $a->equal($b);
    }
    sub _max ( $a, $b ) { $a > $b ? $a : $b }
    sub _min ( $a, $b ) { $a < $b ? $a : $b }

    sub _xterm_caps ($term) {
        my @parts = split /-/, $term;
        return NO_CAPS unless @parts;
        my %caps = (
            contour   => ALL_CAPS,
            foot      => ALL_CAPS,
            ghostty   => ALL_CAPS,
            kitty     => ALL_CAPS,
            rio       => ALL_CAPS,
            st        => ALL_CAPS,
            tmux      => ALL_CAPS,
            wezterm   => ALL_CAPS,
            xterm     => ALL_CAPS,
            alacritty => ALL_CAPS & ~CAP_CHT,
            screen    => ALL_CAPS & ~CAP_REP,
            linux     => CAP_VPA | CAP_HPA | CAP_ECH | CAP_ICH
        );
        return $caps{ $parts[0] } // NO_CAPS;
    }

    sub _get_terminal_size ($fh) {
        if ( ref $fh eq 'GLOB' ) {
            if ( $^O eq 'MSWin32' ) {
                require Win32::Console;
                my $handle = eval { Win32::Console::GetStdHandle(-11) };
                if ($handle) {
                    my ( $w, $h ) = Win32::Console::GetConsoleScreenBufferInfo($handle);
                    return [ $w, $h ] if defined $w && defined $h;
                }
            }
            else {
                if ( eval { require Term::ReadKey } ) {
                    my @size = Term::ReadKey::GetTerminalSize($fh);
                    return [ $size[0], $size[1] ] if @size;
                }
            }
        }
        return [ 80, 24 ];    # Default fallback
    }
}
#
1;
