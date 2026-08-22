use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::List qw[NewList RomanEnumerator];
my $enumerator_style = NewStyle->foreground( Color("99") )->margin_right(1);
my $item_style       = NewStyle->foreground( Color("255") )->margin_right(1);
my $l
    = NewList->Items( "Glossier", "Claire\x{2019}s Boutique", "Nyx", "Mac", "Milk" )
    ->Enumerator( \&RomanEnumerator )
    ->EnumeratorStyle($enumerator_style)
    ->ItemStyle($item_style);
Println($l);
