use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi title_test.go
use Cancer::Ansi qw[/icon/ /window/];
#
is set_icon_name_window_title('hello'), "\e]0;hello\a", 'set_icon_name_window_title("hello")';
is set_icon_name('hello'),              "\e]1;hello\a", 'set_icon_name("hello")';
is set_window_title('hello'),           "\e]2;hello\a", 'set_window_title("hello")';
#
done_testing;
