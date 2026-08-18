use Test2::V1 -ipP;
use Cancer::Ansi qw(set_palette);
subtest 'TestSetPalette' => sub {
    my @cases = (
        { index => -1, r => 255, g => 0,   b => 0,   want => '' },
        { index =>  0, r => 255, g => 0,   b => 0,   want => "\e]P0ff0000\a" },
        { index =>  1, r => 0,   g => 255, b => 0,   want => "\e]P100ff00\a" },
        { index =>  2, r => 0,   g => 0,   b => 255, want => "\e]P20000ff\a" },
        { index =>  3, r => 255, g => 255, b => 0,   want => "\e]P3ffff00\a" },
        { index =>  4, r => 255, g => 0,   b => 255, want => "\e]P4ff00ff\a" },
        { index =>  5, r => 0,   g => 255, b => 255, want => "\e]P500ffff\a" },
        { index =>  6, r => 192, g => 192, b => 192, want => "\e]P6c0c0c0\a" },
        { index =>  7, r => 128, g => 128, b => 128, want => "\e]P7808080\a" },
        { index =>  8, r => 255, g => 128, b => 128, want => "\e]P8ff8080\a" },
        { index =>  9, r => 128, g => 255, b => 128, want => "\e]P980ff80\a" },
        { index => 10, r => 128, g => 128, b => 255, want => "\e]Pa8080ff\a" },
        { index => 11, r => 255, g => 255, b => 128, want => "\e]Pbffff80\a" },
        { index => 12, r => 255, g => 128, b => 255, want => "\e]Pcff80ff\a" },
        { index => 13, r => 128, g => 255, b => 255, want => "\e]Pd80ffff\a" },
        { index => 14, r => 192, g => 192, b => 192, want => "\e]Pec0c0c0\a" },
        { index => 15, r => 0,   g => 0,   b => 0,   want => "\e]Pf000000\a" },
        { index => 16, r => 255, g => 0,   b => 0,   want => '' },
    );
    for my $c (@cases) {
        my $got = set_palette( $c->{index}, $c->{r}, $c->{g}, $c->{b} );
        is $got, $c->{want}, "SetPalette($c->{index}, $c->{r}, $c->{g}, $c->{b})";
    }
};
done_testing;
