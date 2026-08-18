use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../../lib';

# Ported from charmbracelet/x/ansi background_test.go
use Cancer::Ansi;
subtest 'TestSetForegroundColorNil' => sub {
    my $s = Cancer::Ansi::set_foreground_color('');
    is $s, "\e]10;\a", 'SetForegroundColor("")';
};
subtest 'TestStringImplementations' => sub {
    my $fg = Cancer::Ansi::set_foreground_color('#ff00ff');
    my $bg = Cancer::Ansi::set_background_color('#eeeeee');
    my $cc = Cancer::Ansi::set_cursor_color('#ffeeaa');
    is $fg, "\e]10;#ff00ff\a", 'SetForegroundColor(#ff00ff)';
    is $bg, "\e]11;#eeeeee\a", 'SetBackgroundColor(#eeeeee)';
    is $cc, "\e]12;#ffeeaa\a", 'SetCursorColor(#ffeeaa)';
};
#
done_testing;
