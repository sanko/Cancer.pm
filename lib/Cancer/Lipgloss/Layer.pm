use v5.42;

package Cancer::Lipgloss::Layer v0.0.1 {
    use Cancer::CellBuf::Writer qw[set_content_rect];
    use Cancer::CellBuf::Geom   qw[Rect];
    use Cancer::Util            qw[string_width];

    sub new {
        my ( $class, %args ) = @_;
        my $self = bless {
            id      => $args{id}      // '',
            content => $args{content} // '',
            x       => $args{x}       // 0,
            y       => $args{y}       // 0,
            z       => $args{z}       // 0,
            _layers => [],
            width   => 0,
            height  => 0
        }, $class;
        if ( $args{layers} && ref $args{layers} eq 'ARRAY' ) {
            for my $l ( @{ $args{layers} } ) {
                die "layer at index " . scalar( @{ $self->{_layers} } ) . " is nil" unless defined $l;
                push @{ $self->{_layers} }, $l;
            }
        }
        $self->_compute_bounds;
        return $self;
    }
    sub id      { $_[0]->{id} }
    sub content { $_[0]->{content} }
    sub width   { $_[0]->{width} }
    sub height  { $_[0]->{height} }

    sub set_id {
        my ( $self, $id ) = @_;
        $self->{id} = $id;
        return $self;
    }

    sub set_x {
        my ( $self, $v ) = @_;
        $self->{x} = $v;
        return $self;
    }
    *X = \&set_x;

    sub set_y {
        my ( $self, $v ) = @_;
        $self->{y} = $v;
        return $self;
    }
    *Y = \&set_y;

    sub set_z {
        my ( $self, $v ) = @_;
        $self->{z} = $v;
        return $self;
    }
    *Z = \&set_z;
    sub get_id { $_[0]->{id} }
    sub get_x  { $_[0]->{x} }
    sub get_y  { $_[0]->{y} }
    sub get_z  { $_[0]->{z} }
    sub layers { @{ $_[0]->{_layers} } }

    sub add_layers {
        my ( $self, @new_layers ) = @_;
        for my $i ( 0 .. $#new_layers ) {
            die "layer at index $i is nil" unless defined $new_layers[$i];
            push @{ $self->{_layers} }, $new_layers[$i];
        }
        $self->_compute_bounds;
        return $self;
    }
    *AddLayers = \&add_layers;

    sub get_layer {
        my ( $self, $id ) = @_;
        return undef unless defined $id && length $id;
        return $self if defined $self->{id} && $self->{id} eq $id;
        for my $child ( @{ $self->{_layers} } ) {
            my $found = $child->get_layer($id);
            return $found if defined $found;
        }
        return undef;
    }

    sub max_z {
        my $self  = shift;
        my $max_z = $self->{z};
        for my $child ( @{ $self->{_layers} } ) {
            my $child_max = $child->max_z;
            $max_z = $child_max if $child_max > $max_z;
        }
        return $max_z;
    }

    sub _compute_bounds {
        my $self = shift;
        my ( $w, $h ) = ( 0, 0 );
        if ( defined $self->{content} && length $self->{content} ) {
            my @lines = split /\n/, $self->{content}, -1;
            for my $line (@lines) {
                my $lw = string_width($line);
                $w = $lw if $lw > $w;
            }
            $h = scalar @lines;
        }
        my $max_x = $self->{x} + $w;
        my $max_y = $self->{y} + $h;
        for my $child ( @{ $self->{_layers} } ) {
            my $cw = $child->width;
            my $ch = $child->height;
            my $cx = $self->{x} + $child->get_x + $cw;
            my $cy = $self->{y} + $child->get_y + $ch;
            $max_x = $cx if $cx > $max_x;
            $max_y = $cy if $cy > $max_y;
        }
        $self->{width}  = $max_x - $self->{x};
        $self->{height} = $max_y - $self->{y};
    }

    sub draw {
        my ( $self, $screen, $area ) = @_;
        return unless defined $self->{content} && length $self->{content};
        my $ax = $area ? $area->min_x : 0;
        my $ay = $area ? $area->min_y : 0;
        my $aw = $area ? $area->dx    : 0;
        my $ah = $area ? $area->dy    : 0;
        if ( $screen->can('set_cell') ) {
            my $rect = Rect( $ax, $ay, $aw, $ah );
            set_content_rect( $screen, $self->{content}, $rect );
        }
    }
}

sub NewLayer {
    my ( $content, @layers ) = @_;
    return Cancer::Lipgloss::Layer->new( content => $content, layers => [@layers] );
}

sub NewLayerHit {
    my (%args) = @_;
    return bless { id => $args{id} // '', layer => $args{layer}, bounds => $args{bounds} }, 'Cancer::Lipgloss::LayerHit';
}

package Cancer::Lipgloss::LayerHit {

    sub new {
        my ( $class, %args ) = @_;
        return bless { id => $args{id} // '', layer => $args{layer}, bounds => $args{bounds} }, $class;
    }
    sub empty  { !defined $_[0]->{layer} }
    sub id     { $_[0]->{id} }
    sub layer  { $_[0]->{layer} }
    sub bounds { $_[0]->{bounds} }
}
1;
