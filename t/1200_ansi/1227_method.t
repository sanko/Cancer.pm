use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Util qw[visual_width grapheme_width];

# Ported from charmbracelet/x/ansi method_test.go
# Tests visual_width and grapheme_width behavior matching Go's ansi package.
for my $tt (
    [ 'empty string', '', 0, 0 ], [ 'ascii', 'hello', 5, 5 ], [ 'ansi', "\x1b[31mred\x1b[0m", 3, 3 ], [ 'wide chars', 'コンニチハ', 10, 10 ],
    [ 'emoji', "😀", 2, 2 ],

    # Wcwidth measures per codepoint, so a ZWJ sequence is as wide as the
    # emoji it joins: a white flag, a zero-width VS16 and ZWJ, and a
    # rainbow. Grapheme width measures the cluster as the one glyph a
    # terminal in Unicode core mode draws.
    [ 'flag emoji', '🏳️‍🌈', 3, 2 ],

    # Unicode 15.1 merged Indic conjuncts into single clusters, but a
    # terminal without Unicode core mode still advances once per
    # consonant.
    [ 'devanagari', 'नमस्ते', 4, 3 ], [ 'zwj family', '👨‍👩‍👧‍👦', 8, 2 ], [ 'skin tone', '👍🏽', 4, 2 ], [ 'combining mark', 'é', 1, 1 ],
    [ 'vs16', '⚠️', 1, 2 ]
) {
    subtest $tt->[0] => sub {
        is visual_width( $tt->[1] ),   $tt->[2], 'visual_width';
        is grapheme_width( $tt->[1] ), $tt->[3], 'grapheme_width';
    }
}
#
done_testing;
