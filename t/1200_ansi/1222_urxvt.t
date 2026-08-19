use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi urxvt_test.go
use Cancer::Ansi qw[URxvtExt];
#
is URxvtExt( 'foo', 'bar', 'baz' ),         "\e]777;foo;bar;baz\a",         q[URxvtExt( 'foo', 'bar', 'baz' )];
is URxvtExt('test'),                        "\e]777;test;\a",               q[URxvtExt( 'test' )];
is URxvtExt( 'example', 'param1' ),         "\e]777;example;param1\a",      q[URxvtExt( 'example', 'param1' )];
is URxvtExt( 'notify', 'message', 'info' ), "\e]777;notify;message;info\a", q[URxvtExt( 'notify', 'message', 'info' )];
#
done_testing;
