use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Ansi::Parser qw(
    new_parser set_handler set_params_size parser_parse
    Final Intermediate Prefix
);
subtest 'TestEscSequence' => sub {
    my @dispatched;
    my $mk = sub {
        my $p = new_parser();
        set_params_size( $p, 16 );
        set_handler(
            $p,
            {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { csi => $cmd, params => [@$params] } },
                HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } },
                Print     => sub ($r) { push @dispatched, { print => chr($r) } },
            }
        );
        $p;
    };

    # -- reset: "\e[3;1\e(A" (partial CSI discarded, esc with intermediate)
    @dispatched = ();
    my $p = $mk->();
    parser_parse( $p, "\e[3;1\e(A" );
    is scalar(@dispatched),                 1,        'reset: 1 dispatch (CSI discarded)';
    is Final( $dispatched[0]{esc} ),        ord('A'), 'reset: esc final byte';
    is Intermediate( $dispatched[0]{esc} ), ord('('), 'reset: esc intermediate byte';
};
done_testing;
