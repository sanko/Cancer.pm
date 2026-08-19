use v5.42;
use experimental 'class';
use utf8;
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Util qw[strip_ansi string_width string_width_wc];
#
my @cases = (
    [ 'empty',         '',                                                        '',                                            0, 0 ],
    [ 'ascii',         'hello',                                                   'hello',                                       5, 5 ],
    [ 'emoji',         "\x{1F602}",                                               "\x{1F602}",                                   2, 2 ],
    [ 'wideemoji',     "\x{1FAE7}",                                               "\x{1FAE7}",                                   2, 2 ],
    [ 'combining',     "a\x{0300}",                                               "a\x{0300}",                                   1, 1 ],
    [ 'control',       "\e[31mhello\e[0m",                                        'hello',                                       5, 5 ],
    [ 'csi8',          "\x9b38;5;1mhello\x9bm",                                   'hello',                                       5, 5 ],
    [ 'osc',           "\e]2;title\a",                                            '',                                            0, 0 ],
    [ 'controlemoji',  "\e[31m\x{1F602}\e[0m",                                    "\x{1F602}",                                   2, 2 ],
    [ 'oscwideemoji2', "\e]2;title\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F466}\a", '',                                            0, 0 ],
    [ 'oscwideemoji3', "\e[31m\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F466}\e[m",   "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F466}", 2, 6 ],
    [   'multiemojicsi', "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F466}\x9b38;5;1mhello\x9bm", "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F466}hello", 7,
        11
    ],
    [ 'osc8eastasianlink',  "\x9d8;id=1;https://example.com/\x9c\x{6253}\x{8C46}\x{8C46}\x9d8;id=1;\x07", "\x{6253}\x{8C46}\x{8C46}",     6,  6 ],
    [ 'dcsarabic',          "\eP?123\$p\x{633}\x{644}\x{627}\x{645}\e\\\x{627}\x{647}\x{644}\x{627}",     "\x{627}\x{647}\x{644}\x{627}", 4,  4 ],
    [ 'newline',            "hello\nworld",                                                               "hello\nworld",                 10, 10 ],
    [ 'tab',                "hello\tworld",                                                               "hello\tworld",                 10, 10 ],
    [ 'controlnewline',     "\e[31mhello\e[0m\nworld",                                                    "hello\nworld",                 10, 10 ],
    [ 'style',              "\e[38;2;249;38;114mfoo",                                                     'foo',                          3,  3 ],
    [ 'unicode',            "\e[35m\x{201C}box\x{201D}\e[0m",                                             "\x{201C}box\x{201D}",          5,  5 ],
    [ 'just_unicode',       "Claire's Boutique",                                                          "Claire's Boutique",            17, 17 ],
    [ 'unclosed_ansi',      "Hey, \e[7m\n\x{7334}",                                                       "Hey, \n\x{7334}",              7,  7 ],
    [ 'double_asian_runes', " \x{4F60}\e[8m\x{597D}.",                                                    " \x{4F60}\x{597D}.",           6,  6 ],
    [ 'flag',               "\x{1F1F8}\x{1F1E6}",                                                         "\x{1F1F8}\x{1F1E6}",           2,  2 ],
    [ 'halfwidth',          "(\x{FF9F}",                                                                  "(\x{FF9F}",                    1,  2 ]
);
subtest 'TestStrip' => sub {
    for my $c (@cases) {
        my ( $name, $input, $stripped ) = @$c;
        is strip_ansi($input), $stripped, "strip $name";
    }
};
subtest 'TestStringWidth' => sub {
    for my $c (@cases) {
        my ( $name, $input, undef, $width ) = @$c;
        is string_width($input), $width, "width $name" or diag "input: $input";
    }
};
subtest 'TestWcStringWidth' => sub {
    for my $c (@cases) {
        my ( $name, $input, undef, undef, $wcwidth ) = @$c;
        is string_width_wc($input), $wcwidth, "wcwidth $name" or diag "input: $input";
    }
};
#
done_testing;
