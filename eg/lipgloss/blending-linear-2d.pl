use v5.42;
use lib 'lib';
use blib;
use utf8;
use Cancer::Lipgloss     qw[NewStyle Color has_dark_background LightDark Println RoundedBorder];
use Cancer::Color::Blend qw[blend_2d];
binmode STDOUT, ':unix:utf8';
my $has_dark_bg = has_dark_background();
my $light_dark  = LightDark($has_dark_bg);
my @gradients   = (
    {   name  => "Sunset Diagonal",
        stops => [
            Color("#FF6B6B"),    # Coral
            Color("#FFB74D"),    # Orange
            Color("#FFDFBA")     # Peach
        ],
        angle => 45
    },
    {   name  => "Ocean Wave",
        stops => [
            Color("#0077B6"),    # Deep blue
            Color("#48CAE4"),    # Sky blue
            Color("#ADE8F4")     # Light blue
        ],
        angle => 90
    },
    {   name  => "Forest Mist",
        stops => [
            Color("#228B22"),    # Forest green
            Color("#90EE90"),    #Light green
            Color("#FFFFE0")     # Cream
        ],
        angle => 135
    },
    {   name  => "Purple Dream",
        stops => [
            Color("#9370DB"),    # Light purple
            Color("#DDA0DD"),    # Plum
            Color("#FFB6C1")     # Light pink
        ],
        angle => 180
    },
    {   name  => "Fire Gradient",
        stops => [
            Color("#FF0000"),    # Red
            Color("#FFA500"),    # Orange
            Color("#FFFF00")     # Yellow
        ],
        angle => 225
    }
);
my $title_style    = NewStyle->bold(1)->foreground( $light_dark->( Color("#2D3748"), Color("#E2E8F0") ) )->margin_bottom(1)->align(0.5);
my $gradient_style = NewStyle->border( RoundedBorder() )->border_foreground( $light_dark->( Color("#718096"), Color("#A0AEC0") ) )->margin_bottom(1);
my $gradient_name_style = NewStyle->bold(1)->foreground( $light_dark->( Color("#4A5568"), Color("#CBD5E0") ) )->margin_bottom(1);
my $content             = $title_style->render("2D Color Gradient Examples with Blend2D") . "\n\n";
for my $gradient (@gradients) {
    my ( $w, $h ) = ( 30, 12 );
    my $colors       = blend_2d( $w, $h, $gradient->{angle}, @{ $gradient->{stops} } );
    my $gradient_box = '';
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $index = $y * $w + $x;
            $gradient_box .= NewStyle->foreground( $colors->[$index] )->render("█");
        }
        $gradient_box .= "\n" if $y < $h - 1;
    }
    $content .= $gradient_name_style->render( sprintf( "%s (Angle: %.0f°)", $gradient->{name}, $gradient->{angle} ) );
    $content .= "\n";
    $content .= $gradient_style->render($gradient_box);
    $content .= "\n";
}
Println($content);
