use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi style_test.go
use Cancer::Ansi qw(
    SelectGraphicRendition
    AttrBold AttrUnderline
    AttrDefaultForegroundColor AttrDefaultBackgroundColor
    AttrDefaultUnderlineColor
);
subtest 'TestReset' => sub {
    is SelectGraphicRendition(), "\e[m", 'Reset';
};
subtest 'TestBold' => sub {
    is SelectGraphicRendition(AttrBold), "\e[1m", 'Bold';
};
subtest 'TestDefaultBackground' => sub {
    is SelectGraphicRendition(AttrDefaultBackgroundColor), "\e[49m", 'DefaultBackground';
};
subtest 'TestSequence' => sub {
    is SelectGraphicRendition( AttrBold, AttrUnderline, 38, 5, 255 ), "\e[1;4;38;5;255m", 'Sequence';
};
subtest 'TestColorColor' => sub {
    is SelectGraphicRendition( AttrBold, AttrUnderline, 38, 2, 0, 0, 0 ), "\e[1;4;38;2;0;0;0m", 'ColorColor';
};
subtest 'TestNilColors' => sub {
    is SelectGraphicRendition( AttrDefaultForegroundColor, AttrDefaultBackgroundColor, AttrDefaultUnderlineColor, ), "\e[39;49;59m", 'NilColors';
};
done_testing;
