use v5.42;

package Cancer::CharmTone v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[
        Cumin Tang Yam Paprika Bengal Uni Sriracha Coral Salmon Chili
        Cherry Tuna Macaron Pony Cheeky Flamingo Dolly Blush Urchin Mochi
        Lilac Prince Violet Mauve Grape Plum Orchid Jelly Charple Hazy
        Ox Sapphire Guppy Oceania Thunder Anchovy Damson Malibu Sardine
        Zinc Turtle Lichen Guac Julep Bok Mustard Citron Zest Butter
        Pepper BBQ Char Iron Oyster Squid Steam Smoke Steep Sash Salt Soda
        Darple Larple Pickle Gator Spinach Pom Steak Toast Ice
        Charcoal
    ];

    # CharmTone palette as hex strings
    my %COLORS = (
        Cumin    => '#BF976F',
        Tang     => '#FF985A',
        Yam      => '#FFB587',
        Paprika  => '#D36C64',
        Bengal   => '#FF6E63',
        Uni      => '#FF937D',
        Sriracha => '#EB4268',
        Coral    => '#FF577D',
        Salmon   => '#FF7F90',
        Chili    => '#E23080',
        Cherry   => '#FF388B',
        Tuna     => '#FF6DAA',
        Macaron  => '#E940B0',
        Pony     => '#FF4FBF',
        Cheeky   => '#FF79D0',
        Flamingo => '#F947E3',
        Dolly    => '#FF60FF',
        Blush    => '#FF84FF',
        Urchin   => '#C337E0',
        Mochi    => '#EB5DFF',
        Lilac    => '#F379FF',
        Prince   => '#9C35E1',
        Violet   => '#C259FF',
        Mauve    => '#D46EFF',
        Grape    => '#7134DD',
        Plum     => '#9953FF',
        Orchid   => '#AD6EFF',
        Jelly    => '#4A30D9',
        Charple  => '#6B50FF',
        Hazy     => '#8B75FF',
        Ox       => '#3331B2',
        Sapphire => '#4949FF',
        Guppy    => '#7272FF',
        Oceania  => '#2B55B3',
        Thunder  => '#4776FF',
        Anchovy  => '#719AFC',
        Damson   => '#007AB8',
        Malibu   => '#00A4FF',
        Sardine  => '#4FBEFE',
        Zinc     => '#10B1AE',
        Turtle   => '#0ADCD9',
        Lichen   => '#5CDFEA',
        Guac     => '#12C78F',
        Julep    => '#00FFB2',
        Bok      => '#68FFD6',
        Mustard  => '#F5EF34',
        Citron   => '#E8FF27',
        Zest     => '#E8FE96',
        Butter   => '#FFFAF1',
        Pepper   => '#201F26',
        BBQ      => '#2D2C36',
        Char     => '#3A3943',
        Iron     => '#4D4C57',
        Oyster   => '#605F6B',
        Squid    => '#858392',
        Steam    => '#A2A0AD',
        Smoke    => '#BFBCC8',
        Steep    => '#D6D3DC',
        Sash     => '#ECEBF0',
        Salt     => '#F7F6FB',
        Soda     => '#FBFBFB',
        Darple   => '#5B40EC',
        Larple   => '#7B62FF',
        Pickle   => '#00A475',
        Gator    => '#18463D',
        Spinach  => '#1C3634',
        Pom      => '#AB2454',
        Steak    => '#582238',
        Toast    => '#412130',
        Ice      => '#00FFFC'
    );

    # Aliases
    $COLORS{Charcoal} = $COLORS{Char};

    # Create constant subs that return Cancer::Lipgloss Color objects
    for my $name ( keys %COLORS ) {
        no strict 'refs';
        my $hex = $COLORS{$name};
        my $pkg = __PACKAGE__;
        *{"${pkg}::${name}"} = sub {
            require Cancer::Lipgloss;
            return Cancer::Lipgloss::Color($hex);
        };
    }
}
1;
