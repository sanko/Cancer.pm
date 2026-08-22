use v5.42;
use lib 'lib';
use blib;
use utf8;
use Cancer::Lipgloss        qw[NewStyle Color Println ThickBorder];
use Cancer::Lipgloss::Table qw[NewTable HEADER_ROW];
binmode STDOUT, ':unix:utf8';
my $purple       = Color("99");
my $gray         = Color("245");
my $light_gray   = Color("241");
my $header_style = NewStyle->foreground($purple)->bold(1)->align(0.5);
my $cell_style   = NewStyle->padding( 0, 1 )->width(14);
my $odd_style    = $cell_style->foreground($gray);
my $even_style   = $cell_style->foreground($light_gray);
my $border_style = NewStyle->foreground($purple);
my @rows         = (
    [ "Chinese",  "您好",           "你好" ],
    [ "Japanese", "こんにちは",        "やあ" ],
    [ "Arabic",   "أهلين",        "أهلا" ],
    [ "Russian",  "Здравствуйте", "Привет" ],
    [ "Spanish",  "Hola",         "¿Qué tal?" ]
);
my $t = NewTable->Border( ThickBorder() )->BorderStyle($border_style)->Headers( "LANGUAGE", "FORMAL", "INFORMAL" )->Rows(@rows);
$t->Row( "English", "You look absolutely fabulous.", "How's it going?" );
$t->StyleFunc(
    sub {
        my ( $row, $col ) = @_;
        if ( $row == HEADER_ROW ) {
            return $header_style;
        }
        my $style = $row % 2 == 0 ? $even_style : $odd_style;
        if ( $col == 1 ) {
            $style = $style->width(22);
        }
        if ( $row < scalar @rows && $rows[$row][0] eq "Arabic" && $col != 0 ) {
            $style = $style->align(1.0);
        }
        return $style;
    }
);
Println($t);
