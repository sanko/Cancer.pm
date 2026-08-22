use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss qw[
    NewStyle Color Println JoinVertical NormalBorder RoundedBorder Center
    has_dark_background LightDark
];
use Cancer::Color::Blend qw[blend_1d];
my $has_dark_bg = has_dark_background();
my $light_dark  = LightDark($has_dark_bg);
my @gradients   = (
    [ Color("#FF6B6B"), Color("#FFB74D"), Color("#FFDFBA") ],
    [ Color("#0077B6"), Color("#48CAE4"), Color("#ADE8F4") ],
    [ Color("#228B22"), Color("#90EE90"), Color("#FFFFE0") ],
    [ Color("#9370DB"), Color("#DDA0DD"), Color("#FFB6C1") ],
    [ Color("#9900FF"), Color("#00FA68"), Color("#ED5353") ]
);
my $title_style    = NewStyle->bold(1)->foreground( $light_dark->( Color("#2D3748"), Color("#E2E8F0") ) )->margin_bottom(1)->align(Center);
my $gradient_style = NewStyle->border(RoundedBorder)->border_foreground( $light_dark->( Color("#718096"), Color("#A0AEC0") ) );
my $content        = $title_style->render("Color Gradient Examples with Blend1D") . "\n";

for my $gradient (@gradients) {
    my @blended = @{ blend_1d( 40, @$gradient ) };
    my $bar     = join '', map { NewStyle->foreground($_)->render("\x{2588}") } @blended;
    $content .= $gradient_style->render($bar) . "\n";
}
Println($content);
