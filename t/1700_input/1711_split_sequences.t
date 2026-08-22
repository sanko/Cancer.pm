use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Input qw[new_parser];

# Split-read robustness: a CSI whose bytes arrive cut across reads must wait
# for more data instead of being drained as an UnknownEvent. This deviates
# deliberately from upstream charmbracelet/x/input, which shreds partial CSIs
# -- it ate a real DA1 reply (Windows Terminal through ConPTY) mid-session.
#
# Note: a lone ESC still reports immediately (escape key / alt+<char>), so a
# read boundary right after the introducer byte remains visible collateral,
# same as upstream.
sub feed_chunks {
    my (@chunks) = @_;
    my $p = new_parser('Cancer::Input');
    my @events;
    my $buf = '';
    for my $c (@chunks) {
        $buf .= $c;
        while ( length $buf ) {
            my ( $used, $ev ) = $p->parse_sequence($buf);
            last if !$used;
            substr( $buf, 0, $used ) = '';
            push @events, $ev if defined $ev;
        }
    }
    return \@events;
}

sub waits ($seq) {
    my ( $used, $ev ) = new_parser('Cancer::Input')->parse_sequence($seq);
    return !( defined $used && $used > 0 ) && !defined $ev;
}
my $DA1       = "\e[?61;4;6;7;14;21;22;23;24;28;32;42;52c";
my @DA1_ATTRS = ( 61, 4, 6, 7, 14, 21, 22, 23, 24, 28, 32, 42, 52 );
subtest 'whole DA1 reply' => sub {
    my ($got) = @{ feed_chunks($DA1) };
    isa_ok $got, 'Cancer::Input::PrimaryDeviceAttributesEvent';
    is $got->attrs, [@DA1_ATTRS], 'attrs match';
};
subtest 'DA1 split across reads' => sub {

    # cut 2 would isolate the ESC introducer, which reports early by design
    for my $cut ( 3 .. length($DA1) - 1 ) {
        my @events = @{ feed_chunks( substr( $DA1, 0, $cut ), substr( $DA1, $cut ) ) };
        is scalar @events, 1, "split at $cut yields exactly one event";
        next unless @events == 1;
        isa_ok $events[0], 'Cancer::Input::PrimaryDeviceAttributesEvent';
        is $events[0]->attrs, [@DA1_ATTRS], "attrs match at split $cut";
    }
};
subtest 'kitty query reply split' => sub {
    my $reply = "\e[?11u";
    for my $cut ( 3 .. length($reply) - 1 ) {
        my @events = @{ feed_chunks( substr( $reply, 0, $cut ), substr( $reply, $cut ) ) };
        is scalar @events, 1, "split at $cut yields exactly one event";
        next unless @events == 1;
        isa_ok $events[0], 'Cancer::Input::KittyEnhancementsEvent';
        is $events[0]->flags, 11, "flags match at split $cut";
    }
};
subtest 'incomplete CSI waits for more bytes' => sub {
    ok waits("\e[?"),               'private marker waits';
    ok waits("\e[?61;4;6"),         'mid parameters waits';
    ok waits("\e[?61;4;6;7;14;21"), 'long param list waits';
    ok waits("\e[<0;33"),           'sgr mouse fragment waits';

    # Complete sequence followed by a fragment: the fragment must not be
    # drained as unknown garbage nor invent events.
    is scalar @{ feed_chunks("\e[I\e[?61") }, 1, 'trailing fragment stays buffered';
};
subtest 'overlong unterminated CSI drains' => sub {
    my $junk = "\e[" . ( "1;" x 40 );
    my ( $used, $ev ) = new_parser('Cancer::Input')->parse_sequence($junk);
    ok $used > 0, 'consumes the junk';
    isa_ok $ev, 'Cancer::Input::UnknownEvent';
};
done_testing;
