use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Ansi::Parser qw[new_parser set_handler set_params_size set_data_size parser_parse Final];
use constant { ESC => 0x1B, BEL => 0x07, ST => 0x9C };
#
my $max_buf = 1024;

sub make_parser {
    my $p = new_parser();
    set_params_size( $p, 16 );
    set_data_size( $p, $max_buf );
    $p;
}
#
subtest 'parse: \e]2;charmbracelet: ~/Source/bubbletea\a' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p,
        { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );
    parser_parse( $p, "\e]2;charmbracelet: ~/Source/bubbletea\x07" );
    is scalar(@dispatched), 1,                                     'parse: 1 dispatch';
    is $dispatched[0],      "2;charmbracelet: ~/Source/bubbletea", 'parse: data';
};
subtest 'empty: \e]\a' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p, { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, } );
    parser_parse( $p, "\e]\x07" );
    is scalar(@dispatched), 1,  'empty: 1 dispatch';
    is $dispatched[0],      '', 'empty: empty data';
};
subtest 'max_params: \e] + 17 ";" + \e\\' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p,
        { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );
    parser_parse( $p, "\e]" . ( ';' x 17 ) . "\e\\" );
    is scalar(@dispatched),          2, 'max_params: 2 dispatches';
    is $dispatched[0], ( ';' x 17 ), 'max_params: data';
    is $dispatched[1]{esc} & 0xff,   ord('\\'), 'max_params: esc cmd';
};
subtest 'bell_terminated: \e]11;ff/00/ff\a' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p, { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, } );
    parser_parse( $p, "\e]11;ff/00/ff\x07" );
    is $dispatched[0], '11;ff/00/ff', 'bell_terminated: data';
};
subtest 'esc_st_terminated: \e]11;ff/00/ff\e\\' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p,
        { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );
    parser_parse( $p, "\e]11;ff/00/ff\e\\" );
    is scalar(@dispatched),        2,             'esc_st_terminated: 2 dispatches';
    is $dispatched[0],             '11;ff/00/ff', 'esc_st_terminated: osc data';
    is $dispatched[1]{esc} & 0xff, ord('\\'),     'esc_st_terminated: esc cmd';
};
subtest q|tf8: \e]2;echo '¯\_(ツ)_/¯' && sleep 1\e\\  (ST = 0x9C)| => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p, { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, } );

    # Build raw byte input: ESC ] 2 ; echo ' ¯ \ _ ( ツ ) _ / ¯ '   && sleep 1 ST
    my $utf8_input = pack(
        'C*', ESC, 0x5d,                             # \e]
        0x32, 0x3b,                                  # 2;
        0x65, 0x63, 0x68, 0x6f, 0x20, 0x27,          # echo '
        0xc2, 0xaf,                                  # ¯
        0x5c, 0x5f, 0x28,                            # \_(
        0xe3, 0x83, 0x84,                            # ツ
        0x29, 0x5f, 0x2f,                            # )_/
        0xc2, 0xaf,                                  # ¯
        0x27, 0x20, 0x26, 0x26, 0x20,                # ' &&
        0x73, 0x6c, 0x65, 0x65, 0x70, 0x20, 0x31,    # sleep 1
        ST,                                          # \x9c
    );
    my $utf8_expected = pack(
        'C*', 0x32, 0x3b,                            # 2;
        0x65, 0x63, 0x68, 0x6f, 0x20, 0x27,          # echo '
        0xc2, 0xaf,                                  # ¯
        0x5c, 0x5f, 0x28,                            # \_(
        0xe3, 0x83, 0x84,                            # ツ
        0x29, 0x5f, 0x2f,                            # )_/
        0xc2, 0xaf,                                  # ¯
        0x27, 0x20, 0x26, 0x26, 0x20,                # ' &&
        0x73, 0x6c, 0x65, 0x65, 0x70, 0x20, 0x31,    # sleep 1
    );
    parser_parse( $p, $utf8_input );
    is $dispatched[0], $utf8_expected, 'utf8: raw byte data';
};
subtest 'string_terminator: \e]2;\xe6\x9c\xab\e\\  (partial UTF-8 interrupted)' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p,
        { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );
    my $st_input = pack( 'C*', ESC, 0x5d, 0x32, 0x3b, 0xe6, 0x9c, 0xab, ESC, 0x5c );
    parser_parse( $p, $st_input );
    is scalar(@dispatched),        2,                              'string_terminator: 2 dispatches';
    is $dispatched[0],             pack( 'C*', 0x32, 0x3b, 0xe6 ), 'string_terminator: data = "2;\xe6"';
    is $dispatched[1]{esc} & 0xff, ord('\\'),                      'string_terminator: esc cmd';
};
subtest 'exceed_max_buffer_size: data truncated to buffer' => sub {
    my @dispatched = ();
    my $p          = new_parser();
    set_params_size( $p, 16 );
    set_data_size( $p, $max_buf );
    set_handler( $p, { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, } );
    parser_parse( $p, "\e]52;s" . ( 'a' x $max_buf ) . "\x07" );
    is scalar(@dispatched),            1,        'exceed: 1 dispatch';
    is length( $dispatched[0] ),       $max_buf, 'exceed: truncated to buffer size';
    is substr( $dispatched[0], 0, 4 ), '52;s',   'exceed: prefix intact';
    is substr( $dispatched[0], 4 ), ( 'a' x ( $max_buf - 4 ) ), 'exceed: a*1020';
};
subtest 'title_empty_params_esc: \e]0;abc\e\\\e];;;...\a' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p,
        { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );
    parser_parse( $p, "\e]0;abc\e\\\e]" . ( ';' x 45 ) . "\x07" );
    is scalar(@dispatched),          3,         'title_empty: 3 dispatches';
    is $dispatched[0],               '0;abc',   'title_empty: first osc data';
    is $dispatched[1]{esc} & 0xff,   ord('\\'), 'title_empty: esc cmd';
    is $dispatched[2], ( ';' x 45 ), 'title_empty: second osc data';
};
subtest 'just command: \e]112\a' => sub {
    my @dispatched = ();
    my $p          = make_parser();
    set_handler( $p, { HandleOsc => sub ( $cmd, $data ) { push @dispatched, $data }, } );
    parser_parse( $p, "\e]112\x07" );
    is $dispatched[0], '112', 'just_command: data';
};
#
done_testing;
