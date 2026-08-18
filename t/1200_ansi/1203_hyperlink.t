use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi hyperlink_test.go
use Cancer::Ansi;
subtest 'TestNewHyperlink_NoParams' => sub {
    my $h = Cancer::Ansi::set_hyperlink('https://example.com');
    is $h, "\e]8;;https://example.com\a", 'SetHyperlink(https://example.com)';
};
subtest 'TestNewHyperlinkParams' => sub {
    my $h = Cancer::Ansi::set_hyperlink( 'https://example.com', 'color=blue', 'size=12' );
    is $h, "\e]8;color=blue:size=12;https://example.com\a", 'SetHyperlink with params';
};
subtest 'TestHyperlinkReset' => sub {
    my $h = Cancer::Ansi::set_hyperlink('');
    is $h, "\e]8;;\a", 'SetHyperlink("")';
};
done_testing;
