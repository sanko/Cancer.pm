use v5.42;

package Cancer::Lipgloss::Tree v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[
        NewTree RootTree
        DefaultEnumerator RoundedEnumerator DefaultIndenter
    ];

    use Cancer::Lipgloss qw[NewStyle JoinHorizontal JoinVertical Left Top width height string_width];
    use overload '""' => 'String';
    use utf8;

    # ── Leaf ───────────────────────────────────────────────────────────

    package Cancer::Lipgloss::Tree::Leaf {
        sub new {
            my ( $class, %args ) = @_;
            return bless {
                value  => $args{value} // '',
                hidden => $args{hidden} // 0,
            }, $class;
        }

        sub Children    { return [] }
        sub Value       { return $_[0]->{value} }
        sub Hidden      { return $_[0]->{hidden} }
        sub SetHidden   { $_[0]->{hidden} = $_[1] }
        sub SetValue {
            my ( $self, $val ) = @_;
            if ( ref $val && $val->can('String') ) {
                $self->{value} = $val->String;
            }
            elsif ( !defined $val ) {
                $self->{value} = '';
            }
            else {
                $self->{value} = "$val";
            }
        }
        sub String { return $_[0]->{value} }
    }

    # ── NodeChildren (arrayref of Node objects) ────────────────────────

    sub _new_children { return $_[0] // [] }
    sub _children_length { scalar @{ $_[0] } }
    sub _children_at { $_[0][$_[1]] }

    # ── Tree ───────────────────────────────────────────────────────────

    sub new_tree {
        my ( $class, %args ) = @_;
        return bless {
            value    => $args{value} // '',
            hidden   => $args{hidden} // 0,
            offset   => [ 0, 0 ],
            children => [],
            renderer => undef,     # lazy
        }, 'Cancer::Lipgloss::Tree';
    }

    sub NewTree { new_tree( 'Cancer::Lipgloss::Tree', @_ ) }

    sub RootTree {
        my $root = shift;
        my $t = new_tree('Cancer::Lipgloss::Tree');
        return $t->Root($root);
    }

    # Tree methods (on blessed hashref)
    sub Value    { return $_[0]->{value} }
    sub Hidden   { return $_[0]->{hidden} }

    sub SetHidden { $_[0]->{hidden} = $_[1] }

    sub Hide {
        $_[0]->{hidden} = $_[1];
        return $_[0];
    }

    sub Root {
        my ( $self, $root ) = @_;
        if ( ref $root && ref $root eq 'Cancer::Lipgloss::Tree' ) {
            $self->{value} = $root->{value};
            $self->{children} = [ @{ $root->{children} } ];
        }
        elsif ( ref $root && $root->can('String') ) {
            $self->{value} = $root->String;
        }
        elsif ( !defined $root ) {
            $self->{value} = '';
        }
        else {
            $self->{value} = "$root";
        }
        return $self;
    }

    sub Offset {
        my ( $self, $start, $end ) = @_;
        ( $start, $end ) = ( $end, $start ) if $start > $end;
        $start = 0 if $start < 0;
        my $len = scalar @{ $self->{children} };
        $end = $len if $end < 0 || $end > $len;
        $self->{offset} = [ $start, $end ];
        return $self;
    }

    sub Children {
        my $self = shift;
        my ( $s, $e ) = @{ $self->{offset} };
        my $len = scalar @{ $self->{children} };
        $s //= 0;
        $e //= 0;
        my $end = $len - $e;
        return $end <= $s ? [] : [ @{ $self->{children} }[ $s .. $end - 1 ] ];
    }

    sub Child {
        my ( $self, @children ) = @_;
        for my $child (@children) {
            if ( !defined $child ) {
                next;
            }
            elsif ( ref $child && ref $child eq 'Cancer::Lipgloss::Tree' ) {
                my ( $new_item, $rm ) = _ensure_parent( $self->{children}, $child );
                if ( $rm >= 0 ) {
                    splice( @{ $self->{children} }, $rm, 1 );
                }
                push @{ $self->{children} }, $new_item;
            }
            elsif ( ref $child && ref $child eq 'Cancer::Lipgloss::Tree::Leaf' ) {
                push @{ $self->{children} }, $child;
            }
            elsif ( ref $child eq 'ARRAY' ) {
                $self->Child(@$child);
            }
            else {
                push @{ $self->{children} },
                  Cancer::Lipgloss::Tree::Leaf->new( value => "$child" );
            }
        }
        return $self;
    }

    sub _ensure_parent {
        my ( $nodes, $item ) = @_;
        if ( $item->{value} ne '' || !@$nodes ) {
            return ( $item, -1 );
        }
        my $j = $#$nodes;
        my $parent = $nodes->[$j];
        if ( ref $parent && ref $parent eq 'Cancer::Lipgloss::Tree' ) {
            for my $child ( @{ $item->{children} } ) {
                push @{ $parent->{children} }, $child;
            }
            return ( $parent, $j );
        }
        elsif ( ref $parent && ref $parent eq 'Cancer::Lipgloss::Tree::Leaf' ) {
            $item->{value} = $parent->{value};
            return ( $item, $j );
        }
        return ( $item, -1 );
    }

    # ── Renderer accessors (lazy init) ─────────────────────────────────

    sub _ensure_renderer {
        my $self = shift;
        unless ( $self->{renderer} ) {
            $self->{renderer} = _new_renderer();
        }
        return $self->{renderer};
    }

    sub Enumerator {
        my ( $self, $enum ) = @_;
        $self->_ensure_renderer->{enumerator} = $enum;
        return $self;
    }

    sub Indenter {
        my ( $self, $indent ) = @_;
        $self->_ensure_renderer->{indenter} = $indent;
        return $self;
    }

    sub EnumeratorStyle {
        my ( $self, $style ) = @_;
        my $r = $self->_ensure_renderer;
        $r->{style}{enumeratorFunc} = sub { return $style };
        return $self;
    }

    sub EnumeratorStyleFunc {
        my ( $self, $fn ) = @_;
        $self->_ensure_renderer->{style}{enumeratorFunc} = $fn;
        return $self;
    }

    sub IndenterStyle {
        my ( $self, $style ) = @_;
        my $r = $self->_ensure_renderer;
        $r->{style}{indenterFunc} = sub { return $style };
        return $self;
    }

    sub IndenterStyleFunc {
        my ( $self, $fn ) = @_;
        $self->_ensure_renderer->{style}{indenterFunc} = $fn;
        return $self;
    }

    sub ItemStyle {
        my ( $self, $style ) = @_;
        my $r = $self->_ensure_renderer;
        $r->{style}{itemFunc} = sub { return $style };
        return $self;
    }

    sub ItemStyleFunc {
        my ( $self, $fn ) = @_;
        $self->_ensure_renderer->{style}{itemFunc} = $fn;
        return $self;
    }

    sub RootStyle {
        my ( $self, $style ) = @_;
        $self->_ensure_renderer->{style}{root} = $style;
        return $self;
    }

    sub Width {
        my ( $self, $w ) = @_;
        $self->_ensure_renderer->{width} = $w;
        return $self;
    }

    # ── String / render ────────────────────────────────────────────────

    sub String {
        my $self = shift;
        my $r = $self->_ensure_renderer;
        return _render( $r, $self, 1, '' );
    }

    # ── Renderer ───────────────────────────────────────────────────────

    sub _new_renderer {
        return {
            style => {
                enumeratorFunc => sub { NewStyle()->padding_right(1) },
                indenterFunc   => sub { NewStyle()->padding_right(1) },
                itemFunc       => sub { NewStyle() },
                root           => NewStyle(),
            },
            enumerator => \&DefaultEnumerator,
            indenter   => \&DefaultIndenter,
            width      => 0,
        };
    }

    sub _render {
        my ( $r, $node, $is_root, $prefix ) = @_;
        return '' if $node->Hidden;

        my @children = @{ $node->Children // [] };
        my $enumerator = $r->{enumerator};
        my $indenter   = $r->{indenter};

        my @strs;

        # Print root node name
        if ( my $name = $node->Value ) {
            if ($is_root) {
                my $line = $r->{style}{root}->render($name);
                if ( $r->{width} > 0 ) {
                    if ( my $pad = $r->{width} - Cancer::Lipgloss::width($line) ) {
                        $line = $name . $r->{style}{root}->render( ' ' x ($pad > 0 ? $pad : 0) );
                    }
                }
                push @strs, $line;
            }
        }

        # Remove trailing hidden children for prefix calculation
        while ( @children && $children[-1]->Hidden ) {
            pop @children;
        }

        # Calculate max enumerator width
        my $max_len = 0;
        for my $i ( 0 .. $#children ) {
            my $prefix = $enumerator->( \@children, $i );
            my $styled = $r->{style}{enumeratorFunc}->( \@children, $i )->render($prefix);
            my $w = Cancer::Lipgloss::width($styled);
            $max_len = $w if $w > $max_len;
        }

        # Render children
        for my $i ( 0 .. $#children ) {
            my $child = $children[$i];
            next if $child->Hidden;

            my $indent_style = $r->{style}{indenterFunc}->( \@children, $i );
            my $enum_style   = $r->{style}{enumeratorFunc}->( \@children, $i );
            my $item_style   = $r->{style}{itemFunc}->( \@children, $i );

            my $indent      = $indent_style->render( $indenter->( \@children, $i ) );
            my $node_prefix = $enum_style->render( $enumerator->( \@children, $i ) );

            # Pad prefix to align with longest
            my $enum_bg = $enum_style->{bg};
            my $enum_bg_style = (defined $enum_bg && !$enum_bg->isa('Cancer::Lipgloss::NoColor'))
                ? NewStyle()->background( $enum_bg )
                : NewStyle();
            if ( my $l = $max_len - Cancer::Lipgloss::width($node_prefix) ) {
                $node_prefix = $enum_bg_style->render( ' ' x $l ) . $node_prefix;
            }

            my $item = $item_style->render( $child->Value );
            my $mline_prefix = $enum_bg_style->render($prefix);

            # Handle multiline prefixes
            while ( Cancer::Lipgloss::height($item) > Cancer::Lipgloss::height($node_prefix) ) {
                $node_prefix = JoinVertical( Left, $node_prefix, $indent );
            }
            while ( length($prefix) && Cancer::Lipgloss::height($node_prefix) > Cancer::Lipgloss::height($mline_prefix) ) {
                $mline_prefix = JoinVertical( Left, $mline_prefix, $prefix );
            }

            my $line = JoinHorizontal( Top, $mline_prefix, $node_prefix, $item );

            # Pad to width
            if ( $r->{width} > 0 ) {
                if ( my $pad = $r->{width} - Cancer::Lipgloss::width($line) ) {
                    $line .= $item_style->render( ' ' x ($pad > 0 ? $pad : 0) );
                }
            }

            push @strs, $line;

            # Recurse into children
            if ( @children ) {
                my $child_renderer = $r;
                if ( ref $child eq 'Cancer::Lipgloss::Tree' && $child->{renderer} ) {
                    $child_renderer = $child->{renderer};
                }
                my $child_str = _render( $child_renderer, $child, 0, $prefix . $indent );
                push @strs, $child_str if length $child_str;
            }
        }

        return join "\n", @strs;
    }

    # ── Default Enumerators ────────────────────────────────────────────

    sub DefaultEnumerator {
        my ( $children, $index ) = @_;
        return $index == $#$children
          ? "\x{2514}\x{2500}\x{2500}"
          : "\x{251C}\x{2500}\x{2500}";
    }

    sub RoundedEnumerator {
        my ( $children, $index ) = @_;
        return $index == $#$children
          ? "\x{2570}\x{2500}\x{2500}"
          : "\x{251C}\x{2500}\x{2500}";
    }

    sub DefaultIndenter {
        my ( $children, $index ) = @_;
        return $index == $#$children
          ? "   "
          : "\x{2502}  ";
    }
}

1;
