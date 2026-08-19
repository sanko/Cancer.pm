use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi style_test.go
use Cancer::Ansi qw[
    SGR
    AttrBold AttrUnderline
    AttrDefaultForegroundColor AttrDefaultBackgroundColor
    AttrDefaultUnderlineColor
];
#
is SGR(),                                                                                     "\e[m",               'Reset';
is SGR(AttrBold),                                                                             "\e[1m",              'Bold';
is SGR(AttrDefaultBackgroundColor),                                                           "\e[49m",             'DefaultBackground';
is SGR( AttrBold, AttrUnderline, 38, 5, 255 ),                                                "\e[1;4;38;5;255m",   'Sequence';
is SGR( AttrBold, AttrUnderline, 38, 2, 0, 0, 0 ),                                            "\e[1;4;38;2;0;0;0m", 'ColorColor';
is SGR( AttrDefaultForegroundColor, AttrDefaultBackgroundColor, AttrDefaultUnderlineColor, ), "\e[39;49;59m",       'NilColors';
#
done_testing;
