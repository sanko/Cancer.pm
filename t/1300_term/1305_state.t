use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term qw[:all];
#
SKIP: {
    skip 'STDIN is not a terminal', 3 unless -t STDIN;
    my $fd    = fileno STDIN;
    my $state = get_state($fd);
    is $state, D(), 'get_state returns defined';
    isa_ok $state, ['Cancer::Term::State'];
    is $state->fd, $fd, 'fd matches';
}
is get_state(9999), U(), 'get_state on non-terminal returns undef';
#
done_testing;
