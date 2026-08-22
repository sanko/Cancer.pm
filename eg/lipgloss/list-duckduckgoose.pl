use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::List qw[NewList];

sub duck_duck_goose_enum {
    my ( $items, $i ) = @_;
    return "Honk \x{2192}" if $items->[$i]->Value eq "Goose";
    return " ";
}
my $enum_style = NewStyle->foreground( Color("#00d787") )->margin_right(1);
my $item_style = NewStyle->foreground( Color("255") );
my $l
    = NewList->Items( "Duck", "Duck", "Duck", "Goose", "Duck" )
    ->Enumerator( \&duck_duck_goose_enum )
    ->EnumeratorStyle($enum_style)
    ->ItemStyle($item_style);
Println($l);
