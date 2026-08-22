use v5.42;
use lib 'lib';
use blib;
use Cancer::Lipgloss qw[
    NewStyle Color RoundedBorder Println Center
    LightDark
    NewLayer NewCompositor
];
use Cancer::CharmTone qw[Cherry Charple Guac Sriracha Iron Butter Smoke Pepper Squid Charcoal];

sub new_field {
    my ( $rows, $cols, $color ) = @_;
    my $style = NewStyle->foreground($color);
    my $str   = '';
    for my $i ( 0 .. $rows - 1 ) {
        $str .= '/' x $cols;
        $str .= "\n" if $i < $rows - 1;
    }
    return $style->render($str);
}

sub new_card {
    my ( $dark_mode, $text ) = @_;
    my $light_dark = LightDark($dark_mode);
    return NewStyle->border(RoundedBorder)
        ->border_foreground_blend( Cherry(), Charple(), Guac(), Charple(), Sriracha() )
        ->foreground( $light_dark->( Iron(), Butter() ) )
        ->height(9)
        ->width(16)
        ->padding_top(3)
        ->align(Center)
        ->render($text);
}
my $dark_mode     = 1;
my $light_dark    = LightDark($dark_mode);
my $lighter_field = new_field( 17, 43, $light_dark->( Smoke(), Pepper() ) );
my $darker_field  = new_field( 17, 43, $light_dark->( Squid(), Charcoal() ) );
my $pickles       = NewLayer( new_card( $dark_mode, "Pickles" ) );
my $melon         = NewLayer( new_card( $dark_mode, "Bitter Melon" ) );
my $sriracha      = NewLayer( new_card( $dark_mode, "Sriracha" ) );
my @layers        = (
    NewLayer($lighter_field)->X(5)->Y(2),
    NewLayer($darker_field)->AddLayers( $pickles->X(4)->Y(2)->Z(1), $melon->X(22)->Y(1), $sriracha->X(11)->Y(7) )
);
my $comp = NewCompositor(@layers);
Println( $comp->render );
