use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::List qw[NewList];
my @purchased = ( "Bananas", "Barley", "Cashews", "Coconut Milk", "Dill", "Eggs", "Fish Cake", "Leeks", "Papaya" );

sub is_purchased {
    my $v = shift;
    grep { $_ eq $v } @purchased;
}

sub grocery_enum {
    my ( $items, $i ) = @_;
    is_purchased( $items->[$i]->Value ) ? "\x{2713}" : "\x{2022}";
}
my $dim_enum_style = NewStyle->foreground( Color("240") )->margin_right(1);
my $hl_enum_style  = NewStyle->foreground( Color("10") )->margin_right(1);

sub enum_style_func {
    my ( $items, $i ) = @_;
    is_purchased( $items->[$i]->Value ) ? $hl_enum_style : $dim_enum_style;
}

sub item_style_func {
    my ( $items, $i ) = @_;
    my $s = NewStyle->foreground( Color("255") );
    is_purchased( $items->[$i]->Value ) ? $s->strikethrough(1) : $s;
}
my $l = NewList->Items(
    "Artichoke",   "Baking Flour", "Bananas", "Barley",      "Bean Sprouts", "Cashew Apple", "Cashews",   "Coconut Milk",
    "Curry Paste", "Currywurst",   "Dill",    "Dragonfruit", "Dried Shrimp", "Eggs",         "Fish Cake", "Furikake",
    "Jicama",      "Kohlrabi",     "Leeks",   "Lentils",     "Licorice Root"
)->Enumerator( \&grocery_enum )->EnumeratorStyleFunc( \&enum_style_func )->ItemStyleFunc( \&item_style_func );
Println($l);
