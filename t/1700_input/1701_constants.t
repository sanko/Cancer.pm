use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input key_test.go
use Cancer::Input qw[
    new_parser build_keys_table
    KEY_EXTENDED KEY_BACKSPACE KEY_TAB KEY_ENTER KEY_RETURN KEY_ESCAPE KEY_ESC KEY_SPACE
    FLAG_CTRL_AT FLAG_CTRL_I FLAG_CTRL_M FLAG_CTRL_OPEN_BRACKET FLAG_BACKSPACE FLAG_MOUSE_MODE
    MOD_SHIFT MOD_ALT MOD_CTRL MOD_META MOD_HYPER MOD_SUPER MOD_CAPS_LOCK MOD_NUM_LOCK MOD_SCROLL_LOCK
    KITTY_DISAMBIGUATE_ESCAPE_CODES KITTY_REPORT_EVENT_TYPES KITTY_REPORT_ASSOCIATED_TEXT
    MOUSE_NONE MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT MOUSE_WHEEL_UP MOUSE_WHEEL_DOWN MOUSE_WHEEL_LEFT
    MOUSE_WHEEL_RIGHT MOUSE_BACKWARD MOUSE_FORWARD MOUSE_BUTTON10 MOUSE_BUTTON11
];
use Cancer::Ansi qw[
    MouseNone MouseLeft MouseMiddle MouseRight MouseWheelUp MouseWheelDown MouseWheelLeft
    MouseWheelRight MouseBackward MouseForward MouseButton10 MouseButton11 SYSTEM_CLIPBOARD PRIMARY_CLIPBOARD
];
my @EXTENDED_KEYS = (
    'UP', 'DOWN', 'RIGHT', 'LEFT', 'BEGIN', 'FIND', 'INSERT', 'DELETE', 'SELECT', 'PG_UP',
    'PG_DOWN',
    'HOME', 'END',
    'KP_ENTER',
    'KP_EQUAL',
    'KP_MULTIPLY',
    'KP_PLUS',
    'KP_COMMA',
    'KP_MINUS',
    'KP_DECIMAL',
    'KP_DIVIDE',
    ( map {"KP_$_"} 0 .. 9 ),
    ( map {"KP_$_"} qw[SEP UP DOWN LEFT RIGHT PG_UP PG_DOWN HOME END INSERT DELETE BEGIN] ),
    ( map {"F$_"} 1 .. 63 ),
    (qw[CAPS_LOCK SCROLL_LOCK NUM_LOCK PRINT_SCREEN PAUSE MENU]),
    (
        qw[MEDIA_PLAY MEDIA_PAUSE MEDIA_PLAY_PAUSE MEDIA_REVERSE MEDIA_STOP
            MEDIA_FAST_FORWARD MEDIA_REWIND MEDIA_NEXT MEDIA_PREV MEDIA_RECORD]
    ),
    (qw[LOWER_VOL RAISE_VOL MUTE]),
    ( map {"LEFT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ),
    ( map {"RIGHT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ),
    (qw[ISO_LEVEL3_SHIFT ISO_LEVEL5_SHIFT])
);
#
subtest extended_iota => sub {
    my $code = KEY_EXTENDED;
    for my $name (@EXTENDED_KEYS) {
        $code++;
        my $sub = Cancer::Input->can("KEY_$name");
        ok $sub, "KEY_$name exists";
        is $sub->(), $code, "KEY_$name == 0x" . sprintf( '%X', $code ) if $sub;
    }
};
#
subtest fixed_keys => sub {
    is KEY_EXTENDED,  0x110000, 'KEY_EXTENDED == unicode MaxRune + 1';
    is KEY_BACKSPACE, 0x7F,     'KEY_BACKSPACE';
    is KEY_TAB,       0x09,     'KEY_TAB';
    is KEY_ENTER,     0x0D,     'KEY_ENTER';
    is KEY_RETURN,    0x0D,     'KEY_RETURN aliases KEY_ENTER';
    is KEY_ESCAPE,    0x1B,     'KEY_ESCAPE';
    is KEY_ESC,       0x1B,     'KEY_ESC aliases KEY_ESCAPE';
    is KEY_SPACE,     0x20,     'KEY_SPACE';
};
#
subtest bit_flags => sub {
    is FLAG_CTRL_AT,                    1 << 0, 'FLAG_CTRL_AT';
    is FLAG_CTRL_OPEN_BRACKET,          1 << 3, 'FLAG_CTRL_OPEN_BRACKET';
    is FLAG_MOUSE_MODE,                 1 << 9, 'FLAG_MOUSE_MODE';
    is MOD_SHIFT,                       1 << 0, 'MOD_SHIFT';
    is MOD_SCROLL_LOCK,                 1 << 8, 'MOD_SCROLL_LOCK';
    is KITTY_DISAMBIGUATE_ESCAPE_CODES, 1 << 0, 'KITTY_DISAMBIGUATE_ESCAPE_CODES';
    is KITTY_REPORT_ASSOCIATED_TEXT,    1 << 4, 'KITTY_REPORT_ASSOCIATED_TEXT';
};
#
subtest mouse_reexport => sub {
    is MOUSE_NONE,        MouseNone,       'MOUSE_NONE matches Ansi MouseNone';
    is MOUSE_LEFT,        MouseLeft,       'MOUSE_LEFT matches Ansi MouseLeft';
    is MOUSE_MIDDLE,      MouseMiddle,     'MOUSE_MIDDLE matches Ansi MouseMiddle';
    is MOUSE_RIGHT,       MouseRight,      'MOUSE_RIGHT matches Ansi MouseRight';
    is MOUSE_WHEEL_UP,    MouseWheelUp,    'MOUSE_WHEEL_UP matches Ansi MouseWheelUp';
    is MOUSE_WHEEL_DOWN,  MouseWheelDown,  'MOUSE_WHEEL_DOWN matches Ansi MouseWheelDown';
    is MOUSE_WHEEL_LEFT,  MouseWheelLeft,  'MOUSE_WHEEL_LEFT matches Ansi MouseWheelLeft';
    is MOUSE_WHEEL_RIGHT, MouseWheelRight, 'MOUSE_WHEEL_RIGHT matches Ansi MouseWheelRight';
    is MOUSE_BACKWARD,    MouseBackward,   'MOUSE_BACKWARD matches Ansi MouseBackward';
    is MOUSE_FORWARD,     MouseForward,    'MOUSE_FORWARD matches Ansi MouseForward';
    is MOUSE_BUTTON10,    MouseButton10,   'MOUSE_BUTTON10 matches Ansi MouseButton10';
    is MOUSE_BUTTON11,    MouseButton11,   'MOUSE_BUTTON11 matches Ansi MouseButton11';
};
#
subtest clipboard => sub {
    is SYSTEM_CLIPBOARD,  'c', 'SYSTEM_CLIPBOARD re-exported';
    is PRIMARY_CLIPBOARD, 'p', 'PRIMARY_CLIPBOARD re-exported';
};
#
done_testing;
