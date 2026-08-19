use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi hyperlink_test.go
use Cancer::Ansi qw[/hyperlink/];
#
is set_hyperlink('https://example.com'),                            "\e]8;;https://example.com\a", 'set_hyperlink(https://example.com)';
is set_hyperlink( 'https://example.com', 'color=blue', 'size=12' ), "\e]8;color=blue:size=12;https://example.com\a", 'set_hyperlink with params';
is set_hyperlink(''),                                               "\e]8;;\a",                                      'set_hyperlink("")';
#
done_testing;
