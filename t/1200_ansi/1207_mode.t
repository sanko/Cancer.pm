use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi mode_test.go
use Cancer::Ansi qw[/Mode/ /mode/];
subtest 'Mode.+ methods' => sub {
    my @tests = (
        [ 'ModeNotRecognized',    ModeNotRecognized,    T(), F(), F(), F(), F() ],
        [ 'ModeSet',              ModeSet,              F(), T(), F(), F(), F() ],
        [ 'ModeReset',            ModeReset,            F(), F(), T(), F(), F() ],
        [ 'ModePermanentlySet',   ModePermanentlySet,   F(), T(), F(), T(), F() ],
        [ 'ModePermanentlyReset', ModePermanentlyReset, F(), F(), T(), F(), T() ]
    );
    for my $tc (@tests) {
        my ( $name, $mode, $nr, $is_set, $is_reset, $ps, $pr ) = @$tc;
        subtest $name => sub {
            is mode_is_not_recognized($mode),    $nr,       'mode_is_not_recognized';
            is mode_is_set($mode),               $is_set,   'mode_is_set';
            is mode_is_reset($mode),             $is_reset, 'mode_is_reset';
            is mode_is_permanently_set($mode),   $ps,       'mode_is_permanently_set';
            is mode_is_permanently_reset($mode), $pr,       'mode_is_permanently_reset';
        }
    }
};
subtest set_mode => sub {
    is set_mode(),                                                                      '',                'empty modes';
    is set_mode(ModeKeyboardAction),                                                    "\e[2h",           'single ANSI mode';
    is set_mode(ModeCursorKeys),                                                        "\e[?1h",          'single DEC mode';
    is set_mode( ModeKeyboardAction, ModeInsertReplace ),                               "\e[2;4h",         'multiple ANSI modes';
    is set_mode( ModeCursorKeys, ModeAutoWrap ),                                        "\e[?1;7h",        'multiple DEC modes';
    is set_mode( ModeKeyboardAction, ModeCursorKeys ),                                  "\e[2h\e[?1h",     'mixed ANSI and DEC modes';
    is set_mode( ModeKeyboardAction, ModeInsertReplace, ModeCursorKeys, ModeAutoWrap ), "\e[2;4h\e[?1;7h", 'multiple mixed ANSI and DEC modes';
};
subtest reset_mode => sub {
    is reset_mode(),                                                                      '',                'empty modes';
    is reset_mode(ModeKeyboardAction),                                                    "\e[2l",           'single ANSI mode';
    is reset_mode(ModeCursorKeys),                                                        "\e[?1l",          'single DEC mode';
    is reset_mode( ModeKeyboardAction, ModeInsertReplace ),                               "\e[2;4l",         'multiple ANSI modes';
    is reset_mode( ModeCursorKeys, ModeAutoWrap ),                                        "\e[?1;7l",        'multiple DEC modes';
    is reset_mode( ModeKeyboardAction, ModeCursorKeys ),                                  "\e[2l\e[?1l",     'mixed ANSI and DEC modes';
    is reset_mode( ModeKeyboardAction, ModeInsertReplace, ModeCursorKeys, ModeAutoWrap ), "\e[2;4l\e[?1;7l", 'multiple mixed ANSI and DEC modes';
};
subtest request_mode => sub {
    is request_mode(ModeKeyboardAction), "\e[2\$p",  'ANSI mode';
    is request_mode(ModeCursorKeys),     "\e[?1\$p", 'DEC mode';
};
subtest report_mode => sub {
    is report_mode( ModeKeyboardAction, ModeNotRecognized ),    "\e[2;0\$y",  'ANSI mode not recognized';
    is report_mode( ModeCursorKeys,     ModeSet ),              "\e[?1;1\$y", 'DEC mode set';
    is report_mode( ModeInsertReplace,  ModeReset ),            "\e[4;2\$y",  'ANSI mode reset';
    is report_mode( ModeAutoWrap,       ModePermanentlySet ),   "\e[?7;3\$y", 'DEC mode permanently set';
    is report_mode( ModeSendReceive,    ModePermanentlyReset ), "\e[12;4\$y", 'ANSI mode permanently reset';
    is report_mode( ModeKeyboardAction, 5 ),                    "\e[2;0\$y",  'Invalid mode setting defaults to not recognized';
};
subtest 'test mode implementations' => sub {
    is mode_num(ModeKeyboardAction), 2, 'ANSIMode(42)';
    is mode_is_dec(ModeCursorKeys),  1, 'DECMode(99) is DEC';
    is mode_num(ModeCursorKeys),     1, 'DECMode(99) mode num';
};
#
done_testing;
