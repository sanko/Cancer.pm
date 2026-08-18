use v5.42;
use experimental 'class';
use utf8;
use Test2::V1 -ipP;
use Cancer::Util qw[truncate truncate_left cut byte_to_grapheme_range];

# Ported from charm/x/ansi/truncate_test.go
# Tests: Truncate, TruncateLeft, Cut, ByteToGraphemeRange
my @tcases = (
    [ 'empty',                 '',                              '',  0,  '',                           '' ],
    [ 'truncate_length_0',     'foo',                           '',  0,  '',                           'foo' ],
    [ 'equalascii',            'one',                           '.', 3,  'one',                        '' ],
    [ 'equalemoji',            "on\x{1F44B}",                   '.', 3,  "on.",                        ".\x{1F44B}" ],
    [ 'simple multiple words', 'a couple of words',             '',  6,  'a coup',                     'le of words' ],
    [ 'simple',                'foobar',                        '',  3,  'foo',                        'bar' ],
    [ 'passthrough',           'foobar',                        '',  10, 'foobar',                     '' ],
    [ 'ascii',                 'hello',                         '',  3,  'hel',                        'lo' ],
    [ 'emoji',                 "\x{1F44B}",                     '',  2,  "\x{1F44B}",                  '' ],
    [ 'wideemoji',             "\x{1FAE7}",                     '',  2,  "\x{1FAE7}",                  '' ],
    [ 'controlemoji',          "\e[31mhello \x{1F44B}abc\e[0m", '',  8,  "\e[31mhello \x{1F44B}\e[0m", "\e[31mabc\e[0m" ],
    [   'osc8', "\e]8;;https://charm.sh\e\\Charmbracelet \x{1FAE7}\e]8;;\e\\",
        '',     5,
        "\e]8;;https://charm.sh\e\\Charm\e]8;;\e\\",
        "\e]8;;https://charm.sh\e\\bracelet \x{1FAE7}\e]8;;\e\\"
    ],
    [ 'style_tail', "\e[38;5;219mHiya!", "\x{2026}", 3, "\e[38;5;219mHi\x{2026}", "\e[38;5;219m\x{2026}a!" ],
    [   'double_style_tail',                      "\e[38;5;219mHiya!\e[38;5;219mHello",
        "\x{2026}",                               7,
        "\e[38;5;219mHiya!\e[38;5;219mH\x{2026}", "\e[38;5;219m\e[38;5;219m\x{2026}llo"
    ],
    [ 'truncate_with_tail', 'foobar', '.', 4, 'foo.', '.ar' ],
);
subtest 'TestTruncate' => sub {
    for my $c (@tcases) {
        my ( $name, $input, $extra, $width, $expect_right ) = @$c;
        is truncate( $input, $width, $extra ), $expect_right, "truncate $name" or diag "input: $input";
    }
};
subtest 'TestTruncateLeft' => sub {
    for my $c (@tcases) {
        my ( $name, $input, $extra, $width, undef, $expect_left ) = @$c;
        is truncate_left( $input, $width, $extra ), $expect_left, "truncate_left $name" or diag "input: $input";
    }
};
subtest 'TestCut' => sub {
    my @cut_cases = (
        [ 'simple string',        'This is a long string',                     2, 6,  'is i' ],
        [ 'with ansi',            "I really \e[38;2;249;38;114mlove\e[0m Go!", 4, 25, "ally \e[38;2;249;38;114mlove\e[0m Go!" ],
        [ 'left is 0',            "Foo \e[38;2;249;38;114mbar\e[0mbaz",        0, 5,  "Foo \e[38;2;249;38;114mb\e[0m" ],
        [ 'right is 0',           "\e[7mHello\e[m",                            3, 0,  '' ],
        [ 'right less than left', "\e[7mHello\e[m",                            3, 2,  '' ],
        [ 'cut size is 0',        "\e[7mHello\e[m",                            2, 2,  '' ],
        [ 'maintains open ansi',  "\e[38;5;212;48;5;63mHello, Artichoke!\e[m", 7, 16, "\e[38;5;212;48;5;63mArtichoke\e[m" ],
        [   'multiline', "\n\e[38;2;98;98;98m\nif [ -f RE\nADME.md ]; then\e[m\n\e[38;2;98;98;98m    echo oi\e[m\n\e[38;2;98;98;98mfi\e[m\n",
            8, 13, "\e[38;2;98;98;98mRE\nADM\e[m\e[38;2;98;98;98m\e[m\e[38;2;98;98;98m\e[m"
        ]
    );
    for my $c (@cut_cases) {
        my ( $name, $input, $left, $right, $expect ) = @$c;
        is cut( $input, $left, $right ), $expect, "cut $name" or diag "input: $input";
    }
};
subtest 'TestByteToGraphemeRange' => sub {
    my @gb_cases = (
        [ 'simple',     'hello world from x/ansi', [  2, 9 ],  [ 2, 9 ] ],
        [ 'with emoji', "\x{e718} Downloads",      [  4, 7 ],  [ 2, 5 ] ],
        [ 'start ob',   'some text',               [ -1, 5 ],  [ 0, 5 ] ],
        [ 'end ob',     'some text',               [  1, 50 ], [ 1, 9 ] ],
    );
    for my $c (@gb_cases) {
        my ( $name, $input, $feed, $expect ) = @$c;
        my ( $got_start, $got_stop ) = byte_to_grapheme_range( $input, $feed->[0], $feed->[1] );
        is $got_start, $expect->[0], "byte_to_grapheme_range $name start";
        is $got_stop,  $expect->[1], "byte_to_grapheme_range $name stop";
    }
};
done_testing;
