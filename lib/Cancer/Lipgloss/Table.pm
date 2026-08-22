use v5.42;

package Cancer::Lipgloss::Table v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[NewTable DefaultStyles HEADER_ROW];

    use Cancer::Lipgloss qw[
        NewStyle string_width width height
        JoinHorizontal JoinVertical Left Top
        NormalBorder
    ];
    use Cancer::Ansi ();
    use utf8;

    use constant HEADER_ROW => -1;

    # ── StringData ──────────────────────────────────────────────────────

    package Cancer::Lipgloss::Table::StringData {
        sub new {
            my ( $class, @rows ) = @_;
            my $cols = 0;
            for my $row (@rows) {
                $cols = @$row if @$row > $cols;
            }
            return bless { rows => \@rows, columns => $cols }, $class;
        }

        sub At {
            my ( $self, $row, $cell ) = @_;
            return '' if $row >= @{ $self->{rows} };
            return '' if $cell >= @{ $self->{rows}[$row] };
            return $self->{rows}[$row][$cell];
        }

        sub Rows     { return scalar @{ $_[0]->{rows} } }
        sub Columns  { return $_[0]->{columns} }

        sub Append {
            my ( $self, $row ) = @_;
            $self->{columns} = @$row if @$row > $self->{columns};
            push @{ $self->{rows} }, $row;
        }

        sub Item { $_[0]->Append( [@_[ 1 .. $#_ ] ] ) }
    }

    # ── Default styles ─────────────────────────────────────────────────

    sub DefaultStyles { return NewStyle() }

    # ── Table ──────────────────────────────────────────────────────────

    sub new_table {
        my %args = @_;
        return bless {
            baseStyle   => undef,
            styleFunc   => \&DefaultStyles,
            border      => NormalBorder(),
            borderTop   => 1,
            borderBottom => 1,
            borderLeft  => 1,
            borderRight => 1,
            borderHeader => 1,
            borderColumn => 1,
            borderRow   => 0,
            borderStyle => undef,
            headers     => [],
            data        => Cancer::Lipgloss::Table::StringData->new(),
            width       => 0,
            height      => 0,
            useManualHeight => 0,
            yOffset     => 0,
            wrap        => 1,
            widths      => [],
            heights     => [],
            firstVisibleRowIndex => 0,
            lastVisibleRowIndex  => -2,
            overflowHeight => 0,
        }, 'Cancer::Lipgloss::Table';
    }

    sub NewTable { new_table(@_) }

    # Builder methods
    sub Headers {
        my ( $self, @headers ) = @_;
        $self->{headers} = [@headers];
        return $self;
    }

    sub Row {
        my ( $self, @row ) = @_;
        $self->{data}->Append( [@row] );
        return $self;
    }

    sub Rows {
        my ( $self, @rows ) = @_;
        for my $row (@rows) {
            $self->{data}->Append( [@$row] );
        }
        return $self;
    }

    sub Data {
        my ( $self, $data ) = @_;
        $self->{data} = $data;
        return $self;
    }

    sub ClearRows {
        my $self = shift;
        $self->{data} = Cancer::Lipgloss::Table::StringData->new();
        return $self;
    }

    sub StyleFunc {
        my ( $self, $fn ) = @_;
        $self->{styleFunc} = $fn;
        return $self;
    }

    sub BaseStyle {
        my ( $self, $style ) = @_;
        $self->{baseStyle} = $style;
        $self->{borderStyle} //= NewStyle();
        return $self;
    }

    sub Border {
        my ( $self, $border ) = @_;
        $self->{border} = $border;
        return $self;
    }

    sub BorderTop     { $_[0]->{borderTop}    = $_[1]; return $_[0] }
    sub BorderBottom  { $_[0]->{borderBottom} = $_[1]; return $_[0] }
    sub BorderLeft    { $_[0]->{borderLeft}   = $_[1]; return $_[0] }
    sub BorderRight   { $_[0]->{borderRight}  = $_[1]; return $_[0] }
    sub BorderHeader  { $_[0]->{borderHeader} = $_[1]; return $_[0] }
    sub BorderColumn  { $_[0]->{borderColumn} = $_[1]; return $_[0] }
    sub BorderRow     { $_[0]->{borderRow}    = $_[1]; return $_[0] }

    sub BorderStyle {
        my ( $self, $style ) = @_;
        $self->{borderStyle} = $style;
        return $self;
    }

    sub Width  { $_[0]->{width} = $_[1]; return $_[0] }
    sub Height { $_[0]->{height} = $_[1]; $_[0]->{useManualHeight} = 1; return $_[0] }
    sub Wrap   { $_[0]->{wrap} = $_[1]; return $_[0] }

    sub YOffset {
        my ( $self, $o ) = @_;
        $self->{yOffset} = $o;
        return $self;
    }

    # Getters
    sub GetData          { return $_[0]->{data} }
    sub GetHeaders       { return $_[0]->{headers} }
    sub GetBorderTop     { return $_[0]->{borderTop} }
    sub GetBorderBottom  { return $_[0]->{borderBottom} }
    sub GetBorderLeft    { return $_[0]->{borderLeft} }
    sub GetBorderRight   { return $_[0]->{borderRight} }
    sub GetBorderHeader  { return $_[0]->{borderHeader} }
    sub GetBorderColumn  { return $_[0]->{borderColumn} }
    sub GetBorderRow     { return $_[0]->{borderRow} }
    sub GetHeight        { return $_[0]->{height} }
    sub GetYOffset       { return $_[0]->{yOffset} }

    sub FirstVisibleRowIndex { return $_[0]->{firstVisibleRowIndex} }
    sub LastVisibleRowIndex  { return $_[0]->{lastVisibleRowIndex} }

    sub VisibleRows {
        my $self = shift;
        if ( $self->{lastVisibleRowIndex} == -2 ) {
            return $self->{data}->Rows - $self->{firstVisibleRowIndex};
        }
        return $self->{lastVisibleRowIndex} - $self->{firstVisibleRowIndex} + 1;
    }

    # ── Style helper ───────────────────────────────────────────────────

    sub _style {
        my ( $self, $row, $col ) = @_;
        my $s = $self->{styleFunc}->( $row, $col );
        $s = $s->inherit( $self->{baseStyle} ) if $self->{baseStyle};
        return $s;
    }

    # ── Resize ─────────────────────────────────────────────────────────

    sub _resize {
        my $self = shift;
        my $has_headers = @{ $self->{headers} } > 0;

        # Convert data to matrix
        my @all_rows;
        my $num_rows = $self->{data}->Rows;
        my $num_cols = $self->{data}->Columns;
        for my $r ( 0 .. $num_rows - 1 ) {
            my @row;
            for my $c ( 0 .. $num_cols - 1 ) {
                push @row, $self->{data}->At( $r, $c );
            }
            push @all_rows, \@row;
        }

        my @headers = @{ $self->{headers} };
        my @all;
        if ($has_headers) {
            push @all, [@headers];
        }
        push @all, @all_rows;

        # Phase 1: Compute max content width per column, track xPadding and fixedWidth
        my @col_widths;
        my @x_paddings;
        my @fixed_widths;
        for my $j ( 0 .. $num_cols - 1 ) {
            $col_widths[$j]   = 0;
            $x_paddings[$j]   = 0;
            $fixed_widths[$j] = 0;
        }

        for my $i ( 0 .. $#all ) {
            for my $j ( 0 .. $num_cols - 1 ) {
                my $cell = $all[$i][$j] // '';
                my $cw   = width($cell);
                $col_widths[$j] = $cw if $cw > $col_widths[$j];

                my $row_idx = $i;
                $row_idx-- if $has_headers;
                my $style = $self->{styleFunc}->( $row_idx, $j );
                my $fp = $style->get_horizontal_frame_size;
                $x_paddings[$j] = $fp if $fp > $x_paddings[$j];
                my $fw = $style->get_width || 0;
                $fixed_widths[$j] = $fw if $fw > $fixed_widths[$j];
            }
        }

        # Phase 2: Compute maxColumnWidths (Go resizing.go:367-377)
        for my $j ( 0 .. $num_cols - 1 ) {
            if ( $fixed_widths[$j] > 0 ) {
                $col_widths[$j] = $fixed_widths[$j];
            }
            else {
                $col_widths[$j] += $x_paddings[$j];
            }
        }

        # Phase 3: Expand or shrink to fit table width
        my $border_h = $self->_total_horizontal_border;
        if ( $self->{width} > 0 ) {
            my $total = _sum(\@col_widths) + $border_h;
            if ( $total < $self->{width} ) {
                # Expand: distribute extra space to shortest non-fixed columns
                my $extra = $self->{width} - $total;
                for my $k ( 1 .. $extra ) {
                    my $min_w = 999999;
                    my $min_j = 0;
                    for my $j ( 0 .. $num_cols - 1 ) {
                        next if $fixed_widths[$j] > 0 && $col_widths[$j] == $fixed_widths[$j];
                        if ( $col_widths[$j] < $min_w ) {
                            $min_w = $col_widths[$j];
                            $min_j = $j;
                        }
                    }
                    $col_widths[$min_j]++;
                }
            }
            elsif ( $total > $self->{width} ) {
                # Shrink: reduce columns with biggest diff above minWidth
                for my $pass ( 1 .. 2 ) {
                    my $use_floor = ( $pass == 1 );
                    while ( (_sum(\@col_widths) + $border_h) > $self->{width} ) {
                        my $max_diff = -999999;
                        my $max_j    = -1;
                        for my $j ( 0 .. $num_cols - 1 ) {
                            next if $fixed_widths[$j] > 0 && $col_widths[$j] == $fixed_widths[$j];
                            my $floor = $x_paddings[$j] + ( $fixed_widths[$j] > 0 ? $fixed_widths[$j] : ( $use_floor ? 1 : 0 ) );
                            if ( $use_floor && $col_widths[$j] <= $floor ) {
                                next;
                            }
                            my $diff = $col_widths[$j] - ( $fixed_widths[$j] > 0 ? $fixed_widths[$j] : $col_widths[$j] );
                            if ( $pass == 2 ) {
                                # shrinkToMedian: use content width diff
                                $diff = $col_widths[$j] - $x_paddings[$j];
                            }
                            if ( $diff > $max_diff ) {
                                $max_diff = $diff;
                                $max_j    = $j;
                            }
                        }
                        last if $max_j < 0;
                        $col_widths[$max_j]--;
                    }
                }
            }
        }

        $self->{widths} = \@col_widths;

        # Compute row heights
        my @row_heights;
        for my $i ( 0 .. $#all ) {
            my $max_h = 1;
            for my $j ( 0 .. $num_cols - 1 ) {
                my $cell = $all[$i][$j] // '';
                my $cw = $col_widths[$j] - $x_paddings[$j];
                $cw = 1 if $cw < 1;
                my $ch = 1;
                if ( $self->{wrap} && !( $has_headers && $i == 0 ) ) {
                    my $wrapped = Cancer::Ansi::Wrap( $cell, $cw, '' );
                    $ch = height($wrapped);
                }
                my $row_idx = $i;
                $row_idx-- if $has_headers;
                my $style = $self->{styleFunc}->( $row_idx, $j );
                my $ypad = $style->get_vertical_frame_size;
                $ch += $ypad;
                $max_h = $ch if $ch > $max_h;
            }
            $row_heights[$i] = $max_h;
        }

        $self->{heights} = \@row_heights;

        # Compute visible rows for manual height
        $self->{firstVisibleRowIndex} = 0;
        $self->{lastVisibleRowIndex}  = -2;
        $self->{overflowHeight}       = 0;

        if ( $self->{useManualHeight} && $self->{height} > 0 ) {
            my $available = $self->{height};
            $available-- if $self->{borderTop};
            $available-- if $self->{borderBottom};
            if ($has_headers) {
                $available -= $row_heights[0];
                $available-- if $self->{borderHeader};
            }
            $available++ if $self->{borderRow};

            my $first = $self->{yOffset};
            my $last = $first - 1;

            while ( $available > 0 && $last < $num_rows - 1 ) {
                my $next = $last + 1 + ( $has_headers ? 1 : 0 );
                my $rh = $row_heights[$next];
                $rh += 1 if $self->{borderRow};
                last if $available - $rh < 0;
                $last++;
                $available -= $rh;
            }

            $self->{firstVisibleRowIndex} = $first;
            if ( $last >= $num_rows - 1 ) {
                $self->{lastVisibleRowIndex} = -2;
            }
            else {
                $self->{lastVisibleRowIndex} = $last;
                $self->{overflowHeight} = 1;
            }
        }
    }

    sub _total_horizontal_border {
        my $self = shift;
        my $n = 0;
        $n++ if $self->{borderLeft};
        $n++ if $self->{borderRight};
        my $num_cols = $self->{data}->Columns;
        $n += ( $num_cols - 1 ) if $self->{borderColumn};
        return $n;
    }

    sub _sum {
        my $arr = shift;
        my $s = 0;
        $s += $_ for @$arr;
        return $s;
    }

    # ── Render ─────────────────────────────────────────────────────────

    sub String {
        my $self = shift;
        my $has_headers = @{ $self->{headers} } > 0;
        my $has_rows    = $self->{data} && $self->{data}->Rows > 0;

        return '' unless $has_headers || $has_rows;

        # Pad headers to match column count
        if ($has_headers) {
            while ( @{ $self->{headers} } < $self->{data}->Columns ) {
                push @{ $self->{headers} }, '';
            }
        }

        $self->_resize;

        my $bs = $self->{borderStyle} // NewStyle();
        my $b  = $self->{border};
        my @out;

        # Top border
        if ( $self->{borderTop} ) {
            push @out, $self->_render_border_line(
                $b->{top_left}, $b->{top}, $b->{middle_top},
                $b->{top_right}
            );
        }

        # Headers
        push @out, $self->_render_headers if $has_headers;

        # Data rows
        my $num_rows = $self->{data}->Rows;
        if ($num_rows > 0) {
            my $first = $self->{firstVisibleRowIndex};
            my $last  = $self->{lastVisibleRowIndex};
            $last = $num_rows - 1 if $last == -2;

            for my $r ( $first .. $last ) {
                push @out, $self->_render_row( $r, 0 );
            }

            # Overflow row
            if ( $self->{lastVisibleRowIndex} != -2 ) {
                push @out, $self->_render_row( $self->{lastVisibleRowIndex} + 1, 1 );
            }
        }

        # Bottom border
        if ( $self->{borderBottom} ) {
            push @out, $self->_render_border_line(
                $b->{bottom_left}, $b->{bottom}, $b->{middle_bottom},
                $b->{bottom_right}
            );
        }

        my $result = join "\n", @out;
        return $result;
    }

    # ── Border line renderer ───────────────────────────────────────────

    sub _render_border_line {
        my ( $self, $left, $fill, $middle, $right ) = @_;
        my $bs = $self->{borderStyle} // NewStyle();
        my $b  = $self->{border};
        my $out = '';

        $out .= $bs->render($left) if $self->{borderLeft};

        for my $j ( 0 .. $#{ $self->{widths} } ) {
            $out .= $bs->render( $fill x $self->{widths}[$j] );
            if ( $j < $#{ $self->{widths} } && $self->{borderColumn} ) {
                $out .= $bs->render($middle);
            }
        }

        $out .= $bs->render($right) if $self->{borderRight};
        return $out;
    }

    # ── Header renderer ────────────────────────────────────────────────

    sub _render_headers {
        my $self = shift;
        my $bs = $self->{borderStyle} // NewStyle();
        my $b  = $self->{border};
        my $height = $self->{heights}[0] // 1;
        my @cells;

        my $left = ( $self->{borderLeft}
            ? ( $bs->render( $b->{left} ) . "\n" ) x $height : '' );
        push @cells, $left if $self->{borderLeft};

        for my $j ( 0 .. $#{ $self->{headers} } ) {
            my $header = $self->{headers}[$j];
            $header = $self->_truncate_cell( $header, HEADER_ROW, $j );
            my $style = $self->_style( HEADER_ROW, $j );
            my $cw = ($self->{widths}[$j] // 1) - $style->get_horizontal_margins;
            my $ch = $height - $style->get_vertical_margins;
            $ch = 1 if $ch < 1;
            push @cells,
              $style->height($ch)->width($cw)->render($header);

            if ( $j < $#{ $self->{headers} } && $self->{borderColumn} ) {
                my $bc = ( $bs->render( $b->{left} ) . "\n" ) x $height;
                push @cells, $bc;
            }
        }

        my $right = ( $self->{borderRight}
            ? ( $bs->render( $b->{right} ) . "\n" ) x $height : '' );
        push @cells, $right if $self->{borderRight};

        # Trim trailing newlines from cells
        s/\n+$// for @cells;

        my $out = JoinHorizontal( Top(), @cells );

        # Header separator
        if ( $self->{borderHeader} ) {
            $out .= "\n";
            $out .= $self->_render_border_line(
                $b->{middle_left}, $b->{top}, $b->{middle},
                $b->{middle_right}
            );
        }

        return $out;
    }

    # ── Row renderer ───────────────────────────────────────────────────

    sub _render_row {
        my ( $self, $index, $is_overflow ) = @_;
        my $bs = $self->{borderStyle} // NewStyle();
        my $b  = $self->{border};
        my $has_headers = @{ $self->{headers} } > 0;

        my $height;
        if ( !$is_overflow ) {
            $height = $self->{heights}[ $index + ($has_headers ? 1 : 0) ] // 1;
        }
        else {
            $height = $self->{overflowHeight} // 1;
        }

        my @cells;
        my $num_cols = $self->{data}->Columns;

        my $left = ( $self->{borderLeft}
            ? ( $bs->render( $b->{left} ) . "\n" ) x $height : '' );
        push @cells, $left if $self->{borderLeft};

        for my $j ( 0 .. $num_cols - 1 ) {
            my $cell = $is_overflow ? '…' : $self->{data}->At( $index, $j );
            my $style = $self->_style( $index, $j );
            my $cw = $self->{widths}[$j] - $style->get_horizontal_margins;

            if ( !$self->{wrap} && !$is_overflow ) {
                $cell = $self->_truncate_cell( $cell, $index, $j );
            }

            push @cells,
              $style->height($height)->width($cw)->render($cell);

            if ( $j < $num_cols - 1 && $self->{borderColumn} ) {
                my $bc = ( $bs->render( $b->{left} ) . "\n" ) x $height;
                push @cells, $bc;
            }
        }

        my $right = ( $self->{borderRight}
            ? ( $bs->render( $b->{right} ) . "\n" ) x $height : '' );
        push @cells, $right if $self->{borderRight};

        s/\n+$// for @cells;

        my $out = JoinHorizontal( Top(), @cells );

        # Row separator
        if ( $self->{borderRow} && !$is_overflow && $index < $self->{data}->Rows - 1 )
        {
            $out .= "\n";
            $out .= $self->_render_border_line(
                $b->{middle_left}, $b->{bottom}, $b->{middle},
                $b->{middle_right}
            );
        }

        return $out;
    }

    # ── Cell truncation ────────────────────────────────────────────────
    sub _truncate_cell {
        my ( $self, $cell, $row_idx, $col_idx ) = @_;
        my $has_headers = @{ $self->{headers} } > 0;
        my $height_idx  = $row_idx == HEADER_ROW ? 0 : $row_idx + ( $has_headers ? 1 : 0 );
        my $height = $self->{heights}[$height_idx] // 1;
        $height = 1 if $row_idx == HEADER_ROW;

        my $cell_width = $self->{widths}[$col_idx] // 1;
        my $style = $self->_style( $row_idx, $col_idx );
        my $length =
          ( $cell_width * $height ) -
          $style->get_horizontal_padding -
          $style->get_horizontal_margins;

        $length = 1 if $length < 1;
        return Cancer::Ansi::Truncate( $cell, $length, '…');
    }

    use overload '""' => 'String';
    sub Render { goto \&String }
}

1;
