use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];
#
subtest 'from SGR codes' => sub {
    my $s = NewStyle(AttrBold);
    ok $s, 'NewStyle with AttrBold';
    is $s->to_string, "\e[1m", 'to_string for bold';
};
is NewStyle()->to_string,               "\e[m",           'empty style is reset';
is NewStyle()->bold->italic->to_string, "\e[1;3m",        'bold + italic chain';
is NewStyle(AttrBold)->styled('hello'), "\e[1mhello\e[m", 'styled wraps text';
is NewStyle()->styled('hello'),         'hello',          'styled empty is passthrough';
subtest 'italic toggle' => sub {
    my $s_on = NewStyle()->italic(1);
    is $s_on->to_string, "\e[3m", 'italic on';
    my $s_off = NewStyle()->italic(0);
    is $s_off->to_string, "\e[23m", 'italic off';
};
is NewStyle()->underline(1)->to_string, "\e[4m", 'underline on';
subtest underline_style => sub {
    my $s_dbl = NewStyle()->underline_style(UnderlineDouble);
    is $s_dbl->to_string, "\e[4:2m", 'double underline';
    my $s_curl = NewStyle()->underline_style(UnderlineCurly);
    is $s_curl->to_string, "\e[4:3m", 'curly underline';
    my $s_dot = NewStyle()->underline_style(UnderlineDotted);
    is $s_dot->to_string, "\e[4:4m", 'dotted underline';
    my $s_dash = NewStyle()->underline_style(UnderlineDashed);
    is $s_dash->to_string, "\e[4:5m", 'dashed underline';
    my $s_none = NewStyle()->underline(1)->underline_style(UnderlineNone);
    is $s_none->to_string, "\e[4;24m", 'underline none disables underline';
};
is NewStyle()->blink->to_string,                                                         "\e[5m",                  'blink';
is NewStyle()->rapid_blink->to_string,                                                   "\e[6m",                  'rapid_blink';
is NewStyle()->reverse->to_string,                                                       "\e[7m",                  'reverse';
is NewStyle()->conceal->to_string,                                                       "\e[8m",                  'conceal';
is NewStyle()->strikethrough->to_string,                                                 "\e[9m",                  'strikethrough';
is NewStyle()->bold->normal->to_string,                                                  "\e[1;22m",               'bold then normal';
is NewStyle()->foreground_color(196)->to_string,                                         "\e[38;5;196m",           'fg 256-color';
is NewStyle()->foreground_color( [ 255, 128, 0 ] )->to_string,                           "\e[38;2;255;128;0m",     'fg truecolor';
is NewStyle()->foreground_color(undef)->to_string,                                       "\e[39m",                 'fg default';
is NewStyle()->background_color(42)->to_string,                                          "\e[48;5;42m",            'bg 256-color';
is NewStyle()->underline_color( [ 0, 255, 0 ] )->to_string,                              "\e[58;2;0;255;0m",       'underline truecolor';
is NewStyle()->bold->italic->foreground_color( [ 255, 0, 0 ] )->underline(1)->to_string, "\e[1;3;38;2;255;0;0;4m", 'complex chain';
is NewStyle()->bold->reset->to_string,                                                   "\e[1;0m",                'reset appends 0';

# Test passing existing Attr constants to NewStyle
is NewStyle( AttrBold, AttrItalic, 31 )->to_string, "\e[1;3;31m", 'NewStyle with mixed constants';
is NewStyle(-5)->to_string,                         "\e[0m",      'negative attr clamped to 0';
#
done_testing;
