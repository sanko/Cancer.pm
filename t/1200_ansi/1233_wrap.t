use v5.42;
use experimental 'class';
use utf8;
use Test2::V1 -ipP;
use Cancer::Util qw[hardwrap wordwrap wrap];
my @hcases = (
    [ 'empty string',  '',               0, 1, '' ],
    [ 'passthrough',   "foobar\n ",      0, 1, "foobar\n " ],
    [ 'pass',          'foo',            4, 1, 'foo' ],
    [ 'simple',        'foobarfoo',      4, 1, "foob\narfo\no" ],
    [ 'lf',            "f\no\nobar",     3, 1, "f\no\noba\nr" ],
    [ 'tab',           "foo\tbar",       3, 1, "foo\n\tbar" ],
    [ 'unicode_space', "foo\x{00a0}bar", 3, 0, "foo\nbar" ],
    [   'style', "\e[38;2;249;38;114m(\e[0m\e[38;2;248;248;242mjust another test\e[38;2;249;38;114m)\e[0m",
        3, 1, "\e[38;2;249;38;114m(\e[0m\e[38;2;248;248;242mju\nst \nano\nthe\nr t\nest\e[38;2;249;38;114m\n)\e[0m"
    ],
    [ 'emoji',  "foo\x{1FAE7}foobar", 4, 0, "foo\n\x{1FAE7}fo\nobar" ],
    [ 'column', 'VERTICAL',           1, 0, "V\nE\nR\nT\nI\nC\nA\nL" ]
);
subtest 'TestHardwrap' => sub {
    for my $c (@hcases) {
        my ( $name, $input, $limit, $preserve, $expected ) = @$c;
        is hardwrap( $input, $limit, $preserve ), $expected, "hardwrap $name" or diag "input: $input";
    }
};
my @wwcases = (
    [ 'empty string', '',                 0, '',  '' ],
    [ 'passthrough',  "foobar\n ",        0, '',  "foobar\n " ],
    [ 'pass',         'foo',              3, '',  'foo' ],
    [ 'toolong',      'foobarfoo',        4, '',  'foobarfoo' ],
    [ 'white space',  'foo bar foo',      4, '',  "foo\nbar\nfoo" ],
    [ 'hyphen',       'foo-foobar',       4, '-', "foo-\nfoobar" ],
    [ 'simple',       'foo bars foobars', 4, '',  "foo\nbars\nfoobars" ],
    [ 'limit',        'foo bar',          5, '',  "foo\nbar" ],
    [   'style_code_dont_affect_length',
        "\e[38;2;249;38;114mfoo\e[0m\e[38;2;248;248;242m \e[0m\e[38;2;230;219;116mbar\e[0m",
        7, '', "\e[38;2;249;38;114mfoo\e[0m\e[38;2;248;248;242m \e[0m\e[38;2;230;219;116mbar\e[0m"
    ],
    [   'style_code_dont_get_wrapped', "\e[38;2;249;38;114m(\e[0m\e[38;2;248;248;242mjust another test\e[38;2;249;38;114m)\e[0m",
        3, '', "\e[38;2;249;38;114m(\e[0m\e[38;2;248;248;242mjust\nanother\ntest\e[38;2;249;38;114m)\e[0m"
    ]
);
subtest 'TestWordwrap' => sub {
    for my $c (@wwcases) {
        my ( $name, $input, $limit, $breaks, $expected ) = @$c;
        is wordwrap( $input, $limit, $breaks ), $expected, "wordwrap $name" or diag "input: $input";
    }
};
my @wcases = (
    [ 'simple',      "I really \e[38;2;249;38;114mlove\e[0m Go!",    8,  "I really\n\e[38;2;249;38;114mlove\e[0m Go!" ],
    [ 'passthrough', 'hello world',                                  11, 'hello world' ],
    [ 'asian',       "\x{3053}\x{3093}\x{306b}\x{3061}",             7,  "\x{3053}\x{3093}\x{306b}\n\x{3061}" ],
    [ 'emoji',       "\x{1F600}\x{1F469}\x{1FAE7}",                  2,  "\x{1F600}\n\x{1F469}\n\x{1FAE7}" ],
    [ 'long style',  "\e[38;2;249;38;114ma really long string\e[0m", 10, "\e[38;2;249;38;114ma really\nlong\nstring\e[0m" ],
    [   'longer', 'the quick brown foxxxxxxxxxxxxxxxx jumped over the lazy dog.',
        16,       "the quick brown\nfoxxxxxxxxxxxxxx\nxx jumped over\nthe lazy dog."
    ],
    [ 'hyphen break', 'foo-bar',        5, "foo-\nbar" ],
    [ 'tab',          "foo\tbar",       3, "foo\nbar" ],
    [ 'exact',        "\e[91mfoo\e[0m", 3, "\e[91mfoo\e[0m" ]
);
subtest 'TestWrap' => sub {
    for my $c (@wcases) {
        my ( $name, $input, $width, $expected ) = @$c;
        is wrap( $input, $width, '' ), $expected, "wrap $name" or diag "input: $input";
    }
};
done_testing;
