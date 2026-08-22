use v5.42;

package Cancer::Lipgloss::Compositor v0.0.1 {
    use Cancer::Lipgloss::Canvas;
    use Cancer::Lipgloss::Layer;
    use Cancer::CellBuf::Geom qw[Rect];
    use Cancer::Util          qw[string_width];

    sub new {
        my ( $class, @init_layers ) = @_;
        my $root = Cancer::Lipgloss::Layer->new;
        $root->add_layers(@init_layers) if @init_layers;
        my $self = bless { root => $root, _layers => [], _index => {}, _bounds => Rect( 0, 0, 0, 0 ) }, $class;
        $self->_flatten;
        return $self;
    }

    sub add_layers {
        my ( $self, @new_layers ) = @_;
        $self->{root}->add_layers(@new_layers);
        $self->_flatten;
        return $self;
    }

    sub _flatten {
        my $self = shift;
        $self->{_layers} = [];
        $self->{_index}  = {};
        $self->_flatten_recursive( $self->{root}, 0, 0 );

        # Sort by absolute z-index (lowest to highest for drawing)
        $self->{_layers} = [ sort { $a->{layer}{z} <=> $b->{layer}{z} } @{ $self->{_layers} } ];

        # Calculate overall bounds
        if ( @{ $self->{_layers} } ) {
            my $b = $self->{_layers}[0]{bounds};
            for my $i ( 1 .. $#{ $self->{_layers} } ) {
                $b = _union_rect( $b, $self->{_layers}[$i]{bounds} );
            }
            $self->{_bounds} = $b;
        }
        else {
            $self->{_bounds} = Rect( 0, 0, 0, 0 );
        }
    }

    sub _flatten_recursive {
        my ( $self, $layer, $parent_x, $parent_y ) = @_;
        my $abs_x  = $layer->get_x + $parent_x;
        my $abs_y  = $layer->get_y + $parent_y;
        my $w      = $layer->width;
        my $h      = $layer->height;
        my $bounds = Rect( $abs_x, $abs_y, $w, $h );
        push @{ $self->{_layers} }, { layer => $layer, abs_x => $abs_x, abs_y => $abs_y, bounds => $bounds };
        if ( defined $layer->get_id && length $layer->get_id ) {
            $self->{_index}{ $layer->get_id } = $layer;
        }
        for my $child ( $layer->layers ) {
            $self->_flatten_recursive( $child, $abs_x, $abs_y );
        }
    }
    sub bounds { $_[0]->{_bounds} }

    sub draw {
        my ( $self, $screen, $area ) = @_;
        my @sorted = sort { $a->{layer}->get_z <=> $b->{layer}->get_z } @{ $self->{_layers} };
        for my $cl (@sorted) {
            my $cl_bounds = $cl->{bounds};
            if ( _rects_overlap( $cl_bounds, $area ) ) {
                $cl->{layer}->draw( $screen, $cl_bounds );
            }
        }
    }

    sub hit {
        my ( $self, $x, $y ) = @_;

        # Check from highest z to lowest (reverse order)
        for my $i ( reverse 0 .. $#{ $self->{_layers} } ) {
            my $cl = $self->{_layers}[$i];
            my $id = $cl->{layer}->get_id;
            if ( defined $id && length $id && _rect_contains( $cl->{bounds}, $x, $y ) ) {
                return Cancer::Lipgloss::LayerHit->new( id => $id, layer => $cl->{layer}, bounds => $cl->{bounds} );
            }
        }
        return Cancer::Lipgloss::LayerHit->new;
    }

    sub get_layer {
        my ( $self, $id ) = @_;
        return undef unless defined $id && length $id;
        return $self->{_index}{$id};
    }
    sub refresh { $_[0]->_flatten }

    sub render {
        my $self   = shift;
        my $b      = $self->{_bounds};
        my $width  = $b ? $b->dx : 0;
        my $height = $b ? $b->dy : 0;
        my $canvas = Cancer::Lipgloss::Canvas->new( width => $width, height => $height );
        $canvas->compose($self);
        return $canvas->render;
    }

    # ---- Geometry helpers --------------------------------------------------------------------------------------------
    sub _union_rect {
        my ( $a, $b ) = @_;
        my $min_x = $a->min_x < $b->min_x ? $a->min_x : $b->min_x;
        my $min_y = $a->min_y < $b->min_y ? $a->min_y : $b->min_y;
        my $max_x = $a->max_x > $b->max_x ? $a->max_x : $b->max_x;
        my $max_y = $a->max_y > $b->max_y ? $a->max_y : $b->max_y;
        return Rect( $min_x, $min_y, $max_x - $min_x, $max_y - $min_y );
    }

    sub _rects_overlap {
        my ( $a, $b ) = @_;
        return 0 unless $a && $b;
        return 0 if $a->max_x <= $b->min_x;
        return 0 if $a->max_y <= $b->min_y;
        return 0 if $b->max_x <= $a->min_x;
        return 0 if $b->max_y <= $a->min_y;
        return 1;
    }

    sub _rect_contains {
        my ( $rect, $x, $y ) = @_;
        return 0 unless $rect;
        return $x >= $rect->min_x && $x < $rect->max_x && $y >= $rect->min_y && $y < $rect->max_y;
    }
}

sub NewCompositor {
    my @layers = @_;
    return Cancer::Lipgloss::Compositor->new(@layers);
}
1;
