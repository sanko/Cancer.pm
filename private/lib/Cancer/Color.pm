use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';

package Cancer::Color {

    class Cancer::Color::Triplet {
        field $red : param : reader;
        field $green : param : reader;
        field $blue : param : reader;
        method hex()        { sprintf '#%02x%02x%02x', $red, $green, $blue }
        method rgb()        { sprintf 'rgb(%d,%d,%d)', $red, $green, $blue }
        method normalized() { ( $red / 255, $green / 255, $blue / 255 ) }
    };

    class Cancer::ColorSystem {
        use overload '""' => sub ( $s, $etc, $blah ) { $s->class };
        method class() {__CLASS__}
    };

    class Cancer::ColorSystem::STANDARD : isa(Cancer::ColorSystem) {
        use overload int => sub {1};
    };

    class Cancer::ColorSystem::EIGHT_BIT : isa(Cancer::ColorSystem) {
        use overload int => sub {2};
    };

    class Cancer::ColorSystem::TRUECOLOR : isa(Cancer::ColorSystem) {
        use overload int => sub {3};
    };

    class Cancer::ColorSystem::WINDOWS : isa(Cancer::ColorSystem) {
        use overload int => sub {4};
    };

    class Cancer::ColorType {
        use overload '""' => sub ( $s, $etc, $blah ) { $s->class };
        method class() {__CLASS__}
    };

    class Cancer::ColorType::DEFAULT : isa(Cancer::ColorType) {
        use overload int => sub {0};
    };

    class Cancer::ColorType::STANDARD : isa(Cancer::ColorType) {
        use overload int => sub {1};
    };

    class Cancer::ColorType::EIGHT_BIT : isa(Cancer::ColorType) {
        use overload int => sub {2};
    };

    class Cancer::ColorType::TRUECOLOR : isa(Cancer::ColorType) {
        use overload int => sub {3};
    };

    class Cancer::ColorType::WINDOWS : isa(Cancer::ColorType) {
        use overload int => sub {4};
    };
    our $ANSI_COLOR_NAMES = {
        black               => 0,
        red                 => 1,
        green               => 2,
        yellow              => 3,
        blue                => 4,
        magenta             => 5,
        cyan                => 6,
        white               => 7,
        bright_black        => 8,
        bright_red          => 9,
        bright_green        => 10,
        bright_yellow       => 11,
        bright_blue         => 12,
        bright_magenta      => 13,
        bright_cyan         => 14,
        bright_white        => 15,
        grey0               => 16,
        gray0               => 16,
        navy_blue           => 17,
        dark_blue           => 18,
        blue3               => 20,
        blue1               => 21,
        dark_green          => 22,
        deep_sky_blue4      => 25,
        dodger_blue3        => 26,
        dodger_blue2        => 27,
        green4              => 28,
        spring_green4       => 29,
        turquoise4          => 30,
        deep_sky_blue3      => 32,
        dodger_blue1        => 33,
        green3              => 40,
        spring_green3       => 41,
        dark_cyan           => 36,
        light_sea_green     => 37,
        deep_sky_blue2      => 38,
        deep_sky_blue1      => 39,
        spring_green2       => 47,
        cyan3               => 43,
        dark_turquoise      => 44,
        turquoise2          => 45,
        green1              => 46,
        spring_green1       => 48,
        medium_spring_green => 49,
        cyan2               => 50,
        cyan1               => 51,
        dark_red            => 88,
        deep_pink4          => 125,
        purple4             => 55,
        purple3             => 56,
        blue_violet         => 57,
        orange4             => 94,
        grey37              => 59,
        gray37              => 59,
        medium_purple4      => 60,
        slate_blue3         => 62,
        royal_blue1         => 63,
        chartreuse4         => 64,
        dark_sea_green4     => 71,
        pale_turquoise4     => 66,
        steel_blue          => 67,
        steel_blue3         => 68,
        cornflower_blue     => 69,
        chartreuse3         => 76,
        cadet_blue          => 73,
        sky_blue3           => 74,
        steel_blue1         => 81,
        pale_green3         => 114,
        sea_green3          => 78,
        aquamarine3         => 79,
        medium_turquoise    => 80,
        chartreuse2         => 112,
        sea_green2          => 83,
        sea_green1          => 85,
        aquamarine1         => 122,
        dark_slate_gray2    => 87,
        dark_magenta        => 91,
        dark_violet         => 128,
        purple              => 129,
        light_pink4         => 95,
        plum4               => 96,
        medium_purple3      => 98,
        slate_blue1         => 99,
        yellow4             => 106,
        wheat4              => 101,
        grey53              => 102,
        gray53              => 102,
        light_slate_grey    => 103,
        light_slate_gray    => 103,
        medium_purple       => 104,
        light_slate_blue    => 105,
        dark_olive_green3   => 149,
        dark_sea_green      => 108,
        light_sky_blue3     => 110,
        sky_blue2           => 111,
        dark_sea_green3     => 150,
        dark_slate_gray3    => 116,
        sky_blue1           => 117,
        chartreuse1         => 118,
        light_green         => 120,
        pale_green1         => 156,
        dark_slate_gray1    => 123,
        red3                => 160,
        medium_violet_red   => 126,
        magenta3            => 164,
        dark_orange3        => 166,
        indian_red          => 167,
        hot_pink3           => 168,
        medium_orchid3      => 133,
        medium_orchid       => 134,
        medium_purple2      => 140,
        dark_goldenrod      => 136,
        light_salmon3       => 173,
        rosy_brown          => 138,
        grey63              => 139,
        gray63              => 139,
        medium_purple1      => 141,
        gold3               => 178,
        dark_khaki          => 143,
        navajo_white3       => 144,
        grey69              => 145,
        gray69              => 145,
        light_steel_blue3   => 146,
        light_steel_blue    => 147,
        yellow3             => 184,
        dark_sea_green2     => 157,
        light_cyan3         => 152,
        light_sky_blue1     => 153,
        green_yellow        => 154,
        dark_olive_green2   => 155,
        dark_sea_green1     => 193,
        pale_turquoise1     => 159,
        deep_pink3          => 162,
        magenta2            => 200,
        hot_pink2           => 169,
        orchid              => 170,
        medium_orchid1      => 207,
        orange3             => 172,
        light_pink3         => 174,
        pink3               => 175,
        plum3               => 176,
        violet              => 177,
        light_goldenrod3    => 179,
        tan                 => 180,
        misty_rose3         => 181,
        thistle3            => 182,
        plum2               => 183,
        khaki3              => 185,
        light_goldenrod2    => 222,
        light_yellow3       => 187,
        grey84              => 188,
        gray84              => 188,
        light_steel_blue1   => 189,
        yellow2             => 190,
        dark_olive_green1   => 192,
        honeydew2           => 194,
        light_cyan1         => 195,
        red1                => 196,
        deep_pink2          => 197,
        deep_pink1          => 199,
        magenta1            => 201,
        orange_red1         => 202,
        indian_red1         => 204,
        hot_pink            => 206,
        dark_orange         => 208,
        salmon1             => 209,
        light_coral         => 210,
        pale_violet_red1    => 211,
        orchid2             => 212,
        orchid1             => 213,
        orange1             => 214,
        sandy_brown         => 215,
        light_salmon1       => 216,
        light_pink1         => 217,
        pink1               => 218,
        plum1               => 219,
        gold1               => 220,
        navajo_white1       => 223,
        misty_rose1         => 224,
        thistle1            => 225,
        yellow1             => 226,
        light_goldenrod1    => 227,
        khaki1              => 228,
        wheat1              => 229,
        cornsilk1           => 230,
        grey100             => 231,
        gray100             => 231,
        grey3               => 232,
        gray3               => 232,
        grey7               => 233,
        gray7               => 233,
        grey11              => 234,
        gray11              => 234,
        grey15              => 235,
        gray15              => 235,
        grey19              => 236,
        gray19              => 236,
        grey23              => 237,
        gray23              => 237,
        grey27              => 238,
        gray27              => 238,
        grey30              => 239,
        gray30              => 239,
        grey35              => 240,
        gray35              => 240,
        grey39              => 241,
        gray39              => 241,
        grey42              => 242,
        gray42              => 242,
        grey46              => 243,
        gray46              => 243,
        grey50              => 244,
        gray50              => 244,
        grey54              => 245,
        gray54              => 245,
        grey58              => 246,
        gray58              => 246,
        grey62              => 247,
        gray62              => 247,
        grey66              => 248,
        gray66              => 248,
        grey70              => 249,
        gray70              => 249,
        grey74              => 250,
        gray74              => 250,
        grey78              => 251,
        gray78              => 251,
        grey82              => 252,
        gray82              => 252,
        grey85              => 253,
        gray85              => 253,
        grey89              => 254,
        gray89              => 254,
        grey93              => 255,
        gray93              => 255
    };
    our $RE_COLOR = qr[
    ^(?:
        \#([0-9a-f]{6})$|       # #ffffff
        color\(([0-9]{1,3})\)$| # color(white)
        rgb\(([\d\s,]+)\)       # rgb(255, 255, 255)
    )$]x;

    class Cancer::Color {
        use overload '""' => sub ( $s, $etc ) {
            Cancer::Text->assemble(
                '<color %s (%s)%s>', $s->name, lc $s->type->name,
                ( '⬤', Cancer::Style->new( color => $s ) )    # This is supposed to be a dot the color of this object
            );
        };
        field $name : param : reader;
        field $type : param : reader;
        field $number : param  //= ();
        field $triplet : param //= ();    # Cancer::Color::Triplet

        #
        method _data_printer($ddp) {
            "$self";
        }
        #
        method system() {
            return Cancer::ColorSystem::STANDARD() if $type == Cancer::ColorType::DEFAULT();
            return Cancer::ColorSystem->new( type => int $type );
        }

        method is_system_defined() {
        }
    };
};
1;
__END__
=encoding utf-8

=head1 NAME

Cancer::Text - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;
    ...;

=head1 DESCRIPTION

Rich console stuff

=head1 See Also

TODO

=head1 LICENSE

This software is Copyright (c) 2024 by Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=begin stopwords


=end stopwords

=cut


