use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Ansi::Parser qw(
    new_parser set_handler set_params_size parser_advance parser_parse
    params param command Final Prefix Intermediate
    MissingParam HasMoreFlag ParamMask ParamVal Parameter
    GroundState EscapeState CsiEntryState CsiParamState
    CsiIntermediateState
    NoneAction ClearAction CollectAction PrefixAction
    DispatchAction ExecuteAction StartAction PutAction
    ParamAction PrintAction
);
subtest 'TestCsiSequence' => sub {
    my @dispatched;

    # -- no_params: "\e[m"
    @dispatched = ();
    my $p = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[m" );
    is scalar(@dispatched),                  1,        'no_params: dispatched count';
    is Final( $dispatched[0]{cmd} ),         ord('m'), 'no_params: final byte';
    is scalar( $dispatched[0]{params}->@* ), 0,        'no_params: no params';

    # -- one_param: "\e[7m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[7m" );
    is Final( $dispatched[0]{cmd} ), ord('m'), 'one_param: cmd';
    is $dispatched[0]{params}[0],    7,        'one_param: param = 7';

    # -- param_reset: "\e[0mabc\e[1;2m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[0mabc\e[1;2m" );
    is scalar(@dispatched),          5,        'param_reset: 5 events';
    is Final( $dispatched[0]{cmd} ), ord('m'), 'param_reset: first CSI cmd';
    is $dispatched[0]{params}[0],    0,        'param_reset: first param 0';
    is $dispatched[1]{print},        'a',      'param_reset: print a';
    is $dispatched[2]{print},        'b',      'param_reset: print b';
    is $dispatched[3]{print},        'c',      'param_reset: print c';
    is $dispatched[4]{params}[0],    1,        'param_reset: second CSI param[0]=1';
    is $dispatched[4]{params}[1],    2,        'param_reset: second CSI param[1]=2';

    # -- max_params: 31 "1;" with buffer 16
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[" . ( '1;' x 31 ) . 'p' );
    is scalar(@dispatched),                  1,  'max_params: one CSI';
    is scalar( $dispatched[0]{params}->@* ), 16, 'max_params: 16 params (buffer limit)';
    is $dispatched[0]{params}[0],            1,  'max_params: param[0]=1';
    is $dispatched[0]{params}[15],           1,  'max_params: param[15]=1';

    # -- ignore_long: 18 "1;" with buffer 16
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[" . ( '1;' x 18 ) . 'p' );
    is scalar(@dispatched),                  1,  'ignore_long: one CSI';
    is scalar( $dispatched[0]{params}->@* ), 16, 'ignore_long: 16 params capped';

    # -- trailing_semicolon: "\e[4;m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[4;m" );
    is $dispatched[0]{params}[0],                 4,            'trailing_semicolon: param[0]=4';
    is $dispatched[0]{params}[1],                 MissingParam, 'trailing_semicolon: param[1]=MissingParam';
    is ParamVal( $dispatched[0]{params}[1], 99 ), 99,           'trailing_semicolon: param[1] defaults to 99';

    # -- leading_semicolon: "\e[;4m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[;4m" );
    is $dispatched[0]{params}[0],                 MissingParam, 'leading_semicolon: param[0]=MissingParam';
    is ParamVal( $dispatched[0]{params}[0], 99 ), 99,           'leading_semicolon: param[0] defaults to 99';
    is $dispatched[0]{params}[1],                 4,            'leading_semicolon: param[1]=4';

    # -- long_param: "\e[65535m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[65535m" );
    is $dispatched[0]{params}[0], 65535, 'long_param: param = 65535';

    # -- reset: "\e[3;1\x1b[?1049h" (partial CSI discarded by ESC)
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[3;1\x1b[?1049h" );
    is scalar(@dispatched),                  1,        'reset: 1 dispatch (partial discarded)';
    is Final( $dispatched[0]{cmd} ),         ord('h'), 'reset: cmd h';
    is chr( Prefix( $dispatched[0]{cmd} ) ), '?',      'reset: prefix char';
    is $dispatched[0]{params}[0],            1049,     'reset: param 1049';

    # -- subparams: "\e[38:2:255:0:255;1m"
    @dispatched = ();
    $p          = new_parser();
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[38:2:255:0:255;1m" );
    is scalar( $dispatched[0]{params}->@* ), 6,                'subparams: 6 params';
    is $dispatched[0]{params}[0],            38 | HasMoreFlag, 'subparams: [0]=38 with hasmore';
    ok $dispatched[0]{params}[1] & HasMoreFlag, 'subparams: [1] has more';
    is ParamVal( $dispatched[0]{params}[1], 0 ), 2, 'subparams: [1]=2';
    ok $dispatched[0]{params}[2] & HasMoreFlag, 'subparams: [2] has more';
    is ParamVal( $dispatched[0]{params}[2], 0 ), 255, 'subparams: [2]=255';
    ok $dispatched[0]{params}[3] & HasMoreFlag, 'subparams: [3] has more';
    is ParamVal( $dispatched[0]{params}[3], 0 ), 0, 'subparams: [3]=0';
    ok !( $dispatched[0]{params}[4] & HasMoreFlag ), 'subparams: [4] no hasmore';
    is ParamVal( $dispatched[0]{params}[4], 0 ), 255, 'subparams: [4]=255';
    is $dispatched[0]{params}[5],                1,   'subparams: [5]=1';
    ok !( $dispatched[0]{params}[5] & HasMoreFlag ), 'subparams: [5] no hasmore';

    # -- params_buffer_filled_with_subparams: 32 ":" with buffer 16
    @dispatched = ();
    $p          = new_parser();
    set_params_size( $p, 16 );
    set_handler(
        $p,
        {   HandleCsi => sub ( $cmd, $params ) { push @dispatched, { cmd => $cmd, params => [@$params] } },
            Print     => sub ($r) { push @dispatched, { print => chr($r) } },
        }
    );
    parser_parse( $p, "\e[" . ( ':' x 32 ) . "x" );
    is scalar(@dispatched),                  1,  'filled_buffer: one CSI';
    is scalar( $dispatched[0]{params}->@* ), 16, 'filled_buffer: 16 params';

    for my $i ( 0 .. 15 ) {
        ok $dispatched[0]{params}[$i] & HasMoreFlag, "filled_buffer: param[$i] hasmore";
        my $raw_val = $dispatched[0]{params}[$i] & ParamMask;
        is $raw_val, MissingParam, "filled_buffer: param[$i] missing";
    }
    is Final( $dispatched[0]{cmd} ), ord('x'), 'filled_buffer: cmd';
};
done_testing;
