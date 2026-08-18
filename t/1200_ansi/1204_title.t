use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi title_test.go
use Cancer::Ansi;
subtest 'TestSetIconNameWindowTitle' => sub {
    my $r = Cancer::Ansi::set_icon_name_window_title('hello');
    is $r, "\e]0;hello\a", 'SetIconNameWindowTitle(hello)';
};
subtest 'TestSetIconName' => sub {
    my $r = Cancer::Ansi::set_icon_name('hello');
    is $r, "\e]1;hello\a", 'SetIconName(hello)';
};
subtest 'TestSetWindowTitle' => sub {
    my $r = Cancer::Ansi::set_window_title('hello');
    is $r, "\e]2;hello\a", 'SetWindowTitle(hello)';
};
done_testing;
