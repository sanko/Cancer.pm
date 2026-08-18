use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Util qw[visual_width grapheme_width];

# Ported from charmbracelet/x/ansi method_test.go
# Tests WcWidth (visual_width) and GraphemeWidth (grapheme_width)
# behavior matching Go's ansi package.
subtest 'TestMethod_StringWidth' => sub {
    my @wc_tests = (
        [ 'empty string',          '',                                         0 ],
        [ 'ascii',                 'hello',                                    5 ],
        [ 'ansi wrapped',          "\e[31mred\e[0m",                           3 ],
        [ 'wide chars (katakana)', "\x{30b3}\x{30f3}\x{30cb}\x{30c1}\x{30cf}", 10 ],
        [ 'emoji',                 "\x{1f600}",                                2 ],
        [ 'flag emoji',            "\x{1f3f3}\x{fe0f}\x{200d}\x{1f308}",       1 ],
    );
    for my $tc (@wc_tests) {
        my ( $name, $input, $want ) = @$tc;
        my $got = visual_width($input);
        is $got, $want, "WcWidth: $name";
    }
    my @gw_tests = (
        [ 'empty string',          '',                                         0 ],
        [ 'ascii',                 'hello',                                    5 ],
        [ 'ansi wrapped',          "\e[31mred\e[0m",                           3 ],
        [ 'wide chars (katakana)', "\x{30b3}\x{30f3}\x{30cb}\x{30c1}\x{30cf}", 10 ],
        [ 'emoji',                 "\x{1f600}",                                2 ],
        [ 'flag emoji',            "\x{1f3f3}\x{fe0f}\x{200d}\x{1f308}",       2 ]
    );
    for my $tc (@gw_tests) {
        my ( $name, $input, $want ) = @$tc;
        my $got = grapheme_width($input);
        is $got, $want, "GraphemeWidth: $name";
    }
};
done_testing;
