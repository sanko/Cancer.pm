use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Ansi::Parser qw(
    DecodeSequence
    new_parser set_params_size set_data_size
    HasMoreFlag
    PrefixShift IntermedShift
    NormalState
    ParamVal MissingParam ParamMask
    Command
);
use constant ESC => 0x1B;
use constant DEL => 0x7F;
use constant ST  => 0x9C;
use constant SS3 => 0x8F;
subtest 'TestDecodeSequence' => sub {
    my $p = new_parser();
    set_params_size( $p, 32 );
    set_data_size( $p, 1024 );
    my $check = sub {
        my ( $input, $expected ) = @_;
        my $state  = NormalState;
        my $offset = 0;
        for my $exp (@$expected) {
            my $remaining = substr( $input, $offset );
            my ( $seq, $width, $n, $new_state ) = DecodeSequence( $remaining, $state, $p );
            is $n,   $exp->{n},                            $exp->{name} . ': n';
            is $seq, substr( $input, $offset, $exp->{n} ), $exp->{name} . ': seq';
            if ( exists $exp->{width} ) {
                is $width, $exp->{width}, $exp->{name} . ': width';
            }
            if ( exists $exp->{cmd} ) {
                is $p->{cmd}, $exp->{cmd}, $exp->{name} . ': cmd';
            }
            if ( exists $exp->{params} ) {
                my @got = @{ $p->{params} }[ 0 .. $p->{paramsLen} - 1 ];
                is scalar(@got), scalar( @{ $exp->{params} } ), $exp->{name} . ': params count';
                for my $j ( 0 .. $#got ) {
                    is $got[$j], $exp->{params}[$j], $exp->{name} . ": param[$j]";
                }
            }
            if ( exists $exp->{data} ) {
                my $got_data = $p->{dataLen} >= 0 ? substr( $p->{data}, 0, $p->{dataLen} ) : $p->{data};
                is $got_data, $exp->{data}, $exp->{name} . ': data';
            }
            $offset += $n;
            $state = $new_state;
        }
        is $offset, length($input), 'all bytes consumed';
    };

    # single byte ESC
    $check->( pack( 'C*', ESC ), [ { name => 'single_byte', n => 1 }, ] );

    # single byte 0x00
    $check->( pack( 'C*', 0x00 ), [ { name => 'null', n => 1 }, ] );

    # ASCII printable 'a'
    $check->( 'a', [ { name => 'ascii_a', n => 1, width => 1 }, ] );

    # ASCII space
    $check->( ' ', [ { name => 'space', n => 1, width => 1 }, ] );

    # DEL
    $check->( pack( 'C*', DEL ), [ { name => 'del', n => 1 }, ] );

    # DEL in middle of ASCII
    $check->(
        pack( 'C*', ord('a'), DEL, ord('b') ),
        [ { name => 'del_mid_a', n => 1, width => 1 }, { name => 'del_mid_del', n => 1 }, { name => 'del_mid_b', n => 1, width => 1 }, ]
    );

    # DEL in DCS
    $check->(
        pack( 'C*', ESC, ord('P'), ord('1'), ord(';'), ord('2'), ord('+'), ord('x'), ord('a'), DEL, ord('b'), ESC, ord('\\') ),
        [   {   name   => 'del_dcs',
                n      => 12,
                params => [ 1, 2 ],
                data   => pack( 'C*', ord('a'), DEL, ord('b') ),
                cmd    => ord('x') | ord('+') << IntermedShift,
            },
        ]
    );

    # ST in DCS
    $check->(
        pack( 'C*', ESC, ord('P'), ord('1'), ord(';'), ord('2'), ord('+'), ord('x'), ord('a'), ST, ord('b'), ESC, ord('\\') ),
        [   { name => 'st_dcs_part1', n => 9, params => [ 1, 2 ], data => pack( 'C*', ord('a') ), cmd => ord('x') | ord('+') << IntermedShift, },
            { name => 'st_dcs_b',     n => 1, width  => 1 },
            { name => 'st_dcs_esc',   n => 2, cmd    => ord('\\') },
        ]
    );

    # CSI
    $check->(
        pack( 'C*', ESC, ord('['), ord('1'), ord(';'), ord('2'), ord(';'), ord('3'), ord('m') ),
        [ { name => 'csi', n => 8, params => [ 1, 2, 3 ], cmd => ord('m') }, ]
    );

    # unterminated CSI
    $check->(
        pack( 'C*', ESC, ord('['), ord('1'), ord(';'), ord('2'), ord(';'), ord('3') ),
        [ { name => 'unterm_csi', n => 7, params => [ 1, 2 ] }, ]
    );

    # OSC set title with BEL
    $check->(
        pack(
            'C*',     ESC,      0x5d,    # \e]
            ord('2'), ord(';'), ord('c'), ord('h'), ord('a'), ord('r'), ord('m'), ord('b'), ord('r'), ord('a'), ord('c'), ord('e'), ord('l'),
            ord('e'), ord('t'), ord(':'), ord(' '), ord('~'), ord('/'), ord('S'), ord('o'), ord('u'), ord('r'), ord('c'), ord('e'), ord('/'),
            ord('b'), ord('u'), ord('b'), ord('b'), ord('l'), ord('e'), ord('t'), ord('e'), ord('a'), 0x07
        ),
        [   {   name => 'osc_title',
                n    => 38,
                cmd  => 2,
                data => pack( 'C*',
                    ord('2'), ord(';'), ord('c'), ord('h'), ord('a'), ord('r'), ord('m'), ord('b'), ord('r'), ord('a'), ord('c'), ord('e'),
                    ord('l'), ord('e'), ord('t'), ord(':'), ord(' '), ord('~'), ord('/'), ord('S'), ord('o'), ord('u'), ord('r'), ord('c'),
                    ord('e'), ord('/'), ord('b'), ord('u'), ord('b'), ord('b'), ord('l'), ord('e'), ord('t'), ord('e'), ord('a') ),
            },
        ]
    );

    # OSC set background with 7-bit ST (ESC \)
    $check->(
        pack(
            'C*',     ESC, 0x5d,    # \e]
            ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f'), ESC, ord('\\')
        ),
        [   {   name => 'osc_bg_7bit',
                n    => 15,
                cmd  => 11,
                data => pack( 'C*', ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f') ),
            },
        ]
    );

    # OSC with ST 8-bit, followed by ESC a, 'a', SS3, 'a'
    $check->(
        pack(
            'C*',     ESC, 0x5d,                                                                                                 # \e]
            ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f'), ST,    # \x9c
            ESC,      ord('a'),    # ESC a (escape sequence)
            ord('a'),              # 'a' (printable)
            SS3,                   # \x8f (SS3 single shift)
            ord('a')
        ), [    # 'a' (printable)
            {   name => 'osc_c1_st',
                n    => 14,
                cmd  => 11,
                data => pack( 'C*', ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f') ),
            },
            { name => 'osc_c1_esc_a', n => 2, cmd   => ord('a') },
            { name => 'osc_c1_a',     n => 1, width => 1 },
            { name => 'osc_c1_ss3',   n => 1 },
            { name => 'osc_c1_a2',    n => 1, width => 1 },
        ]
    );

    # OSC followed by CSI (ESC terminated)
    $check->(
        pack(
            'C*',     ESC,      0x5d,                                                                                             # \e]
            ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f'), ESC,    # terminates OSC
            ord('['), ord('1'), ord(';'), ord('2'), ord(';'), ord('3'), ord('m')
        ),
        [   {   name => 'osc_then_csi_osc',
                n    => 13,
                cmd  => 11,
                data => pack( 'C*', ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f') ),
            },
            { name => 'osc_then_csi_csi', n => 8, params => [ 1, 2, 3 ], cmd => ord('m') },
        ]
    );

    # OSC ESC-terminated (no following byte)
    $check->(
        pack( 'C*', ESC, 0x5d, ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f'), ESC ),
        [   {   name => 'osc_esc_term',
                n    => 13,
                cmd  => 11,
                data => pack( 'C*', ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f') ),
            },
            { name => 'osc_esc_alone', n => 1 },
        ]
    );

    # multiple sequences
    $check->(
        pack( 'C*',
            ESC,      ord('['), ord('1'), ord(';'), ord('2'), ord(';'), ord('3'), ord('m'), ESC,      0x5d,     ord('2'), ord(';'), ord('c'),
            ord('h'), ord('a'), ord('r'), ord('m'), ord('b'), ord('r'), ord('a'), ord('c'), ord('e'), ord('l'), ord('e'), ord('t'), ord(':'),
            ord(' '), ord('~'), ord('/'), ord('S'), ord('o'), ord('u'), ord('r'), ord('c'), ord('e'), ord('/'), ord('b'), ord('u'), ord('b'),
            ord('b'), ord('l'), ord('e'), ord('t'), ord('e'), ord('a'), 0x07,     ESC,      0x5d,     ord('1'), ord('1'), ord(';'), ord('f'),
            ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f'), ESC,      ord('\\') ),
        [   { name => 'multi_csi', n => 8, params => [ 1, 2, 3 ], cmd => ord('m') },
            {   name => 'multi_osc1',
                n    => 38,
                cmd  => 2,
                data => pack( 'C*',
                    ord('2'), ord(';'), ord('c'), ord('h'), ord('a'), ord('r'), ord('m'), ord('b'), ord('r'), ord('a'), ord('c'), ord('e'),
                    ord('l'), ord('e'), ord('t'), ord(':'), ord(' '), ord('~'), ord('/'), ord('S'), ord('o'), ord('u'), ord('r'), ord('c'),
                    ord('e'), ord('/'), ord('b'), ord('u'), ord('b'), ord('b'), ord('l'), ord('e'), ord('t'), ord('e'), ord('a') ),
            },
            {   name => 'multi_osc2',
                n    => 15,
                cmd  => 11,
                data => pack( 'C*', ord('1'), ord('1'), ord(';'), ord('f'), ord('f'), ord('/'), ord('0'), ord('0'), ord('/'), ord('f'), ord('f') ),
            },
        ]
    );

    # double ESC
    $check->( pack( 'C*', ESC, ESC ), [ { name => 'double_esc_1', n => 1 }, { name => 'double_esc_2', n => 1 }, ] );

    # double ST (7-bit)
    $check->(
        pack( 'C*', ESC, ord('\\'), ESC, ord('\\') ),
        [ { name => 'double_st_1', n => 2, cmd => ord('\\') }, { name => 'double_st_2', n => 2, cmd => ord('\\') }, ]
    );

    # double ST (8-bit)
    $check->( pack( 'C*', ST, ST ), [ { name => 'double_st8_1', n => 1 }, { name => 'double_st8_2', n => 1 }, ] );

    # ASCII printables
    $check->(
        'Hello, World!',
        [   { name => 'hw_H',  n => 1, width => 1 },
            { name => 'hw_e',  n => 1, width => 1 },
            { name => 'hw_l',  n => 1, width => 1 },
            { name => 'hw_l2', n => 1, width => 1 },
            { name => 'hw_o',  n => 1, width => 1 },
            { name => 'hw_,',  n => 1, width => 1 },
            { name => 'hw_sp', n => 1, width => 1 },
            { name => 'hw_W',  n => 1, width => 1 },
            { name => 'hw_o2', n => 1, width => 1 },
            { name => 'hw_r',  n => 1, width => 1 },
            { name => 'hw_l3', n => 1, width => 1 },
            { name => 'hw_d',  n => 1, width => 1 },
            { name => 'hw_!',  n => 1, width => 1 },
        ]
    );

    # rune (emoji)
    $check->( pack( 'C*', 0xF0, 0x9F, 0x91, 0x8B ), [ { name => 'emoji', n => 4 }, ] );

    # invalid rune (0xC3 alone, incomplete UTF-8)
    $check->( pack( 'C*', 0xC3 ), [ { name => 'invalid_rune', n => 1 }, ] );

    # multiple sequences with UTF8 and double ESC
    $check->(
        pack(
            'C*',     0xF0,     0x9F,     0x91, 0xA8,     0xF0,     0x9F, 0x8F, 0xBF,                                                          # 👨🏿
            0xE2,     0x80,     0x8D,     0xF0, 0x9F,     0x8C,     0xBE,                                                                      # ‍🌾
            ESC,      ESC,      0x20,     ESC,  ord('['), ord('?'), ord('1'), ord(':'), ord('2'), ord(':'), ord('3'), ord('m'), 0xC3, 0x84,    # Ä
            ord('a'), ord('b'), ord('c'), ESC,  ESC,      ord('P'), ord('+'), ord('q'), ESC,      ord('\\')
        ),
        [   { name => 'multi_emoji',     n => 15 },
            { name => 'multi_esc1',      n => 1 },
            { name => 'multi_esc_space', n => 2, cmd    => 0x20 << IntermedShift },
            { name => 'multi_csi_q',     n => 9, params => [ 1 | HasMoreFlag, 2 | HasMoreFlag, 3 ], cmd => ord('m') | ord('?') << PrefixShift, },
            { name => 'multi_a_umlaut',  n => 2 },
            { name => 'multi_a',         n => 1, width => 1 },
            { name => 'multi_b',         n => 1, width => 1 },
            { name => 'multi_c',         n => 1, width => 1 },
            { name => 'multi_esc2',      n => 1 },
            { name => 'multi_dcs',       n => 6, cmd => ord('q') | ord('+') << IntermedShift },
        ]
    );

    # style sequences (text with CSI)
    $check->(
        "hello, \x1b[1;2;3mworld\x1b[0m!",
        [   { name => 'style_h',    n => 1, width  => 1 },
            { name => 'style_e',    n => 1, width  => 1 },
            { name => 'style_l',    n => 1, width  => 1 },
            { name => 'style_l2',   n => 1, width  => 1 },
            { name => 'style_o',    n => 1, width  => 1 },
            { name => 'style_,',    n => 1, width  => 1 },
            { name => 'style_sp',   n => 1, width  => 1 },
            { name => 'style_csi1', n => 8, params => [ 1, 2, 3 ], cmd => ord('m') },
            { name => 'style_w',    n => 1, width  => 1 },
            { name => 'style_o2',   n => 1, width  => 1 },
            { name => 'style_r',    n => 1, width  => 1 },
            { name => 'style_l3',   n => 1, width  => 1 },
            { name => 'style_d',    n => 1, width  => 1 },
            { name => 'style_csi2', n => 4, params => [0], cmd => ord('m') },
            { name => 'style_!',    n => 1, width  => 1 },
        ]
    );

    # OSC with C1 (0x90 == DCS)
    $check->(
        pack( 'C*', ESC, 0x5d, ord('1'), ord('1'), ord(';'), 0x90, ord('?'), ESC, ord('\\') ),
        [ { name => 'osc_c1_dcs', n => 9, cmd => 11, data => pack( 'C*', ord('1'), ord('1'), ord(';'), 0x90, ord('?') ), }, ]
    );

    # unterminated CSI with escape sequence
    $check->(
        pack( 'C*', ESC, ord('['), ord('1'), ord(';'), ord('2'), ord(';'), ord('3'), ESC, ord('O'), ord('a') ),
        [   { name => 'unterm_csi_esc', n => 7, params => [ 1, 2, 3 ], },
            { name => 'unterm_csi_ss3', n => 2, cmd    => ord('O') },
            { name => 'unterm_csi_a',   n => 1, width  => 1 },
        ]
    );

    # SS3
    $check->( pack( 'C*', ESC, ord('O'), ord('a') ), [ { name => 'ss3_cmd', n => 2, cmd => ord('O') }, { name => 'ss3_a', n => 1, width => 1 }, ] );

    # SS3 8-bit
    $check->( pack( 'C*', SS3, ord('a') ), [ { name => 'ss3_8bit', n => 1 }, { name => 'ss3_8bit_a', n => 1, width => 1 }, ] );

    # ESC sequence with intermediate " Q"
    $check->( pack( 'C*', ESC, 0x20, ord('Q') ), [ { name => 'esc_intermed', n => 3, cmd => ord('Q') | 0x20 << IntermedShift }, ] );

    # ESC [ followed by C0 (null)
    $check->(
        pack( 'C*', ESC, ord('['), 0x00, ord('a') ),
        [ { name => 'esc_c0_esc', n => 2 }, { name => 'esc_c0_null', n => 1 }, { name => 'esc_c0_a', n => 1, width => 1 }, ]
    );

    # unterminated DCS
    $check->(
        pack( 'C*', ESC, ord('P'), ord('1'), ord(';'), ord('2'), ord('+'), ord('x'), ord('a') ),
        [ { name => 'unterm_dcs', n => 8, params => [ 1, 2 ], data => pack( 'C*', ord('a') ), cmd => ord('x') | ord('+') << IntermedShift, }, ]
    );

    # invalid DCS (ESC immediately after \eP)
    $check->(
        pack( 'C*', ESC, ord('P'), ESC, ord('\\'), ord('a'), ord('b') ),
        [   { name => 'invalid_dcs_ep', n => 2 },
            { name => 'invalid_dcs_st', n => 2, cmd   => ord('\\') },
            { name => 'invalid_dcs_a',  n => 1, width => 1 },
            { name => 'invalid_dcs_b',  n => 1, width => 1 },
        ]
    );

    # single param OSC
    $check->(
        pack( 'C*', ESC, 0x5d, ord('1'), ord('1'), ord('2'), 0x07 ),
        [ { name => 'single_osc', n => 6, cmd => 112, data => pack( 'C*', ord('1'), ord('1'), ord('2') ), }, ]
    );
};
subtest 'TestCommand' => sub {
    is Cancer::Ansi::Parser::Command( 0,        0,    ord('A') ), ord('A'),                           'CUU';
    is Cancer::Ansi::Parser::Command( ord('?'), 0,    ord('h') ), ord('h') | ord('?') << PrefixShift, 'DECAWM';
    is Cancer::Ansi::Parser::Command( 0,        0x20, ord('q') ), ord('q') | 0x20 << IntermedShift,   'DECSCUSR';
    my $c = Cancer::Ansi::Parser::Command( ord('>'), ord('('), ord('x') );
    is $c,                                        ord('x') | ord('>') << PrefixShift | ord('(') << IntermedShift, 'imaginary';
    is Cancer::Ansi::Parser::Command( 0, 0, 11 ), 11,                                                             'OSC11';
};
subtest 'TestParameter' => sub {
    is Cancer::Ansi::Parser::Parameter(  1, 0 ), 1,                       'single param';
    is Cancer::Ansi::Parser::Parameter(  1, 1 ), 1 | HasMoreFlag,         'single param with hasMore';
    is Cancer::Ansi::Parser::Parameter( -1, 0 ), ParamMask,               'negative param';
    is Cancer::Ansi::Parser::Parameter( -1, 1 ), ParamMask | HasMoreFlag, 'negative param with hasMore';
};
done_testing;
