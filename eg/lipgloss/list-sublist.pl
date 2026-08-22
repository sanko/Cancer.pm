use v5.42;
use lib 'lib';
use blib;
use utf8;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Println Color LightDark has_dark_background blend_1d Center Right Top Bottom];
use Cancer::Lipgloss::List qw[
    NewList DashEnumerator RomanEnumerator BulletEnumerator
];
my $hasDarkBG          = has_dark_background();
my $lightDark          = LightDark($hasDarkBG);
my $purple             = NewStyle->foreground( Color("99") )->margin_right(1);
my $pink               = NewStyle->foreground( Color("212") )->margin_right(1);
my $base               = NewStyle->margin_bottom(1)->margin_left(1);
my $faint              = NewStyle->faint(1);
my $dim                = Color("250");
my $highlight          = Color("#EE6FF8");
my $special            = $lightDark->( Color("#43BF6D"), Color("#73F59F") );
my $checklistEnumStyle = sub {
    my ( $items, $index ) = @_;
    if ( $index == 1 || $index == 2 || $index == 4 ) {
        return NewStyle->foreground($special)->padding_right(1);
    }
    return NewStyle->padding_right(1);
};
my $checklistEnum = sub {
    my ( $items, $index ) = @_;
    if ( $index == 1 || $index == 2 || $index == 4 ) {
        return "\x{2713}";    # ✓
    }
    return "\x{2022}";        # •
};
my $checklistStyle = sub {
    my ( $items, $index ) = @_;
    if ( $index == 1 || $index == 2 || $index == 4 ) {
        return NewStyle->strikethrough(1)->foreground( $lightDark->( Color("#969B86"), Color("#696969") ) );
    }
    return NewStyle();
};
my @gradient          = @{ blend_1d( 5, Color("#F25D94"), Color("#643AFF") ) };
my $titleStyle        = NewStyle->italic(1)->foreground( Color("#FFF7DB") );
my $lipglossStyleFunc = sub {
    my ( $items, $index ) = @_;
    my $len = scalar @$items;
    if ( $index == $len - 1 ) {
        return $titleStyle->padding(1)->clone->padding_top(1)
            ->padding_bottom(1)
            ->padding_left(2)
            ->padding_right(2)
            ->margin_top(0)
            ->margin_right(0)
            ->margin_bottom(1)
            ->margin_left(0)
            ->max_width(20)
            ->background( $gradient[$index] );
    }
    return $titleStyle->clone->padding(0)->clone->padding_top(0)
        ->padding_right( 5 - $index )
        ->padding_bottom(0)
        ->padding_left( $index + 2 )
        ->max_width(20)
        ->background( $gradient[$index] );
};
my $history
    = "Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac.";
my $l = NewList()->EnumeratorStyle($purple)->Item("Lip Gloss")->Item("Blush")->Item("Eye Shadow")->Item("Mascara")->Item("Foundation")->Item(
    NewList()->EnumeratorStyle($pink)->Item("Citrus Fruits to Try")->Item(
        NewList()
            ->ItemStyleFunc($checklistStyle)
            ->EnumeratorStyleFunc($checklistEnumStyle)
            ->Enumerator($checklistEnum)
            ->Item("Grapefruit")
            ->Item("Yuzu")
            ->Item("Citron")
            ->Item("Kumquat")
            ->Item("Pomelo")
    )->Item("Actual Lip Gloss Vendors")->Item(
        NewList()
            ->ItemStyleFunc($checklistStyle)
            ->EnumeratorStyleFunc($checklistEnumStyle)
            ->Enumerator($checklistEnum)
            ->Item("Glossier")
            ->Item("Claire's Boutique")
            ->Item("Nyx")
            ->Item("Mac")
            ->Item("Milk")
            ->Item(
            NewList()
                ->EnumeratorStyle($purple)
                ->Enumerator( sub { return DashEnumerator(@_) } )
                ->ItemStyleFunc($lipglossStyleFunc)
                ->Item("Lip Gloss")
                ->Item("Lip Gloss")
                ->Item("Lip Gloss")
                ->Item("Lip Gloss")
                ->Item(
                NewList()->EnumeratorStyle( NewStyle->foreground( $gradient[4] )->margin_right(1) )
                    ->Item("\nStyle Definitions for Nice Terminal Layouts\n\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}")
                    ->Item("From Charm")
                    ->Item("https://github.com/charmbracelet/lipgloss")
                    ->Item(
                    NewList()->EnumeratorStyle( NewStyle->foreground( $gradient[3] )->margin_right(1) )
                        ->Item("Emperors: Julio-Claudian dynasty")
                        ->Item(
                        NewStyle->padding(1)->render(
                            NewList( "Augustus", "Tiberius", "Caligula", "Claudius", "Nero" )
                                ->Enumerator( sub { return RomanEnumerator(@_) } )
                                ->String()
                        )
                        )->Item(
                        NewStyle->bold(1)
                            ->foreground( Color("#FAFAFA") )
                            ->background( Color("#7D56F4") )
                            ->align(Center)
                            ->align_vertical(Center)
                            ->padding(1)
                            ->clone->padding_top(1)
                            ->padding_right(3)
                            ->padding_bottom(1)
                            ->padding_left(3)
                            ->margin_top(0)
                            ->margin_right(1)
                            ->margin_bottom(1)
                            ->margin_left(1)
                            ->width(40)
                            ->render($history)
                        )->Item(
                        do {
                            require Cancer::Lipgloss::Table;
                            Cancer::Lipgloss::Table::NewTable()->Width(30)->BorderStyle( $purple->margin_right(0) )->StyleFunc(
                                sub {
                                    my ( $row, $col ) = @_;
                                    my $style = NewStyle();
                                    if ( $col == 0 ) {
                                        $style = $style->align(Center);
                                    }
                                    else {
                                        $style = $style->align(Right)->padding_right(2);
                                    }
                                    if ( $row == 0 ) {
                                        return $style->bold(1)->align(Center)->padding_right(0);
                                    }
                                    return $style->faint(1);
                                }
                                )
                                ->Headers( "ITEM", "QUANTITY" )
                                ->Row( "Apple",      "6" )
                                ->Row( "Banana",     "10" )
                                ->Row( "Orange",     "2" )
                                ->Row( "Strawberry", "12" ),;
                        }
                        )->Item("Documents")->Item(
                        NewList()->Enumerator(
                            sub {
                                my ( undef, $i ) = @_;
                                if ( $i == 1 ) { return "\x{2502}\n\x{2502}"; }
                                return " ";
                            }
                        )->ItemStyleFunc(
                            sub {
                                my ( undef, $i ) = @_;
                                if ( $i == 1 ) {
                                    return $base->foreground($highlight);
                                }
                                return $base->foreground($dim);
                            }
                        )->EnumeratorStyleFunc(
                            sub {
                                my ( undef, $i ) = @_;
                                if ( $i == 1 ) {
                                    return NewStyle->foreground($highlight);
                                }
                                return NewStyle->foreground($dim);
                            }
                            )
                            ->Item( "Foo Document\n" . $faint->render("1 day ago") )
                            ->Item( "Bar Document\n" . $faint->render("2 days ago") )
                            ->Item( "Baz Document\n" . $faint->render("10 minutes ago") )
                            ->Item( "Qux Document\n" . $faint->render("1 month ago") )
                        )->Item("EOF")
                    )->Item("go get github.com/charmbracelet/lipgloss/list\n")
                )->Item("See ya later")
            )
    )->Item("List")
)->Item("xoxo, Charm_\x{2122}");
binmode STDOUT, ':encoding(UTF-8)';
print $l;
print "\n";
