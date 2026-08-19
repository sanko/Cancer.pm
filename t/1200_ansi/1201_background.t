use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../../lib';

# Ported from charmbracelet/x/ansi background_test.go
use Cancer::Ansi qw[/^set_.*color$/];
#
is set_foreground_color(''),        "\e]10;\a",        'set_foreground_color("")';
is set_foreground_color('#ff00ff'), "\e]10;#ff00ff\a", 'set_foreground_color(#ff00ff)';
is set_background_color('#eeeeee'), "\e]11;#eeeeee\a", 'set_background_color(#eeeeee)';
is set_cursor_color('#ffeeaa'),     "\e]12;#ffeeaa\a", 'set_cursor_color(#ffeeaa)';
#
done_testing;
