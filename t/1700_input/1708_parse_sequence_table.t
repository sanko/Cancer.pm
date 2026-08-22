use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input key_test.go buildBaseSeqTests + TestParseSequence.
# Every sequence produced by buildKeysTable(FlagTerminfo, "dumb") must parse back
# into exactly the Key event recorded in the table (plus the F3/cursor-position
# dual report, see _parse_csi).
use Cancer::Input qw[new_parser build_keys_table FLAG_TERMINFO];
my $P      = new_parser('Cancer::Input');
my %table  = %{ build_keys_table( FLAG_TERMINFO, 'dumb' ) };
my $f3_cpr = qr/\e\[1;(\d+)R/;

sub seq_name ($s) {
    return join '', map { $_ < 32 || $_ > 126 ? sprintf( '\x%02x', $_ ) : chr($_) } unpack 'C*', $s;
}

sub parse_all ($seq) {
    my @events;
    my $buf = $seq;
    while ( defined $buf && length $buf ) {
        my ( $w, $ev ) = $P->parse_sequence($buf);
        last if !$w;
        if ( ref($ev) eq 'Cancer::Input::MultiEvent' ) { push @events, @{ $ev->events // [] } }
        else                                           { push @events, $ev }
        substr( $buf, 0, $w, '' );
    }
    return \@events;
}

sub expected_events ($key) {
    return (
        {   class        => 'KeyPressEvent',
            code         => $key->{code},
            mod          => $key->{mod}  // 0,
            text         => $key->{text} // '',
            shifted_code => 0,
            base_code    => 0,
            is_repeat    => 0
        }
    );
}

sub snap_ev ($e) {
    my $c     = ref $e or return undef;
    my $short = do { local $_ = $c; s/^Cancer::Input:://r };
    if ( $c eq 'Cancer::Input::KeyPressEvent' ) {
        return {
            class        => $short,
            code         => $e->code         // 0,
            mod          => $e->mod          // 0,
            text         => $e->text         // '',
            shifted_code => $e->shifted_code // 0,
            base_code    => $e->base_code    // 0,
            is_repeat    => $e->is_repeat ? 1 : 0
        };
    }
    elsif ( $c eq 'Cancer::Input::CursorPositionEvent' ) {
        return { class => $short, x => $e->x, y => $e->y };
    }
    die "unhandled event class: $c";
}
#
subtest event_classes => sub {
    my $count = 0;
    for my $seq ( sort keys %table ) {
        my $key  = $table{$seq};
        my @want = expected_events($key);

        # XXX: F3 and cursor position report share the same sequence
        # ("\e[1;<mod>R"), so the parser emits both events. See _parse_csi.
        push @want, { class => 'CursorPositionEvent', x => $key->{mod}, y => 0 } if $seq =~ $f3_cpr;
        my $got = [ map { ref $_ } @{ parse_all($seq) } ];
        is $got, [ map {"Cancer::Input::$_->{class}"} @want ], seq_name($seq) or note "failed sequence: $seq";
        $count++;
    }
    pass "$count sequences exercised";
};
#
subtest full_payloads => sub {
    for my $seq ( sort keys %table ) {
        my $key  = $table{$seq};
        my @want = expected_events($key);
        my $name = 'parse';

        # XXX: F3 and cursor position report share the same sequence. See above.
        if ( $seq =~ $f3_cpr ) {
            push @want, { class => 'CursorPositionEvent', x => $key->{mod}, y => 0 };
            $name = "F3 dual report (mod=$key->{mod})";
        }
        my @got = map { snap_ev($_) } @{ parse_all($seq) };
        is \@got, \@want, $name;
    }
};
#
done_testing;
