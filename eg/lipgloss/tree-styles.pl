use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[NewTree];
my $purple = NewStyle->foreground( Color("99") )->margin_right(1);
my $pink   = NewStyle->foreground( Color("212") )->margin_right(1);
my $t      = NewTree->Child(
    "Glossier",
    "Claire\x{2019}s Boutique",
    NewTree->Root("Nyx")->Child( "Lip Gloss", "Foundation" )->EnumeratorStyle($pink)->IndenterStyle($purple),
    "Mac", "Milk"
)->EnumeratorStyle($purple)->IndenterStyle($purple);
print $t, "\n";
