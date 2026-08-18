use Test2::V1 -ipP;
use Cancer::Ansi qw(
    color_to_hex_string hex_to_rgb ansi_to_rgb convert_256
);
subtest 'TestRGBAToHex' => sub {
    my @cases = (
        { hex => 0x0000ff, r => 0,   g => 0,   b => 255 },
        { hex => 0xffffff, r => 255, g => 255, b => 255 },
        { hex => 0xff0000, r => 255, g => 0,   b => 0 },
    );
    for my $c (@cases) {
        my ( $r, $g, $b ) = hex_to_rgb( $c->{hex} );
        is $r, $c->{r}, "TrueColor($c->{hex}) R";
        is $g, $c->{g}, "TrueColor($c->{hex}) G";
        is $b, $c->{b}, "TrueColor($c->{hex}) B";
    }
};
subtest 'TestColorToHexString' => sub {
    my @cases = ( { hex => 0x0000ff, want => '#0000ff' }, { hex => 0xffffff, want => '#ffffff' }, { hex => 0xff0000, want => '#ff0000' }, );
    for my $c (@cases) {
        is color_to_hex_string( $c->{hex} ), $c->{want}, "color_to_hex_string($c->{hex})";
    }
};
subtest 'TestAnsiToRGB' => sub {
    my @cases = (
        { ansi => 0,   r => 0x00, g => 0x00, b => 0x00 },
        { ansi => 1,   r => 0x80, g => 0x00, b => 0x00 },
        { ansi => 255, r => 0xee, g => 0xee, b => 0xee },
    );
    for my $c (@cases) {
        my ( $r, $g, $b ) = ansi_to_rgb( $c->{ansi} );
        is $r, $c->{r}, "ansi_to_rgb($c->{ansi}) R";
        is $g, $c->{g}, "ansi_to_rgb($c->{ansi}) G";
        is $b, $c->{b}, "ansi_to_rgb($c->{ansi}) B";
    }
};
subtest 'TestHexToRGB' => sub {
    my @cases = (
        { hex => 0x0000FF, r => 0,   g => 0,   b => 255 },
        { hex => 0xFFFFFF, r => 255, g => 255, b => 255 },
        { hex => 0xFF0000, r => 255, g => 0,   b => 0 },
    );
    for my $c (@cases) {
        my ( $r, $g, $b ) = hex_to_rgb( $c->{hex} );
        is $r, $c->{r}, "hex_to_rgb($c->{hex}) R";
        is $g, $c->{g}, "hex_to_rgb($c->{hex}) G";
        is $b, $c->{b}, "hex_to_rgb($c->{hex}) B";
    }
};
subtest 'TestHexTo256' => sub {
    my %cases = (
        'white'                             => { hex => '#ffffff', want => 231 },
        'offwhite'                          => { hex => '#eeeeee', want => 255 },
        'slightly brighter than offwhite'   => { hex => '#f2f2f2', want => 255 },
        'red'                               => { hex => '#ff0000', want => 196 },
        'silver foil'                       => { hex => '#afafaf', want => 145 },
        'silver chalice'                    => { hex => '#b2b2b2', want => 249 },
        'slightly closer to silver foil'    => { hex => '#b0b0b0', want => 145 },
        'slightly closer to silver chalice' => { hex => '#b1b1b1', want => 249 },
        'gray'                              => { hex => '#808080', want => 244 },
    );
    for my $name ( keys %cases ) {
        my $c   = $cases{$name};
        my $hex = hex( substr $c->{hex}, 1 );
        my $got = convert_256($hex);
        is $got, $c->{want}, "$name ($c->{hex}) -> $c->{want}";
    }
};
done_testing;
