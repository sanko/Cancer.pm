use v5.42;
use experimental 'class';
class Cancer::CellBuf::TabStops v0.0.1 {
    use constant DEFAULT_TAB_INTERVAL => 8;
    field $width : param;
    field $interval : param = DEFAULT_TAB_INTERVAL;
    field @stops;
    ADJUST {
        my $size = int( ( $width + ( $interval - 1 ) ) / $interval );
        @stops = (0) x $size;
        $self->_init( 0, $width );
    }

    sub default ( $class, $width ) {
        return $class->new( width => $width, interval => DEFAULT_TAB_INTERVAL );
    }

    method resize ($new_width) {
        return if $new_width == $width;
        if ( $new_width < $width ) {
            my $size = int( ( $new_width + ( $interval - 1 ) ) / $interval );
            $#stops = $size - 1;
        }
        else {
            my $size = int( ( $new_width - $width + ( $interval - 1 ) ) / $interval );
            push @stops, (0) x $size;
        }
        $self->_init( $width, $new_width );
        $width = $new_width;
    }

    method is_stop ($col) {
        my $mask = $self->_mask($col);
        my $i    = $col >> 3;
        return 0 if $i < 0 || $i >= @stops;
        return ( $stops[$i] & $mask ) ? 1 : 0;
    }
    method next ($col) { $self->find( $col,  1 ) }
    method prev ($col) { $self->find( $col, -1 ) }

    method find ( $col, $delta ) {
        return $col if $delta == 0;
        my $count = abs($delta);
        my $prev  = $delta < 0;
        while ( $count > 0 ) {
            if ( !$prev ) {
                return $col if $col >= $width - 1;
                $col++;
            }
            else {
                return $col if $col < 1;
                $col--;
            }
            $count-- if $self->is_stop($col);
        }
        return $col;
    }

    method set ($col) {
        my $mask = $self->_mask($col);
        $stops[ $col >> 3 ] |= $mask;
    }

    method reset ($col) {
        my $mask = $self->_mask($col);
        $stops[ $col >> 3 ] &= ~$mask;
    }

    method clear_stops () {
        @stops = (0) x @stops;
    }

    method _mask ($col) {
        return 1 << ( $col & ( $interval - 1 ) );
    }

    method _init ( $from, $to ) {
        for my $x ( $from .. $to - 1 ) {
            if ( $x % $interval == 0 ) {
                $self->set($x);
            }
            else {
                $self->reset($x);
            }
        }
    }
} 1;
