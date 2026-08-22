use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[NewTree RootTree];
my $SELECTED = "/Users/bash/.config/doom-emacs";

sub default_styles {
    my $base = NewStyle;
    return {
        base      => $base,
        container => $base->margin( 1, 2 )->padding( 1, 0 ),
        dir       => $base->inline(1),
        toggle    => NewStyle->foreground( Color("5") )->padding_right(1),
        selected  => NewStyle->background( Color("8") )->foreground( Color("207") )->bold(1),
        dimmed    => NewStyle->foreground( Color("241") )
    };
}
my $S = default_styles();

sub make_dir {
    my ( $name, $open ) = @_;
    my $t    = $S->{toggle}->padding_left(1)->render( $open ? "\x{25BC}" : "\x{25B6}" );
    my $n    = $S->{dir}->render($name);
    my $leaf = Cancer::Lipgloss::Tree::Leaf->new( value => $t . $n );
    $leaf->{_node_name} = $name;
    $leaf->{_node_type} = 'dir';
    $leaf->{_node_open} = $open;
    return $leaf;
}

sub make_file {
    my ($name) = @_;
    my @parts  = split /\//, $name;
    my $leaf   = Cancer::Lipgloss::Tree::Leaf->new( value => $parts[-1] );
    $leaf->{_node_name} = $name;
    $leaf->{_node_type} = 'file';
    return $leaf;
}

# ---- Style callbacks ----
sub is_item_selected {
    my ( $children, $index ) = @_;
    my $child = $children->[$index];
    return 0 unless ref $child;
    return 1 if ( $child->{_node_type} // '' ) eq 'file' && ( $child->{_node_name} // '' ) eq $SELECTED;
    return 0;
}

sub item_style {
    my ( $children, $index ) = @_;
    return $S->{selected} if is_item_selected( $children, $index );
    return $S->{base};
}

sub indenter_style {
    my ( $children, $index ) = @_;
    if ( is_item_selected( $children, $index ) ) {
        return $S->{dimmed}->background( $S->{selected}->get_background );
    }
    return $S->{dimmed};
}
sub my_enumerator {" \x{2502} "}
sub my_indenter   {" \x{2502} "}

# ---- Build tree ----
my $t = RootTree( make_dir( "~/charm", 1 ) )->Child(
    make_dir( "ayman", 0 ),
    RootTree( make_dir( "bash",   1 ) )->Child( make_file("/Users/bash/.config/doom-emacs") ),
    RootTree( make_dir( "carlos", 1 ) )->Child(
        RootTree( make_dir( "emotes", 1 ) )->Child( make_file("/home/caarlos0/Pictures/chefkiss.png"), make_file("/home/caarlos0/Pictures/kekw.png") )
    ),
    make_dir( "maas", 0 )
    )
    ->Width(30)
    ->Enumerator( \&my_enumerator )
    ->Indenter( \&my_indenter )
    ->EnumeratorStyleFunc( \&indenter_style )
    ->IndenterStyleFunc( \&indenter_style )
    ->ItemStyleFunc( \&item_style );
print $S->{container}->render( $t->String ), "\n";
