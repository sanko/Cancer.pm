use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Ansi::Parser qw[
    new_parser set_handler set_params_size set_data_size parser_parse
    Final Prefix Intermediate
];
#
subtest 'just_esc' => sub {    # "\e" alone, no dispatch
    my @dispatched = ();
    my $p          = new_parser();
    set_handler(
        $p,
        {   Print     => sub ($r) { push @dispatched, { type => 'print',   value => chr($r) } },
            Execute   => sub ($b) { push @dispatched, { type => 'execute', value => $b } },
            HandleEsc => sub ($cmd) { push @dispatched, { type => 'esc', cmd => $cmd } },
            HandleCsi => sub ( $cmd, $params ) { push @dispatched, { type => 'csi', cmd => $cmd, params => [@$params] } },
            HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { type => 'dcs', cmd => $cmd, params => [@$params], data => $data } },
            HandleOsc => sub ( $cmd, $data ) { push @dispatched, { type => 'osc', cmd => $cmd, data => $data } },
            HandleApc => sub ($data) { push @dispatched, { type => 'apc', data => $data } }
        }
    );
    parser_parse( $p, "\e" );
    is scalar @dispatched, 0, 'no dispatches for bare ESC';
};
subtest 'double_esc' => sub {    # "\e\e" dispatches first ESC as control byte
    my @dispatched = ();
    my $p          = new_parser();
    set_handler(
        $p,
        {   Print     => sub ($r) { push @dispatched, { type => 'print',   value => chr($r) } },
            Execute   => sub ($b) { push @dispatched, { type => 'execute', value => $b } },
            HandleEsc => sub ($cmd) { push @dispatched, { type => 'esc', cmd => $cmd } },
            HandleCsi => sub ( $cmd, $params ) { push @dispatched, { type => 'csi', cmd => $cmd, params => [@$params] } },
            HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { type => 'dcs', cmd => $cmd, params => [@$params], data => $data } },
            HandleOsc => sub ( $cmd, $data ) { push @dispatched, { type => 'osc', cmd => $cmd, data => $data } },
            HandleApc => sub ($data) { push @dispatched, { type => 'apc', data => $data } }
        }
    );
    parser_parse( $p, "\e\e" );
    is scalar @dispatched,      1,         'one dispatch for double ESC';
    is $dispatched[0]->{type},  'execute', 'type is execute';
    is $dispatched[0]->{value}, 0x1b,      'value is ESC byte';
};
subtest 'csi plus text' => sub {    # "Hello, \e[31mWorld!\e[0m"
    my @dispatched = ();
    my $p          = new_parser();
    set_handler(
        $p,
        {   Print     => sub ($r) { push @dispatched, { type => 'print',   value => chr($r) } },
            Execute   => sub ($b) { push @dispatched, { type => 'execute', value => $b } },
            HandleEsc => sub ($cmd) { push @dispatched, { type => 'esc', cmd => $cmd } },
            HandleCsi => sub ( $cmd, $params ) { push @dispatched, { type => 'csi', cmd => $cmd, params => [@$params] } },
            HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { type => 'dcs', cmd => $cmd, params => [@$params], data => $data } },
            HandleOsc => sub ( $cmd, $data ) { push @dispatched, { type => 'osc', cmd => $cmd, data => $data } },
            HandleApc => sub ($data) { push @dispatched, { type => 'apc', data => $data } }
        }
    );
    parser_parse( $p, "Hello, \e[31mWorld!\e[0m" );
    my @expected = (
        ( map { { type => 'print', value => $_ } } split //, 'Hello, ' ), { type => 'csi', cmd => Final(109), params => [31] },    # 109 = ord('m')
        ( map { { type => 'print', value => $_ } } split //, 'World!' ),  { type => 'csi', cmd => Final(109), params => [0] }
    );
    is scalar @dispatched, scalar @expected, 'correct number of dispatches';
    for my $i ( 0 .. $#expected ) {
        is $dispatched[$i]->{type}, $expected[$i]->{type}, "dispatch[$i] type";
        if ( $expected[$i]->{type} eq 'print' ) {
            is $dispatched[$i]->{value}, $expected[$i]->{value}, "dispatch[$i] value";
        }
        elsif ( $expected[$i]->{type} eq 'csi' ) {
            is Final( $dispatched[$i]->{cmd} ), Final( $expected[$i]->{cmd} ), "dispatch[$i] cmd";
            is $dispatched[$i]->{params},       $expected[$i]->{params},       "dispatch[$i] params";
        }
    }
};
#
done_testing;
