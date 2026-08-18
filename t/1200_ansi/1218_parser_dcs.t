use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Encode               qw(encode);
use Cancer::Ansi::Parser qw(
    new_parser set_handler set_params_size parser_parse
    Final Intermediate Prefix
    MissingParam
);
subtest 'TestDcsSequence' => sub {
    my @dispatched;
    my $p = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } },
            HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } },
            HandleCsi => sub ( $cmd, $params ) { push @dispatched, { csi => $cmd, params => [@$params] } },
        }
    );

    # -- max_params: "\eP" + "1;"x33 + "p\e\\"
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } },
            HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } },
        }
    );
    parser_parse( $p, "\eP" . ( '1;' x 33 ) . "p\e\\" );
    is scalar(@dispatched),                  2,         'max_params: 2 dispatches';
    is Final( $dispatched[0]{dcs} ),         ord('p'),  'max_params: dcs final byte';
    is scalar( $dispatched[0]{params}->@* ), 16,        'max_params: 16 params capped';
    is $dispatched[0]{params}[0],            1,         'max_params: param[0]=1';
    is $dispatched[0]{params}[15],           1,         'max_params: param[15]=1';
    is $dispatched[0]{data},                 '',        'max_params: empty data';
    is Final( $dispatched[1]{esc} ),         ord('\\'), 'max_params: esc cmd';

    # -- reset: "\e[3;1\eP1$tx\x9c" (CSI discarded, DCS with intermed and ST)
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } },
            HandleCsi => sub ( $cmd, $params ) { push @dispatched, { csi => $cmd, params => [@$params] } },
        }
    );
    parser_parse( $p, "\e[3;1\eP1\$tx\x9c" );
    is scalar(@dispatched),                 1,        'reset: 1 dispatch (CSI discarded)';
    is Final( $dispatched[0]{dcs} ),        ord('t'), 'reset: dcs final byte';
    is Intermediate( $dispatched[0]{dcs} ), ord('$'), 'reset: dcs intermediate byte';
    is $dispatched[0]{params}[0],           1,        'reset: param[0]=1';
    is $dispatched[0]{data},                'x',      'reset: data=x';

    # -- parse: "\eP0;1|17/ab\x9c"
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler( $p, { HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } }, } );
    parser_parse( $p, "\eP0;1|17/ab\x9c" );
    is scalar( $dispatched[0]{params}->@* ), 2,        'parse: 2 params';
    is $dispatched[0]{params}[0],            0,        'parse: param[0]=0';
    is $dispatched[0]{params}[1],            1,        'parse: param[1]=1';
    is Final( $dispatched[0]{dcs} ),         ord('|'), 'parse: dcs final byte';
    is $dispatched[0]{data},                 '17/ab',  'parse: data';

    # -- intermediate_reset_on_exit: "\eP=1sZZZ\e+\x5c"
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } },
            HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } },
        }
    );
    parser_parse( $p, "\eP=1sZZZ\e+\x5c" );
    is scalar(@dispatched),                        2,        'intermediate_reset: 2 dispatches';
    is Final( $dispatched[0]{dcs} ),               ord('s'), 'intermediate_reset: dcs final byte';
    is chr( Prefix( $dispatched[0]{dcs} ) ),       '=',      'intermediate_reset: dcs prefix char';
    is $dispatched[0]{params}[0],                  1,        'intermediate_reset: param[0]=1';
    is $dispatched[0]{data},                       'ZZZ',    'intermediate_reset: dcs data';
    is Final( $dispatched[1]{esc} ),               0x5c,     'intermediate_reset: esc final byte';
    is chr( Intermediate( $dispatched[1]{esc} ) ), '+',      'intermediate_reset: esc intermediate byte';

    # -- put_utf8: "\eP+r😃\e\\"
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleDcs => sub ( $cmd, $params, $data ) { push @dispatched, { dcs => $cmd, params => [@$params], data => $data } },
            HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } },
        }
    );
    my $emoji_bytes = encode( 'UTF-8', "\x{1f603}" );
    my $dcs_input   = "\eP+r" . $emoji_bytes . "\e\\";
    parser_parse( $p, $dcs_input );
    is scalar(@dispatched),                        2,            'put_utf8: 2 dispatches';
    is Final( $dispatched[0]{dcs} ),               ord('r'),     'put_utf8: dcs final byte';
    is chr( Intermediate( $dispatched[0]{dcs} ) ), '+',          'put_utf8: dcs intermediate byte';
    is $dispatched[0]{data},                       $emoji_bytes, 'put_utf8: dcs data is emoji bytes';
    is scalar( $dispatched[0]{params}->@* ),       0,            'put_utf8: no params';
    is Final( $dispatched[1]{esc} ),               ord('\\'),    'put_utf8: esc cmd';
};
done_testing;
