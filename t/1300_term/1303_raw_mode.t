use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term qw[:all];
#
is get_state(9999), U(), 'get_state on non-terminal returns undef';
is make_raw(9999),  U(), 'make_raw on non-terminal returns undef';

# Full round-trip test (only on real TTY)
SKIP: {
    skip 'STDIN is not a terminal', 4 unless -t STDIN;
    my $fd    = fileno(STDIN);
    my $state = get_state($fd);
    is $state, D(), 'get_state returns defined state on TTY';
    isa_ok $state, ['Cancer::Term::State'];
    is $state->fd, $fd, 'state fd matches';
    my $raw_state = make_raw($fd);
    is $raw_state, D(), 'make_raw returns defined state on TTY';
    ok set_state( $fd, $raw_state ), 'set_state restores successfully';
}
done_testing;
