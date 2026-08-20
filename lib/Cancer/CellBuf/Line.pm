use v5.42;

package Cancer::CellBuf::Line v0.0.1 {
    use Carp qw[carp];
    use Cancer::CellBuf::Cell;

    sub new ( $class, @cells ) {
        bless \@cells, $class;
    }
    sub width ($self) { scalar @$self }
    sub len   ($self) { scalar @$self }

    sub string ($self) {
        my $s = '';
        for my $c (@$self) {
            if ( !defined $c ) {
                $s .= ' ';
            }
            elsif ( $c->empty ) {

                # skip placeholder
            }
            else {
                $s .= $c->string;
            }
        }
        $s =~ s/ +$//;
        return $s;
    }

    sub at ( $self, $x ) {
        return undef if $x < 0 || $x >= @$self;
        my $c = $self->[$x];
        if ( !defined $c ) {
            return Cancer::CellBuf::Cell::BlankCell();
        }
        return $c;
    }
    my $MAX_CELL_WIDTH = 4;

    sub set ( $self, $x, $c ) {
        return $self->_set( $x, $c, 1 );
    }

    sub _set ( $self, $x, $c, $clone ) {
        my $width = $self->width;
        return 0 if $x < 0 || $x >= $width;
        my $prev = $self->at($x);

        # Handle overwriting wide cells
        if ( $prev && $prev->width > 1 ) {
            for my $j ( 0 .. $prev->width - 1 ) {
                last if $x + $j >= $width;
                $self->[ $x + $j ] = $prev->clone->blank;
            }
        }
        elsif ( $prev && $prev->width == 0 ) {

            # Writing to wide cell placeholder
            for my $j ( 1 .. $MAX_CELL_WIDTH - 1 ) {
                last if $x - $j < 0;
                my $wide = $self->at( $x - $j );
                if ( $wide && $wide->width > 1 && $j < $wide->width ) {
                    for my $k ( 0 .. $wide->width - 1 ) {
                        $self->[ $x - $j + $k ] = $wide->clone->blank;
                    }
                    last;
                }
            }
        }
        if ( $clone && defined $c ) {
            $c = $c->clone;
        }
        if ( defined $c && $x + $c->width > $width ) {

            # Cell too wide, fill with blanks
            for my $i ( 0 .. $c->width - 1 ) {
                last if $x + $i >= $width;
                $self->[ $x + $i ] = $c->clone->blank;
            }
        }
        else {
            $self->[$x] = $c;

            # Mark wide cell placeholders
            if ( defined $c && $c->width > 1 ) {
                for my $j ( 1 .. $c->width - 1 ) {
                    last if $x + $j >= $width;
                    $self->[ $x + $j ] = Cancer::CellBuf::Cell->new;
                }
            }
        }
        return 1;
    }
    sub TO_ARRAY ($self) { [@$self] }
}
1;
