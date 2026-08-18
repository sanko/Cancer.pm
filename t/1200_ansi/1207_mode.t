use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi mode_test.go
use Cancer::Ansi;
subtest 'TestModeSetting_Methods' => sub {
    my @tests = (
        [ 'ModeNotRecognized',    Cancer::Ansi::ModeNotRecognized,    1, 0, 0, 0, 0 ],
        [ 'ModeSet',              Cancer::Ansi::ModeSet,              0, 1, 0, 0, 0 ],
        [ 'ModeReset',            Cancer::Ansi::ModeReset,            0, 0, 1, 0, 0 ],
        [ 'ModePermanentlySet',   Cancer::Ansi::ModePermanentlySet,   0, 1, 0, 1, 0 ],
        [ 'ModePermanentlyReset', Cancer::Ansi::ModePermanentlyReset, 0, 0, 1, 0, 1 ],
    );
    for my $tc (@tests) {
        my ( $name, $mode, $nr, $is_set, $is_reset, $ps, $pr ) = @$tc;
        subtest $name => sub {
            is Cancer::Ansi::mode_is_not_recognized($mode),    $nr,       'IsNotRecognized';
            is Cancer::Ansi::mode_is_set($mode),               $is_set,   'IsSet';
            is Cancer::Ansi::mode_is_reset($mode),             $is_reset, 'IsReset';
            is Cancer::Ansi::mode_is_permanently_set($mode),   $ps,       'IsPermanentlySet';
            is Cancer::Ansi::mode_is_permanently_reset($mode), $pr,       'IsPermanentlyReset';
        };
    }
};
subtest 'TestSetMode' => sub {
    my @tests = (
        [ 'empty modes',              [],                                                                    '' ],
        [ 'single ANSI mode',         [Cancer::Ansi::ModeKeyboardAction],                                    "\e[2h" ],
        [ 'single DEC mode',          [Cancer::Ansi::ModeCursorKeys],                                        "\e[?1h" ],
        [ 'multiple ANSI modes',      [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeInsertReplace ], "\e[2;4h" ],
        [ 'multiple DEC modes',       [ Cancer::Ansi::ModeCursorKeys, Cancer::Ansi::ModeAutoWrap ],          "\e[?1;7h" ],
        [ 'mixed ANSI and DEC modes', [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeCursorKeys ],    "\e[2h\e[?1h" ],
        [   'multiple mixed ANSI and DEC modes',
            [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeInsertReplace, Cancer::Ansi::ModeCursorKeys, Cancer::Ansi::ModeAutoWrap ],
            "\e[2;4h\e[?1;7h"
        ],
    );
    for my $tc (@tests) {
        my ( $name, $modes, $want ) = @$tc;
        my $got = Cancer::Ansi::set_mode(@$modes);
        is $got, $want, $name;
    }
};
subtest 'TestResetMode' => sub {
    my @tests = (
        [ 'empty modes',              [],                                                                    '' ],
        [ 'single ANSI mode',         [Cancer::Ansi::ModeKeyboardAction],                                    "\e[2l" ],
        [ 'single DEC mode',          [Cancer::Ansi::ModeCursorKeys],                                        "\e[?1l" ],
        [ 'multiple ANSI modes',      [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeInsertReplace ], "\e[2;4l" ],
        [ 'multiple DEC modes',       [ Cancer::Ansi::ModeCursorKeys, Cancer::Ansi::ModeAutoWrap ],          "\e[?1;7l" ],
        [ 'mixed ANSI and DEC modes', [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeCursorKeys ],    "\e[2l\e[?1l" ],
        [   'multiple mixed ANSI and DEC modes',
            [ Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeInsertReplace, Cancer::Ansi::ModeCursorKeys, Cancer::Ansi::ModeAutoWrap ],
            "\e[2;4l\e[?1;7l"
        ],
    );
    for my $tc (@tests) {
        my ( $name, $modes, $want ) = @$tc;
        my $got = Cancer::Ansi::reset_mode(@$modes);
        is $got, $want, $name;
    }
};
subtest 'TestRequestMode' => sub {
    my @tests = ( [ 'ANSI mode', Cancer::Ansi::ModeKeyboardAction, "\e[2\$p" ], [ 'DEC mode', Cancer::Ansi::ModeCursorKeys, "\e[?1\$p" ], );
    for my $tc (@tests) {
        my ( $name, $mode, $want ) = @$tc;
        my $got = Cancer::Ansi::request_mode($mode);
        is $got, $want, $name;
    }
};
subtest 'TestReportMode' => sub {
    my @tests = (
        [ 'ANSI mode not recognized',                        Cancer::Ansi::ModeKeyboardAction, Cancer::Ansi::ModeNotRecognized,    "\e[2;0\$y" ],
        [ 'DEC mode set',                                    Cancer::Ansi::ModeCursorKeys,     Cancer::Ansi::ModeSet,              "\e[?1;1\$y" ],
        [ 'ANSI mode reset',                                 Cancer::Ansi::ModeInsertReplace,  Cancer::Ansi::ModeReset,            "\e[4;2\$y" ],
        [ 'DEC mode permanently set',                        Cancer::Ansi::ModeAutoWrap,       Cancer::Ansi::ModePermanentlySet,   "\e[?7;3\$y" ],
        [ 'ANSI mode permanently reset',                     Cancer::Ansi::ModeSendReceive,    Cancer::Ansi::ModePermanentlyReset, "\e[12;4\$y" ],
        [ 'Invalid mode setting defaults to not recognized', Cancer::Ansi::ModeKeyboardAction, 5,                                  "\e[2;0\$y" ],
    );
    for my $tc (@tests) {
        my ( $name, $mode, $val, $want ) = @$tc;
        my $got = Cancer::Ansi::report_mode( $mode, $val );
        is $got, $want, $name;
    }
};
subtest 'TestModeImplementations' => sub {
    is Cancer::Ansi::mode_num(Cancer::Ansi::ModeKeyboardAction), 2, 'ANSIMode(42)';
    is Cancer::Ansi::mode_is_dec(Cancer::Ansi::ModeCursorKeys),  1, 'DECMode(99) is DEC';
    is Cancer::Ansi::mode_num(Cancer::Ansi::ModeCursorKeys),     1, 'DECMode(99) mode num';
};
done_testing;
