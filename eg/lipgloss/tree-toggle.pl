use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[RootTree NewTree];
my $color_style    = NewStyle->background( Color("57") )->foreground( Color("225") );
my $block_style    = $color_style->clone->padding( 1, 3 )->margin( 1, 3 )->width(40);
my $toggle_style   = $color_style->clone->foreground( Color("207") )->padding_right(1);
my $dir_style      = $color_style->clone;
my $file_style     = $color_style->clone;
my $indenter_style = $color_style->clone->foreground( Color("212") )->padding_right(1);

sub mk_dir {
    my ( $name, $open ) = @_;
    my $icon = $open ? "\x{25BC}" : "\x{25B6}";
    return "$icon $name";
}

sub mk_file {
    my ($name) = @_;
    return $name;
}
my $t
    = RootTree( mk_dir( "~/charm", 1 ) )
    ->Enumerator( \&Cancer::Lipgloss::Tree::RoundedEnumerator )
    ->IndenterStyle($indenter_style)
    ->EnumeratorStyle($indenter_style)
    ->ItemStyle($dir_style)
    ->Child(
    mk_dir( "ayman", 0 ),
    RootTree( mk_dir( "bash",   1 ) )->Child( RootTree( mk_dir( "tools",  1 ) )->Child( mk_file("zsh"),          mk_file("doom-emacs") ) ),
    RootTree( mk_dir( "carlos", 1 ) )->Child( RootTree( mk_dir( "emotes", 1 ) )->Child( mk_file("chefkiss.png"), mk_file("kekw.png") ) ),
    mk_dir( "maas", 0 )
    );
Println( $block_style->render( $t->String ) );
