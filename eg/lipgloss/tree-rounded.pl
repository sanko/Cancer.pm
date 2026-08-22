use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[RootTree NewTree];
my $item_style       = NewStyle->margin_right(1);
my $enumerator_style = NewStyle->foreground( Color("8") )->margin_right(1);
my $t                = RootTree("Groceries")->Child(
    RootTree("Fruits")->Child( "Blood Orange", "Papaya", "Dragonfruit", "Yuzu" ),
    RootTree("Items")->Child( "Cat Food", "Nutella", "Powdered Sugar" ),
    RootTree("Veggies")->Child( "Leek", "Artichoke" )
    )
    ->ItemStyle($item_style)
    ->EnumeratorStyle($enumerator_style)
    ->Enumerator( \&Cancer::Lipgloss::Tree::RoundedEnumerator )
    ->IndenterStyle($enumerator_style);
Println($t);
