use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[RootTree NewTree];
my $enumerator_style = NewStyle->foreground( Color("63") )->margin_right(1);
my $root_style       = NewStyle->foreground( Color("35") );
my $item_style       = NewStyle->foreground( Color("212") );
my $t
    = RootTree("\x{205C} Makeup")
    ->Child( "Glossier", "Fenty Beauty", NewTree->Child( "Gloss Bomb Universal Lip Luminizer", "Hot Cheeks Velour Blushlighter" ),
    "Nyx", "Mac", "Milk" )
    ->Enumerator( \&Cancer::Lipgloss::Tree::RoundedEnumerator )
    ->EnumeratorStyle($enumerator_style)
    ->IndenterStyle($enumerator_style)
    ->RootStyle($root_style)
    ->ItemStyle($item_style);
Println($t);
