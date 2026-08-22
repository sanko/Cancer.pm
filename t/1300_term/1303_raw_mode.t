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
    skip 'STDIN is not a terminal', 6 unless -t STDIN;
    my $fd    = fileno(STDIN);
    my $state = get_state($fd);
    is $state, D(), 'get_state returns defined state on TTY';
    isa_ok $state, ['Cancer::Term::State'];
    is $state->fd, $fd, 'state fd matches';

    # Verify raw mode actually takes effect: decode c_lflag from the state data
    # using the same ABI table as Cancer::Term::Unix ([offset, width] of the
    # flag field per platform). Guards against struct-layout drift silently
    # no-op'ing make_raw -- 16-bit flag offsets at 0/2/4/6 once landed the
    # ECHO|ICANON|ISIG clears inside c_oflag, leaving POSIX terminals cooked.
    my %LFLAG_AT = (
        linux     => [ 12, 4 ],
        darwin    => [ 24, 8 ],
        freebsd   => [ 12, 4 ],
        openbsd   => [ 12, 4 ],
        netbsd    => [ 12, 4 ],
        dragonfly => [ 12, 4 ],
        solaris   => [ 12, 4 ]
    );
    my ( $off, $bytes ) = @{ $LFLAG_AT{$^O} // [] };
    if ( defined $off ) {
        my $lf        = sub { unpack( $bytes == 8 ? 'Q' : 'L', substr( $_[0]->data, $off, $bytes ) ) };
        my $raw_state = make_raw($fd);
        is $raw_state, D(), 'make_raw returns defined state on TTY';
        ok !( $lf->($raw_state) & ( 0x08 | 0x10 | 0x20 | 0x40 | 0x100 ) ), 'make_raw cleared ECHO|ECHONL|ICANON|ISIG|IEXTEN';
        ok set_state( $fd, $raw_state ),                                   'set_state restores successfully';
        is $lf->( get_state($fd) ), $lf->($state), 'terminal flags restored to original values';
    }
    else {
        pass $_ for 1 .. 3;    # unknown platform: state round-trip only
    }
}
done_testing;
