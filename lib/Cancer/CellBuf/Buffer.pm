use v5.42;
use experimental 'class';
class Cancer::CellBuf::Buffer v0.0.1 {
    use Carp qw[carp];
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Line;
    use Cancer::CellBuf::Geom qw[Rect];
    #
    field $width  : param //= 0;
    field $height : param //= 0;
    field @lines;
    #
    ADJUST {
        $self->resize( $width, $height ) if $width && $height;
    }

    method width () {
        return 0 unless @lines;
        return $lines[0]->width;
    }
    method height () { scalar @lines }
    method bounds () { Rect( 0, 0, $width, $height ) }

    method line ($y) {
        return undef if $y < 0 || $y >= @lines;
        return $lines[$y];
    }

    method cell ( $x, $y ) {
        return undef if $y < 0 || $y >= @lines;
        return $lines[$y]->at($x);
    }
    my $MAX_CELL_WIDTH = 4;

    method set_cell ( $x, $y, $c ) {
        return 0 if $y < 0 || $y >= @lines;
        return $lines[$y]->_set( $x, $c, 1 );
    }

    method fill_rect ( $c, $rect ) {
        my $cell_width = ( defined $c && $c->width > 1 ) ? $c->width : 1;
        for my $y ( $rect->min->y .. $rect->max->y - 1 ) {
            for ( my $x = $rect->min->x; $x < $rect->max->x; $x += $cell_width ) {
                $self->_set_cell( $x, $y, $c, 0 );
            }
        }
    }
    method fill ($c)          { $self->fill_rect( $c, $self->bounds ) }
    method clear ()           { $self->clear_rect( $self->bounds ); }
    method clear_rect ($rect) { $self->fill_rect( undef, $rect ) }

    method string () {
        my $s = '';
        for my $i ( 0 .. $#lines ) {
            $s .= $lines[$i]->string;
            $s .= "\r\n" if $i < $#lines;
        }
        return $s;
    }
    method insert_line ( $y, $n, $c = undef ) { $self->insert_line_rect( $y, $n, $c, $self->bounds ) }

    method insert_line_rect ( $y, $n, $c, $rect ) {
        return                  if $n <= 0;
        return                  if $y < $rect->min->y || $y >= $rect->max->y;
        return                  if $y >= $self->height;
        $n = $rect->max->y - $y if $y + $n > $rect->max->y;

        # Move lines down
        for my $i ( reverse( $y + $n .. $rect->max->y - 1 ) ) {
            for my $x ( $rect->min->x .. $rect->max->x - 1 ) {
                my $src = $i - $n;
                $lines[$i] //= Cancer::CellBuf::Line->new;
                $lines[$i]->_set( $x, $lines[$src][$x], 0 );
            }
        }

        # Clear new lines
        for my $i ( $y .. $y + $n - 1 ) {
            for my $x ( $rect->min->x .. $rect->max->x - 1 ) {
                $lines[$i] //= Cancer::CellBuf::Line->new;
                $lines[$i]->_set( $x, $c, 1 );
            }
        }
    }
    method delete_line ( $y, $n, $c = undef ) { $self->delete_line_rect( $y, $n, $c, $self->bounds ) }

    method delete_line_rect ( $y, $n, $c, $rect ) {
        return                  if $n <= 0;
        return                  if $y < $rect->min->y || $y >= $rect->max->y;
        return                  if $y >= $self->height;
        $n = $rect->max->y - $y if $n > $rect->max->y - $y;

        # Shift lines up
        for my $dst ( $y .. $rect->max->y - $n - 1 ) {
            my $src = $dst + $n;
            for my $x ( $rect->min->x .. $rect->max->x - 1 ) {
                $lines[$dst] //= Cancer::CellBuf::Line->new;
                $lines[$dst]->_set( $x, $lines[$src][$x], 0 );
            }
        }

        # Fill bottom with blanks
        for my $i ( $rect->max->y - $n .. $rect->max->y - 1 ) {
            for my $x ( $rect->min->x .. $rect->max->x - 1 ) {
                $lines[$i] //= Cancer::CellBuf::Line->new;
                $lines[$i]->_set( $x, $c, 1 );
            }
        }
    }

    method resize ( $width, $height ) {
        if ( $width == 0 || $height == 0 ) {
            @lines = [];
            return;
        }
        my $old_width = $self->width;
        if ( $width > $old_width ) {
            for my $line (@lines) {
                for my $i ( $old_width .. $width - 1 ) {
                    push @$line, undef;
                }
            }
        }
        elsif ( $width < $old_width ) {
            for my $line (@lines) {
                $#$line = $width - 1;
            }
        }
        my $old_height = $self->height;
        if ( $height > $old_height ) {
            for my $i ( $old_height .. $height - 1 ) {
                push @lines, Cancer::CellBuf::Line->new( (undef) x $width );
            }
        }
        elsif ( $height < $old_height ) {
            splice @lines, $height;
        }
    }

    method _set_cell ( $x, $y, $c, $clone ) {
        return 0 if $y < 0 || $y >= @lines;
        $lines[$y] //= Cancer::CellBuf::Line->new;
        return $lines[$y]->_set( $x, $c, $clone );
    }
};
#
1;
