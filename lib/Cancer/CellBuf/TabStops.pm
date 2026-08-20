use v5.42;

package Cancer::CellBuf::TabStops v0.0.1 {
    use constant DEFAULT_TAB_INTERVAL => 8;

    sub new ( $class, $width, $interval = DEFAULT_TAB_INTERVAL ) {
        my $self = bless { stops => [], interval => $interval, width => $width }, $class;
        my $size = int( ( $width + ( $interval - 1 ) ) / $interval );
        $self->{stops} = [ (0) x $size ];
        $self->_init( 0, $width );
        return $self;
    }

    sub default ( $class, $width ) {
        return $class->new( $width, DEFAULT_TAB_INTERVAL );
    }

    sub resize ( $self, $width ) {
        return if $width == $self->{width};
        my $interval = $self->{interval};
        if ( $width < $self->{width} ) {
            my $size = int( ( $width + ( $interval - 1 ) ) / $interval );
            $#$self->{stops} = $size - 1;
        }
        else {
            my $size = int( ( $width - $self->{width} + ( $interval - 1 ) ) / $interval );
            push @{ $self->{stops} }, (0) x $size;
        }
        $self->_init( $self->{width}, $width );
        $self->{width} = $width;
    }

    sub is_stop ( $self, $col ) {
        my $mask = $self->_mask($col);
        my $i    = $col >> 3;
        return 0 if $i < 0 || $i >= @{ $self->{stops} };
        return ( $self->{stops}[$i] & $mask ) ? 1 : 0;
    }
    sub next ( $self, $col ) { $self->find( $col,  1 ) }
    sub prev ( $self, $col ) { $self->find( $col, -1 ) }

    sub find ( $self, $col, $delta ) {
        return $col if $delta == 0;
        my $count = abs($delta);
        my $prev  = $delta < 0;
        while ( $count > 0 ) {
            if ( !$prev ) {
                return $col if $col >= $self->{width} - 1;
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

    sub set ( $self, $col ) {
        my $mask = $self->_mask($col);
        $self->{stops}[ $col >> 3 ] |= $mask;
    }

    sub reset ( $self, $col ) {
        my $mask = $self->_mask($col);
        $self->{stops}[ $col >> 3 ] &= ~$mask;
    }

    sub clear_stops ($self) {
        $self->{stops} = [ (0) x @{ $self->{stops} } ];
    }

    sub _mask ( $self, $col ) {
        return 1 << ( $col & ( $self->{interval} - 1 ) );
    }

    sub _init ( $self, $from, $width ) {
        my $interval = $self->{interval};
        for my $x ( $from .. $width - 1 ) {
            if ( $x % $interval == 0 ) {
                $self->set($x);
            }
            else {
                $self->reset($x);
            }
        }
    }
}
1;
