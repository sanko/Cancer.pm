use v5.42;
use lib 'lib';
use blib;
use Cancer::Lipgloss        qw[NewStyle Color NoColor Println NormalBorder];
use Cancer::Lipgloss::Table qw[NewTable HEADER_ROW];
binmode STDOUT, ':unix:utf8';
my $base_style     = NewStyle->padding( 0, 1 );
my $header_style   = $base_style->foreground( Color("252") )->bold(1);
my $selected_style = $base_style->foreground( Color("#01BE85") )->background( Color("#00432F") );
my %type_colors    = (
    Bug      => Color("#D7FF87"),
    Electric => Color("#FDFF90"),
    Fire     => Color("#FF7698"),
    Flying   => Color("#FF87D7"),
    Grass    => Color("#75FBAB"),
    Ground   => Color("#FF875F"),
    Normal   => Color("#929292"),
    Poison   => Color("#7D5AFC"),
    Water    => Color("#00E2C7")
);
my %dim_type_colors = (
    Bug      => Color("#97AD64"),
    Electric => Color("#FCFF5F"),
    Fire     => Color("#BA5F75"),
    Flying   => Color("#C97AB2"),
    Grass    => Color("#59B980"),
    Ground   => Color("#C77252"),
    Normal   => Color("#727272"),
    Poison   => Color("#634BD0"),
    Water    => Color("#439F8E")
);
my @headers = map {uc} ( "#", "Name", "Type 1", "Type 2", "Japanese", "Official Rom." );
my @data    = (
    [ "1",  "Bulbasaur",  "Grass",    "Poison", "\x{30D5}\x{30B7}\x{30AE}\x{30C0}\x{30CD}", "Fushigidane" ],
    [ "2",  "Ivysaur",    "Grass",    "Poison", "\x{30D5}\x{30B7}\x{30AE}\x{30BD}\x{30A6}", "Fushigisou" ],
    [ "3",  "Venusaur",   "Grass",    "Poison", "\x{30D5}\x{30B7}\x{30AE}\x{30D0}\x{30CA}", "Fushigibana" ],
    [ "4",  "Charmander", "Fire",     "",       "\x{30D2}\x{30C8}\x{30AB}\x{30B2}",         "Hitokage" ],
    [ "5",  "Charmeleon", "Fire",     "",       "\x{30EA}\x{30B6}\x{30FC}\x{30C9}",         "Lizardo" ],
    [ "6",  "Charizard",  "Fire",     "Flying", "\x{30EA}\x{30B6}\x{30FC}\x{30C9}\x{30F3}", "Lizardon" ],
    [ "7",  "Squirtle",   "Water",    "",       "\x{30BC}\x{30CB}\x{30AC}\x{30E1}",         "Zenigame" ],
    [ "8",  "Wartortle",  "Water",    "",       "\x{30AB}\x{30E1}\x{30FC}\x{30EB}",         "Kameil" ],
    [ "9",  "Blastoise",  "Water",    "",       "\x{30AB}\x{30E1}\x{30C3}\x{30AF}\x{30B9}", "Kamex" ],
    [ "10", "Caterpie",   "Bug",      "",       "\x{30AD}\x{30E3}\x{30BF}\x{30D4}\x{30FC}", "Caterpie" ],
    [ "11", "Metapod",    "Bug",      "",       "\x{30C8}\x{30E9}\x{30F3}\x{30BB}\x{30EB}", "Trancell" ],
    [ "12", "Butterfree", "Bug",      "Flying", "\x{30D0}\x{30BF}\x{30D5}\x{30EA}\x{30FC}", "Butterfree" ],
    [ "13", "Weedle",     "Bug",      "Poison", "\x{30D3}\x{30FC}\x{30C9}\x{30EB}",         "Beedle" ],
    [ "14", "Kakuna",     "Bug",      "Poison", "\x{30B3}\x{30AF}\x{30FC}\x{30F3}",         "Cocoon" ],
    [ "15", "Beedrill",   "Bug",      "Poison", "\x{30B9}\x{30D4}\x{30A2}\x{30FC}",         "Spear" ],
    [ "16", "Pidgey",     "Normal",   "Flying", "\x{30DD}\x{30C3}\x{30DD}",                 "Poppo" ],
    [ "17", "Pidgeotto",  "Normal",   "Flying", "\x{30D4}\x{30B8}\x{30E7}\x{30F3}",         "Pigeon" ],
    [ "18", "Pidgeot",    "Normal",   "Flying", "\x{30D4}\x{30B8}\x{30E7}\x{30C3}\x{30C8}", "Pigeot" ],
    [ "19", "Rattata",    "Normal",   "",       "\x{30B3}\x{30E9}\x{30C3}\x{30BF}",         "Koratta" ],
    [ "20", "Raticate",   "Normal",   "",       "\x{30E9}\x{30C3}\x{30BF}",                 "Ratta" ],
    [ "21", "Spearow",    "Normal",   "Flying", "\x{30AA}\x{30CB}\x{30B9}\x{30BA}\x{30E1}", "Onisuzume" ],
    [ "22", "Fearow",     "Normal",   "Flying", "\x{30AA}\x{30CB}\x{30C9}\x{30EA}\x{30EB}", "Onidrill" ],
    [ "23", "Ekans",      "Poison",   "",       "\x{30A2}\x{30FC}\x{30DC}",                 "Arbo" ],
    [ "24", "Arbok",      "Poison",   "",       "\x{30A2}\x{30FC}\x{30DC}\x{30C3}\x{30AF}", "Arbok" ],
    [ "25", "Pikachu",    "Electric", "",       "\x{30D4}\x{30AB}\x{30C1}\x{30E5}\x{30A6}", "Pikachu" ],
    [ "26", "Raichu",     "Electric", "",       "\x{30E9}\x{30A4}\x{30C1}\x{30E5}\x{30A6}", "Raichu" ],
    [ "27", "Sandshrew",  "Ground",   "",       "\x{30B5}\x{30F3}\x{30C9}",                 "Sand" ],
    [ "28", "Sandslash",  "Ground",   "",       "\x{30B5}\x{30F3}\x{30C9}\x{30D1}\x{30F3}", "Sandpan" ]
);
my $t = NewTable->Border( NormalBorder() )->BorderStyle( NewStyle->foreground( Color("238") ) )->Headers(@headers)->Width(80)->Rows(@data);
$t->StyleFunc(
    sub {
        my ( $row, $col ) = @_;
        return $header_style   if $row == HEADER_ROW;
        return $selected_style if $data[$row][1] eq "Pikachu";
        my $even = $row % 2 == 0;
        if ( $col == 2 || $col == 3 ) {
            my $c     = $even ? \%dim_type_colors : \%type_colors;
            my $color = $c->{ $data[$row][$col] } // NoColor();
            return $base_style->foreground($color);
        }
        if ($even) {
            return $base_style->foreground( Color("245") );
        }
        return $base_style->foreground( Color("252") );
    }
);
Println($t);
