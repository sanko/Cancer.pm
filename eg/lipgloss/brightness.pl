use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss qw[
    NewStyle Color Println has_dark_background LightDark
];
use Cancer::Color::Blend qw[lighten darken];
my $has_dark_bg      = has_dark_background();
my $light_dark       = LightDark($has_dark_bg);
my %base_colors      = ( Red => Color("#FF0000"), Blue => Color("#0066FF"), Green => Color("#00FF00"), Gray => Color("#808080") );
my $percentage       = 0.05;
my $steps            = 20;
my $color_name_style = NewStyle->bold(1)->foreground( $light_dark->( Color("#2D3748"), Color("#E2E8F0") ) );
my $content          = '';

for my $name ( sort keys %base_colors ) {
    my $base = $base_colors{$name};
    $content .= $color_name_style->render($name) . "\n";
    my $lightened = "Lightened: ";
    for my $i ( 0 .. $steps - 1 ) {
        my $c = lighten( $base, $percentage * ( $i + 1 ) );
        $lightened .= NewStyle->foreground($c)->render("\x{2588}\x{2588}");
    }
    $content .= $lightened . "\n";
    my $darkened = "Darkened:  ";
    for my $i ( 0 .. $steps - 1 ) {
        my $c = darken( $base, $percentage * ( $i + 1 ) );
        $darkened .= NewStyle->foreground($c)->render("\x{2588}\x{2588}");
    }
    $content .= $darkened . "\n\n";
}
Println($content);
