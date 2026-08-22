use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input focus_test.go TestFocus/TestBlur
use Cancer::Input qw[new_parser];
#
subtest focus => sub {
    my $p = new_parser('Cancer::Input');
    my ( undef, $e ) = $p->parse_sequence("\e[I");
    isa_ok $e, ['Cancer::Input::FocusEvent'], 'produces FocusEvent' or diag ref($e);
};
#
subtest blur => sub {
    my $p = new_parser('Cancer::Input');
    my ( undef, $e ) = $p->parse_sequence("\e[O");
    isa_ok $e, ['Cancer::Input::BlurEvent'], 'produces BlurEvent' or diag ref($e);
};
#
done_testing;
