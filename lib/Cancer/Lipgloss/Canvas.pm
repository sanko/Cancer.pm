use v5.42;

package Cancer::Lipgloss::Canvas v0.0.1 {
    use Cancer::CellBuf::Buffer;
    use Cancer::CellBuf::Cell;
    use Cancer::CellBuf::Writer qw[render_line];
    use Cancer::CellBuf::Geom   qw[Rect];
    use Cancer::Util            qw[string_width];

    sub new {
        my ( $class, %args ) = @_;
        my $w    = $args{width}  // 0;
        my $h    = $args{height} // 0;
        my $self = bless { width => $w, height => $h, buf => Cancer::CellBuf::Buffer->new( width => $w, height => $h ) }, $class;
        return $self;
    }
    sub width  { $_[0]->{width} }
    sub height { $_[0]->{height} }
    sub bounds { Rect( 0, 0, $_[0]->{width}, $_[0]->{height} ) }

    sub resize {
        my ( $self, $w, $h ) = @_;
        $self->{width}  = $w;
        $self->{height} = $h;
        $self->{buf}->resize( $w, $h );
    }
    sub clear { $_[0]->{buf}->clear }

    sub cell_at {
        my ( $self, $x, $y ) = @_;
        return $self->{buf}->cell( $x, $y );
    }

    sub set_cell {
        my ( $self, $x, $y, $cell ) = @_;
        $self->{buf}->set_cell( $x, $y, $cell );
    }

    sub cell_width {
        my ( $self, $x, $y ) = @_;
        my $cell = $self->{buf}->cell( $x, $y );
        return defined $cell ? $cell->width : 1;
    }

    sub cell_height {
        my ( $self, $x, $y ) = @_;
        return 1;
    }

    sub compose {
        my ( $self, $drawable ) = @_;
        $drawable->draw( $self, $self->bounds );
        return $self;
    }

    sub draw {
        my ( $self, $target, $area ) = @_;
        for my $y ( 0 .. $self->{height} - 1 ) {
            for my $x ( 0 .. $self->{width} - 1 ) {
                my $cell = $self->{buf}->cell( $x, $y );
                next unless defined $cell;
                my $tx = $x + ( $area ? $area->min_x : 0 );
                my $ty = $y + ( $area ? $area->min_y : 0 );
                $target->set_cell( $tx, $ty, $cell ) if $target->can('set_cell');
            }
        }
    }

    sub render {
        my $self = shift;
        my $h    = $self->{height};
        return '' unless $h;
        my $result = '';
        for my $y ( 0 .. $h - 1 ) {
            my ( $w, $line ) = Cancer::CellBuf::Writer::render_line( $self->{buf}, $y );
            $result .= $line;
            $result .= "\n" if $y < $h - 1;
        }
        return $result;
    }
}

sub NewCanvas {
    my (%args) = @_;
    return Cancer::Lipgloss::Canvas->new(%args);
}
1;
