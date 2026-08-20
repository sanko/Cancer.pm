use v5.42;
use experimental 'class';
class Cancer::CellBuf::Screen v0.0.1 {
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
    use Cancer::Util          qw[_max _min];
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
    field $writer : param = \*STDOUT;
    field $width  : param = 0;
    field $height : param = 0;
    field $opts   : param = {};
    field $buf             = '';
    field $curbuf          = undef;
    field $newbuf          = undef;
    field $tabs            = undef;
    field $touch : reader  = {};
    field $queue_above     = [];
    field $oldhash         = [];
    field $newhash         = [];
    field $hashtab         = [];
    field $oldnum          = [];
    field $cur_style       = Cancer::CellBuf::Style->new;
    field $cur_link        = Cancer::CellBuf::Link->new;
    field $cur_x           = -1;
    field $cur_y           = -1;
    field $saved_x         = -1;
    field $saved_y         = -1;
    field $scroll_height   = 0;
    field $alt_screen_mode = 0;
    field $cursor_hidden   = 0;
    field $clear           = 1;
    field $caps            = NO_CAPS;
    field $queued_text     = 0;
    field $at_phantom      = 0;
    ADJUST {
        my $term_opts = {
            term            => $ENV{TERM} // '',
            relative_cursor => 0,
            alt_screen      => 0,
            show_cursor     => 1,
            hard_tabs       => 0,
            backspace       => 0,
            map_nl          => 0,
            %$opts
        };
        $opts = $term_opts;
        if ( $width <= 0 || $height <= 0 ) {
            if ( ref $writer eq 'GLOB' || ( ref $writer && $writer->can('fileno') ) ) {
                my $size = _get_terminal_size($writer);
                ( $width, $height ) = @$size if $size;
            }
        }
        $width  = 0 if $width < 0;
        $height = 0 if $height < 0;
        $caps   = _xterm_caps( $opts->{term} );
        $curbuf = Cancer::CellBuf::Buffer->new( width => $width, height => $height );
        $newbuf = Cancer::CellBuf::Buffer->new( width => $width, height => $height );
        $self->_reset;
    }
    method width ()        { $newbuf->width }
    method height ()       { $newbuf->height }
    method bounds ()       { $newbuf->bounds }
    method cell ( $x, $y ) { $newbuf->cell( $x, $y ) }

    method set_cell ( $x, $y, $cell ) {
        my $cell_width = defined $cell ? $cell->width : 1;
        my $prev       = $curbuf->cell( $x, $y );
        if ( !_cell_equal( $prev, $cell ) ) {
            my $chg = $touch->{$y};
            if ( !defined $chg ) {
                $chg = { first_cell => $x, last_cell => $x + $cell_width };
            }
            else {
                $chg->{first_cell} = $x               if $x < $chg->{first_cell};
                $chg->{last_cell}  = $x + $cell_width if $x + $cell_width > $chg->{last_cell};
            }
            $touch->{$y} = $chg;
        }
        return $newbuf->set_cell( $x, $y, $cell );
    }
    method fill ($cell) { return $self->fill_rect( $cell, $self->bounds ) }

    method fill_rect ( $cell, $rect ) {
        $newbuf->fill_rect( $cell, $rect );
        for my $y ( $rect->min_y .. $rect->max_y - 1 ) {
            $touch->{$y} = { first_cell => $rect->min_x, last_cell => $rect->max_x };
        }
        return 1;
    }
    method clear ()           { $self->clear_rect( $self->bounds ) }
    method clear_rect ($rect) { $self->fill_rect( undef, $rect ) }
    method redraw ()          { $clear               = 1 }
    method show_cursor ()     { $opts->{show_cursor} = 1 }
    method hide_cursor ()     { $opts->{show_cursor} = 0 }

    method enter_alt_screen () {
        $opts->{alt_screen} = 1;
        $clear              = 1;
        $saved_x            = $cur_x;
        $saved_y            = $cur_y;
    }

    method exit_alt_screen () {
        $opts->{alt_screen} = 0;
        $clear              = 1;
        $cur_x              = $saved_x;
        $cur_y              = $saved_y;
    }

    method resize ( $new_width, $new_height ) {
        my $old_width  = $newbuf->width;
        my $old_height = $newbuf->height;
        $clear = 1 if $opts->{alt_screen} || $new_width != $old_width;
        if ( $new_width > $old_width ) {
            $self->clear_rect( Rect( $old_width - 1, 0, $new_width - $old_width, $new_height ) );
        }
        elsif ( $new_width < $old_width ) {
            $self->clear_rect( Rect( $new_width - 1, 0, $old_width - $new_width, $new_height ) );
        }
        if ( $new_height > $old_height ) {
            $self->clear_rect( Rect( 0, $old_height, $new_width, $new_height - $old_height ) );
        }
        elsif ( $new_height < $old_height ) {
            $self->clear_rect( Rect( 0, $new_height, $new_width, $old_height - $new_height ) );
        }
        $newbuf->resize( $new_width, $new_height );
        $tabs->resize($new_width);
        $oldhash       = [];
        $newhash       = [];
        $scroll_height = 0;
        return 1;
    }

    method render () {
        return unless $self->_needs_render;
        if ( $opts->{alt_screen} != $alt_screen_mode ) {
            $buf .= $opts->{alt_screen} ? set_mode(ModeAltScreenSaveCursor) : reset_mode(ModeAltScreenSaveCursor);
            $alt_screen_mode = $opts->{alt_screen};
        }
        if ( ( !$opts->{show_cursor} ) != $cursor_hidden ) {
            $cursor_hidden = !$opts->{show_cursor};
            $buf .= HideCursor() if $cursor_hidden;
        }
        if (@$queue_above) {
            $self->_move( 0, $newbuf->height - 1 );
            $buf .= "\n" x scalar @$queue_above;
            $cur_y += scalar @$queue_above;
            $self->_move_cursor( 0, 0, 0 );
            $buf .= InsertLine( scalar @$queue_above );
            for my $line (@$queue_above) { $buf .= $line . "\r\n" }
            $queue_above = [];
        }
        my $non_empty;
        my $partial_clear
            = !$opts->{alt_screen} && $cur_x != -1 && $cur_y != -1 && $curbuf->width == $newbuf->width && $curbuf->height > $newbuf->height;
        if    ( !$clear && $partial_clear ) { $self->_clear_below( undef, $newbuf->height - 1 ) }
        if    ($clear)                      { $self->_clear_update; $clear = 0 }
        elsif (%$touch) {
            $self->_scroll_optimize if $opts->{alt_screen};
            $non_empty = $opts->{alt_screen} ? _min( $curbuf->height, $newbuf->height ) : $newbuf->height;
            $non_empty = $self->_clear_bottom($non_empty);
            for my $i ( 0 .. $non_empty - 1 ) {
                $self->_transform_line($i) if exists $touch->{$i};
            }
        }
        $touch = {};
        if ( $curbuf->width != $newbuf->width || $curbuf->height != $newbuf->height ) {
            my $old_h = $curbuf->height;
            $curbuf->resize( $newbuf->width, $newbuf->height );
            for my $i ( $old_h .. $newbuf->height - 1 ) {
                $curbuf->{lines}[$i] = $newbuf->{lines}[$i] if defined $newbuf->{lines}[$i];
            }
        }
        $self->_update_pen(undef);
        if ( length $buf > 1 && $opts->{show_cursor} && !$cursor_hidden && $queued_text ) {
            $buf = HideCursor() . $buf . ShowCursor();
        }
        $queued_text = 0;
    }

    method flush () {
        $self->render;
        if ( length $buf > 0 ) {
            if   ( ref $writer && $writer->can('print') ) { $writer->print($buf) }
            else                                          { print {$writer} $buf }
            $buf = '';
        }
    }

    method close () {
        $self->render;
        $self->_update_pen(undef);
        $self->_move( 0, $newbuf->height - 1 );
        if ($alt_screen_mode) { $buf .= reset_mode(ModeAltScreenSaveCursor); $alt_screen_mode = 0 }
        if ($cursor_hidden)   { $buf .= ShowCursor();                        $cursor_hidden   = 0 }
        $self->flush;
        $self->_reset;
    }
    method move_to ( $x, $y ) { $self->_move( $x, $y ) }

    method insert_above ($str) {
        return if $opts->{alt_screen};
        for my $line ( split /\n/, $str ) {
            my $w = $self->width;
            $line = substr( $line, 0, $w ) if length($line) > $w;
            push @$queue_above, $line;
        }
    }

    method _reset () {
        $scroll_height   = 0;
        $cursor_hidden   = 0;
        $alt_screen_mode = 0;
        $touch           = {};
        $curbuf->clear if $curbuf;
        $newbuf->clear if $newbuf;
        $buf               = '';
        $tabs              = Cancer::CellBuf::TabStops->default( $newbuf->width ) if $newbuf;
        $oldhash           = [];
        $newhash           = [];
        $caps              = _xterm_caps( $opts->{term} ) if $opts->{term} =~ /^linux/;
        $opts->{hard_tabs} = 0                            if $opts->{term} =~ /^linux/;
    }

    method _needs_render () {
        return 0 if $opts->{alt_screen} == $alt_screen_mode && ( !$opts->{show_cursor} ) == $cursor_hidden && !$clear && !%$touch && !@$queue_above;
        return 1;
    }

    method _clear_blank () {
        my $c = Cancer::CellBuf::Cell->BlankCell->clone;
        if ( !$cur_style->empty || !$cur_link->empty ) {
            $c->set_style( $cur_style->clone );
            $c->set_link( $cur_link->clone );
        }
        return $c;
    }

    method _update_pen ($cell) {
        $cell //= Cancer::CellBuf::Cell->BlankCell;
        my $style = $cell->style // Cancer::CellBuf::Style->new;
        my $link  = $cell->link  // Cancer::CellBuf::Link->new;
        if ( !$style->equal($cur_style) ) {
            my $seq = $style->diff_sequence($cur_style);
            $seq = ResetStyle() if $style->empty && length($seq) > length( ResetStyle() );
            $buf .= $seq;
            $cur_style = $style->clone;
        }
        if ( !$link->equal($cur_link) ) {
            $buf .= set_hyperlink( $link->url, $link->params );
            $cur_link = $link->clone;
        }
    }

    method _move ( $x, $y ) {
        my $w = _max( $newbuf->width,  $curbuf->width );
        my $h = _max( $newbuf->height, $curbuf->height );
        if ( $w > 0 && $x >= $w ) { $y += int( $x / $w ); $x %= $w }
        $y = $h - 1 if $h > 0 && $y > $h - 1;
        $y = 0      if $y < 0;
        $x = 0      if $x < 0;
        return if $x == $cur_x && $y == $cur_y;
        $self->_move_cursor( $x, $y, 1 );
    }

    method _move_cursor ( $x, $y, $overwrite ) {
        if ( !$opts->{alt_screen} && $cur_x == -1 && $cur_y == -1 ) {
            $buf .= "\r";
            $cur_x = 0;
            $cur_y = 0;
        }
        my $seq = _relative_cursor_move( $self, $cur_x, $cur_y, $x, $y, $overwrite );
        $buf .= $seq;
        $cur_x = $x;
        $cur_y = $y;
    }

    method _relative_cursor_move ( $fx, $fy, $tx, $ty, $overwrite ) {
        my $seq = '';
        if ( $ty != $fy ) {
            my $yseq = '';
            if ( $ty > $fy ) {
                my $n = $ty - $fy;
                $yseq = CursorDown($n);
                my $should_scroll = !$opts->{alt_screen} && $fy + $n >= $scroll_height;
                my $lf            = "\n" x $n;
                if ( $should_scroll || ( $fy + $n < $newbuf->height && length($lf) < length($yseq) ) ) {
                    $yseq          = $lf;
                    $scroll_height = _max( $scroll_height, $fy + $n );
                    $fx            = 0 if $opts->{map_nl};
                }
            }
            elsif ( $ty < $fy ) {
                my $n = $fy - $ty;
                $yseq = CursorUp($n);
                $yseq = ReverseIndex() if $n == 1 && $fy - 1 > 0;
            }
            $seq .= $yseq;
        }
        if ( $tx != $fx ) {
            my $xseq = '';
            if ( $tx > $fx ) {
                my $n = $tx - $fx;
                $xseq = CursorForward($n);
                if ( $overwrite && $ty >= 0 ) {
                    my $ovw           = '';
                    my $can_overwrite = 1;
                    for my $i ( 0 .. $n - 1 ) {
                        my $cell = $newbuf->cell( $fx + $i, $ty );
                        if ( defined $cell && $cell->width > 0 ) {
                            $i += $cell->width - 1;
                            if ( !_style_equal( $cell->style, $cur_style ) || !_link_equal( $cell->link, $cur_link ) ) {
                                $can_overwrite = 0;
                                last;
                            }
                        }
                    }
                    if ( $can_overwrite && $ty >= 0 ) {
                        for my $i ( 0 .. $n - 1 ) {
                            my $cell = $newbuf->cell( $fx + $i, $ty );
                            if ( defined $cell && $cell->width > 0 ) {
                                $ovw .= $cell->string;
                                $i += $cell->width - 1;
                            }
                            else { $ovw .= ' ' }
                        }
                        $xseq = $ovw if length($ovw) < length($xseq);
                    }
                }
            }
            elsif ( $tx < $fx ) {
                my $n = $fx - $tx;
                $xseq = CursorBackward($n);
                $xseq = "\b" x $n if $opts->{backspace} && $n < length($xseq);
            }
            $seq .= $xseq;
        }
        return $seq;
    }

    method _clear_to_end ( $blank, $force ) {
        if ( $cur_y >= 0 ) {
            my $curline = $curbuf->line($cur_y);
            if ($curline) {
                for my $j ( $cur_x .. $curbuf->width - 1 ) {
                    if ( $j >= 0 ) {
                        my $c = $curline->at($j);
                        if ( !_cell_equal( $c, $blank ) ) { $curline->set( $j, $blank ); $force = 1 }
                    }
                }
            }
        }
        if ($force) { $self->_update_pen($blank); $buf .= EraseLineRight() }
    }

    method _clear_to_bottom ($blank) {
        my $row = $cur_y;
        $row = 0 if $row < 0;
        $self->_update_pen($blank);
        $buf .= EraseScreenBelow();
        $curbuf->clear_rect( Rect( $cur_x, $row,     $curbuf->width - $cur_x, 1 ) );
        $curbuf->clear_rect( Rect( 0,      $row + 1, $curbuf->width,          $curbuf->height - $row - 1 ) );
    }
    method _clear_below ( $blank, $row ) { $self->_move( 0, $row ); $self->_clear_to_bottom($blank) }

    method _clear_screen ($blank) {
        $self->_update_pen($blank);
        $buf .= CursorHomePosition() . EraseEntireScreen();
        $cur_x = 0;
        $cur_y = 0;
        $curbuf->fill($blank);
    }

    method _clear_bottom ($total) {
        return 0 if $total <= 0;
        my $top       = $total;
        my $blank     = $self->_clear_blank;
        my $can_clear = !$blank || $blank->clear;
        if ($can_clear) {
            for my $row ( reverse 0 .. $total - 1 ) {
                my $old_line = $curbuf->line($row);
                my $new_line = $newbuf->line($row);
                my $ok       = 1;
                for my $col ( 0 .. $newbuf->width - 1 ) { $ok = _cell_equal( $new_line->at($col), $blank ); last unless $ok }
                last unless $ok;
                for my $col ( 0 .. $newbuf->width - 1 ) { $ok = _cell_equal( $old_line->at($col), $blank ); last unless $ok }
                $top = $row if !$ok;
            }
            if ( $top < $total ) {
                $self->_move( 0, $top - 1 );
                $self->_clear_to_bottom($blank);
                if ( @$oldhash && @$newhash ) {
                    for my $row ( $top .. $newbuf->height - 1 ) {
                        $oldhash->[$row] = $newhash->[$row] if defined $newhash->[$row];
                    }
                }
            }
        }
        return $top;
    }

    method _clear_update () {
        my $blank = $self->_clear_blank;
        my $non_empty;
        if ( $opts->{alt_screen} ) {
            $non_empty = _max( $curbuf->height, $newbuf->height );
            $self->_clear_screen($blank);
        }
        else {
            $non_empty = $newbuf->height;
            $self->_clear_below( $blank, 0 );
        }
        $non_empty = $self->_clear_bottom($non_empty);
        $self->_transform_line($_) for 0 .. $non_empty - 1;
    }

    method _transform_line ($y) {
        my $old_line = $curbuf->line($y);
        my $new_line = $newbuf->line($y);
        return unless $old_line && $new_line;
        my $first_cell   = 0;
        my $line_changed = 0;
        for my $i ( 0 .. $newbuf->width - 1 ) {
            if ( !_cell_equal( $new_line->at($i), $old_line->at($i) ) ) { $line_changed = 1; last }
            $first_cell++;
        }
        return unless $line_changed;
        my $last_cell = $newbuf->width - 1;
        while ( $last_cell > $first_cell && _cell_equal( $new_line->at($last_cell), $old_line->at($last_cell) ) ) {
            $last_cell--;
        }
        if ( $last_cell >= $first_cell ) {
            $self->_move( $first_cell, $y );
            $self->_put_range( $old_line, $new_line, $y, $first_cell, $last_cell );
            for my $i ( $first_cell .. $last_cell ) { $old_line->set( $i, $new_line->at($i) ) }
        }
    }

    method _put_range ( $old_line, $new_line, $y, $start, $end ) {
        for my $j ( $start .. $end ) {
            if ( !_cell_equal( $old_line->at($j), $new_line->at($j) ) ) {
                $self->_put_cell( $new_line->at($j) );
            }
            else {
                $self->_move( $j, $y ) if $j != $cur_x;
            }
        }
    }

    method _put_cell ($cell) {
        if ( $opts->{alt_screen} && $cur_x == $newbuf->width - 1 && $cur_y == $newbuf->height - 1 ) {
            $self->_put_cell_lr($cell);
        }
        else {
            $self->_put_attr_cell($cell);
        }
    }

    method _put_attr_cell ($cell) {
        return if defined $cell && $cell->empty;
        $cell = $self->_clear_blank unless defined $cell;
        if ($at_phantom) { $cur_x = 0; $cur_y++; $at_phantom = 0 }
        $self->_update_pen($cell);
        $buf .= $cell->string;
        $cur_x += $cell->width;
        $queued_text = 1 if $cell->width > 0;
        $at_phantom  = 1 if $cur_x >= $newbuf->width;
    }

    method _put_cell_lr ($cell) {
        my $saved_cur_x = $cur_x;
        if ( !defined $cell || !$cell->empty ) {
            $buf .= reset_mode(ModeAutoWrap);
            $self->_put_attr_cell($cell);
            $at_phantom = 0;
            $cur_x      = $saved_cur_x;
            $buf .= set_mode(ModeAutoWrap);
        }
    }
    use constant newIndex => -1;

    method _hash ($line) {
        my $h = 0;
        for my $i ( 0 .. $newbuf->width - 1 ) {
            my $c = $line                      ? $line->at($i) : undef;
            my $r = ( defined $c && $c->rune ) ? $c->rune      : ord(' ');
            $h += ( $h << 5 ) + $r;
        }
        return $h;
    }

    method _update_hashmap () {
        my $height = $newbuf->height;
        if ( @$oldhash >= $height && @$newhash >= $height ) {
            for my $i ( 0 .. $height - 1 ) {
                if ( exists $touch->{$i} ) {
                    $oldhash->[$i] = $self->_hash( $curbuf->line($i) );
                    $newhash->[$i] = $self->_hash( $newbuf->line($i) );
                }
            }
        }
        else {
            $oldhash = [];
            $newhash = [];
            for my $i ( 0 .. $height - 1 ) {
                $oldhash->[$i] = $self->_hash( $curbuf->line($i) );
                $newhash->[$i] = $self->_hash( $newbuf->line($i) );
            }
        }
        my @hashtab;
        for my $i ( 0 .. $height - 1 ) {
            my $hv  = $oldhash->[$i];
            my $idx = 0;
            while ( $idx < @hashtab && $hashtab[$idx]{value} != $hv ) { $idx++ }
            if ( $idx >= @hashtab ) {
                $hashtab[$idx] = { value => $hv, oldcount => 0, newcount => 0, oldindex => 0, newindex => 0 };
            }
            $hashtab[$idx]{value} = $hv;
            $hashtab[$idx]{oldcount}++;
            $hashtab[$idx]{oldindex} = $i;
        }
        for my $i ( 0 .. $height - 1 ) {
            my $hv  = $newhash->[$i];
            my $idx = 0;
            while ( $idx < @hashtab && $hashtab[$idx]{value} != $hv ) { $idx++ }
            if ( $idx >= @hashtab ) {
                $hashtab[$idx] = { value => $hv, oldcount => 0, newcount => 0, oldindex => 0, newindex => 0 };
            }
            $hashtab[$idx]{value} = $hv;
            $hashtab[$idx]{newcount}++;
            $hashtab[$idx]{newindex} = $i;
            $oldnum->[$i] = newIndex;
        }
        $hashtab = \@hashtab;
        for my $hsp (@$hashtab) {
            next unless $hsp->{oldcount} == 1 && $hsp->{newcount} == 1 && $hsp->{oldindex} != $hsp->{newindex};
            $oldnum->[ $hsp->{newindex} ] = $hsp->{oldindex};
        }
        $self->_grow_hunks;
        my $i = 0;
        while ( $i < $height ) {
            while ( $i < $height && $oldnum->[$i] == newIndex ) { $i++ }
            last if $i >= $height;
            my $start = $i;
            my $shift = $oldnum->[$i] - $i;
            $i++;
            while ( $i < $height && $oldnum->[$i] != newIndex && $oldnum->[$i] - $i == $shift ) { $i++ }
            my $size = $i - $start;
            if ( $size < 3 || $size + _min( int( $size / 8 ), 2 ) < abs($shift) ) {
                $oldnum->[$_] = newIndex for $start .. $i - 1;
            }
        }
        $self->_grow_hunks;
    }

    method _grow_hunks () {
        my $height = $newbuf->height;
        my ( $back_limit, $back_ref_limit ) = ( 0, 0 );
        my $i = 0;
        while ( $i < $height && $oldnum->[$i] == newIndex ) { $i++ }
        while ( $i < $height ) {
            my $start = $i;
            my $shift = $oldnum->[$i] - $i;
            $i = $start + 1;
            while ( $i < $height && $oldnum->[$i] != newIndex && $oldnum->[$i] - $i == $shift ) { $i++ }
            my $end = $i;
            while ( $i < $height && $oldnum->[$i] == newIndex ) { $i++ }
            my $next_hunk     = $i;
            my $forward_limit = $i;
            my $forward_ref_limit;
            if   ( $i >= $height || $oldnum->[$i] >= $i ) { $forward_ref_limit = $i }
            else                                          { $forward_ref_limit = $oldnum->[$i] }
            $i          = $start - 1;
            $back_limit = $back_ref_limit + abs($shift) if $shift < 0;

            while ( $i >= $back_limit ) {
                if ( $newhash->[$i] == $oldhash->[ $i + $shift ] || $self->_cost_effective( $i + $shift, $i, $shift < 0 ) ) {
                    $oldnum->[$i] = $i + $shift;
                }
                else {last}
                $i--;
            }
            $i             = $end;
            $forward_limit = $forward_ref_limit - $shift if $shift > 0;
            while ( $i < $forward_limit ) {
                if ( $newhash->[$i] == $oldhash->[ $i + $shift ] || $self->_cost_effective( $i + $shift, $i, $shift > 0 ) ) {
                    $oldnum->[$i] = $i + $shift;
                }
                else {last}
                $i++;
            }
            $back_limit     = $i;
            $back_ref_limit = $back_limit;
            $back_ref_limit += $shift if $shift > 0;
            $i = $next_hunk;
        }
    }

    method _cost_effective ( $from, $to, $blank ) {
        return 0 if $from == $to;
        my $new_from = $oldnum->[$from];
        $new_from = $from if $new_from == newIndex;
        my $cost_before;
        if   ($blank) { $cost_before = $self->_update_cost_blank( $newbuf->line($to) ) }
        else          { $cost_before = $self->_update_cost( $curbuf->line($to), $newbuf->line($to) ) }
        $cost_before += $self->_update_cost( $curbuf->line($new_from), $newbuf->line($from) );
        my $cost_after;
        if   ( $new_from == $from ) { $cost_after = $self->_update_cost_blank( $newbuf->line($from) ) }
        else                        { $cost_after = $self->_update_cost( $curbuf->line($new_from), $newbuf->line($from) ) }
        $cost_after += $self->_update_cost( $newbuf->line($from), $newbuf->line($to) );
        return $cost_before >= $cost_after;
    }

    method _update_cost ( $from_line, $to_line ) {
        my $cost = 0;
        for my $i ( 0 .. $newbuf->width - 1 ) {
            my $fc = $from_line ? $from_line->at($i) : undef;
            my $tc = $to_line   ? $to_line->at($i)   : undef;
            $cost++ unless _cell_equal( $fc, $tc );
        }
        return $cost;
    }

    method _update_cost_blank ($to_line) {
        my $cost = 0;
        for my $i ( 0 .. $newbuf->width - 1 ) {
            my $tc = $to_line ? $to_line->at($i) : undef;
            $cost++ unless _cell_equal( undef, $tc );
        }
        return $cost;
    }

    method _scroll_oldhash ( $n, $top, $bot ) {
        return unless @$oldhash;
        my $size = $bot - $top + 1 - abs($n);
        if ( $n > 0 ) {
            for my $i ( 0 .. $size - 1 ) { $oldhash->[ $top + $i ] = $oldhash->[ $top + $n + $i ] }
            for my $i ( reverse( $bot - $n + 1 .. $bot ) ) { $oldhash->[$i] = $self->_hash( $curbuf->line($i) ) }
        }
        elsif ( $n < 0 ) {
            my $an = abs($n);
            for my $i ( reverse( 0 .. $size - 1 ) ) { $oldhash->[ $top + $an + $i ] = $oldhash->[ $top + $i ] }
            for my $i ( $top .. $top + $an - 1 ) { $oldhash->[$i] = $self->_hash( $curbuf->line($i) ) }
        }
    }

    method _scroll_optimize () {
        my $height = $newbuf->height;
        $oldnum = [] unless $oldnum && @$oldnum >= $height;
        $self->_update_hashmap;
        return if @$hashtab < $height;
        my $i = 0;
        while ( $i < $height ) {
            while ( $i < $height && ( $oldnum->[$i] == newIndex || $oldnum->[$i] <= $i ) ) { $i++ }
            last if $i >= $height;
            my $shift = $oldnum->[$i] - $i;
            my $start = $i;
            $i++;
            while ( $i < $height && $oldnum->[$i] != newIndex && $oldnum->[$i] - $i == $shift ) { $i++ }
            $self->_scrolln( $shift, $start, $i - 1 + $shift, $height - 1 );
        }
        $i = $height - 1;
        while ( $i >= 0 ) {
            while ( $i >= 0 && ( $oldnum->[$i] == newIndex || $oldnum->[$i] >= $i ) ) { $i-- }
            last if $i < 0;
            my $shift = $oldnum->[$i] - $i;
            my $end   = $i;
            $i--;
            while ( $i >= 0 && $oldnum->[$i] != newIndex && $oldnum->[$i] - $i == $shift ) { $i-- }
            $self->_scrolln( $shift, $i + 1 - abs($shift), $end, $height - 1 );
        }
    }

    method _scrolln ( $n, $top, $bot, $max_y ) {
        my $blank = $self->_clear_blank;
        if ( $n > 0 ) {
            my $v = $self->_scroll_up( $n, $top, $bot, 0, $max_y, $blank );
            if ( !$v ) {
                $buf .= SetTopBottomMargins( $top + 1, $bot + 1 );
                ( $cur_x, $cur_y ) = ( -1, -1 );
                $v = $self->_scroll_up( $n, $top, $bot, $top, $bot, $blank );
                $buf .= SetTopBottomMargins( 1, $max_y + 1 );
                ( $cur_x, $cur_y ) = ( -1, -1 );
            }
            $v = $self->_scroll_idl( $n, $top, $bot - $n + 1, $blank ) unless $v;
            if ($v) { $self->_scroll_buffer( $curbuf, $n, $top, $bot, $blank ); $self->_scroll_oldhash( $n, $top, $bot ) }
        }
        elsif ( $n < 0 ) {
            my $an = abs($n);
            my $v  = $self->_scroll_down( $an, $top, $bot, 0, $max_y, $blank );
            if ( !$v ) {
                $buf .= SetTopBottomMargins( $top + 1, $bot + 1 );
                ( $cur_x, $cur_y ) = ( -1, -1 );
                $v = $self->_scroll_down( $an, $top, $bot, $top, $bot, $blank );
                $buf .= SetTopBottomMargins( 1, $max_y + 1 );
                ( $cur_x, $cur_y ) = ( -1, -1 );
            }
            $v = $self->_scroll_idl( $an, $bot + $n + 1, $top, $blank ) unless $v;
            if ($v) { $self->_scroll_buffer( $curbuf, $n, $top, $bot, $blank ); $self->_scroll_oldhash( $n, $top, $bot ) }
        }
        return 1;
    }

    method _scroll_up ( $n, $top, $bot, $min_y, $max_y, $blank ) {
        if ( $n == 1 && $top == $min_y && $bot == $max_y ) {
            $self->_move( 0, $bot );
            $self->_update_pen($blank);
            $buf .= "\n";
        }
        elsif ( $n == 1 && $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $buf .= DeleteLine(1);
        }
        elsif ( $top == $min_y && $bot == $max_y ) {
            $self->_move( 0, ( $caps & CAP_SU ) ? $bot : $top );
            $self->_update_pen($blank);
            $buf .= ( $caps & CAP_SU ) ? ScrollUp($n) : ( "\n" x $n );
        }
        elsif ( $bot == $max_y ) {
            $self->_move( 0, $top );
            $self->_update_pen($blank);
            $buf .= DeleteLine($n);
        }
        else { return 0 }
        return 1;
    }

    method _scroll_down ( $n, $top, $bot, $min_y, $max_y, $blank ) {
        $self->_move( 0, $top );
        $self->_update_pen($blank);
        if ( $n == 1 && $top == $min_y && $bot == $max_y ) {
            $buf .= ReverseIndex();
        }
        elsif ( $n == 1 && $bot == $max_y ) {
            $buf .= InsertLine(1);
        }
        elsif ( $top == $min_y && $bot == $max_y ) {
            $buf .= ( $caps & CAP_SD ) ? ScrollDown($n) : ( ReverseIndex() x $n );
        }
        elsif ( $bot == $max_y ) {
            $buf .= InsertLine($n);
        }
        else { return 0 }
        return 1;
    }

    method _scroll_idl ( $n, $del, $ins, $blank ) {
        return 0 if $n < 0;
        $self->_move( 0, $del );
        $self->_update_pen($blank);
        $buf .= DeleteLine($n);
        $self->_move( 0, $ins );
        $self->_update_pen($blank);
        $buf .= InsertLine($n);
        return 1;
    }

    method _scroll_buffer ( $buf_obj, $n, $top, $bot, $blank ) {
        return if $top < 0 || $bot < $top || $bot >= $buf_obj->height;
        if ( $n < 0 ) {
            my $limit = $top - abs($n);
            for my $line ( reverse $limit .. $bot ) { $buf_obj->{lines}[$line] = $buf_obj->{lines}[ $line + $n ] }
            for my $line ( $top .. $limit - 1 )     { $buf_obj->fill_rect( $blank, Rect( 0, $line, $buf_obj->width, 1 ) ) }
        }
        elsif ( $n > 0 ) {
            my $limit = $bot - $n;
            for my $line ( $top .. $limit )                { $buf_obj->{lines}[$line] = $buf_obj->{lines}[ $line + $n ] }
            for my $line ( reverse( $limit + 1 .. $bot ) ) { $buf_obj->fill_rect( $blank, Rect( 0, $line, $buf_obj->width, 1 ) ) }
        }
        $self->_touch_line( $buf_obj->width, $buf_obj->height, $top, $bot - $top + 1, 1 );
    }

    method _touch_line ( $tw, $th, $y, $n, $changed ) {
        return if $n < 0 || $y < 0 || $y >= $th;
        for my $i ( $y .. _min( $y + $n - 1, $th - 1 ) ) {
            if ($changed) { $touch->{$i} = { first_cell => 0, last_cell => $tw - 1 } }
            else          { delete $touch->{$i} }
        }
    }

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
        return [ 80, 24 ];
    }
} 1;
