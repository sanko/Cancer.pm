use v5.42;
use lib 'lib';
use blib;
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[RootTree];
binmode STDOUT, ':unix:utf8';
use File::Spec;
my $enumerator_style = NewStyle->foreground( Color("240") )->padding_right(1);
my $item_style       = NewStyle->foreground( Color("99") )->bold(1)->padding_right(1);

sub add_branches {
    my ( $node, $path ) = @_;
    opendir my $dh, $path or return;
    my @entries = sort grep { !/^\./ } readdir $dh;
    closedir $dh;
    for my $entry (@entries) {
        my $full = File::Spec->catfile( $path, $entry );
        if ( -d $full ) {
            my $branch = RootTree($entry);
            $node->Child($branch);
            add_branches( $branch, $full );
        }
        else {
            $node->Child($entry);
        }
    }
}
my $pwd = File::Spec->rel2abs('.');
my $t   = RootTree($pwd)->IndenterStyle($enumerator_style)->EnumeratorStyle($enumerator_style)->RootStyle($item_style)->ItemStyle($item_style);
add_branches( $t, '.' );
Println($t);
