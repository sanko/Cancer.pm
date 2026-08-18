use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi mouse_test.go
use Cancer::Ansi;
subtest 'TestMouseButton' => sub {
    my @tests = (
        [ 'mouse release',                                     Cancer::Ansi::MouseNone,       0, 0, 0, 0, 0b0000_0011 ],
        [ 'mouse release with ctrl',                           Cancer::Ansi::MouseNone,       0, 0, 0, 1, 0b0001_0011 ],
        [ 'mouse left',                                        Cancer::Ansi::MouseLeft,       0, 0, 0, 0, 0b0000_0000 ],
        [ 'mouse right',                                       Cancer::Ansi::MouseRight,      0, 0, 0, 0, 0b0000_0010 ],
        [ 'mouse wheel up',                                    Cancer::Ansi::MouseWheelUp,    0, 0, 0, 0, 0b0100_0000 ],
        [ 'mouse wheel right',                                 Cancer::Ansi::MouseWheelRight, 0, 0, 0, 0, 0b0100_0011 ],
        [ 'mouse backward',                                    Cancer::Ansi::MouseBackward,   0, 0, 0, 0, 0b1000_0000 ],
        [ 'mouse forward',                                     Cancer::Ansi::MouseForward,    0, 0, 0, 0, 0b1000_0001 ],
        [ 'mouse button 10',                                   Cancer::Ansi::MouseButton10,   0, 0, 0, 0, 0b1000_0010 ],
        [ 'mouse button 11',                                   Cancer::Ansi::MouseButton11,   0, 0, 0, 0, 0b1000_0011 ],
        [ 'mouse middle with motion',                          Cancer::Ansi::MouseMiddle,     1, 0, 0, 0, 0b0010_0001 ],
        [ 'mouse middle with shift',                           Cancer::Ansi::MouseMiddle,     0, 1, 0, 0, 0b0000_0101 ],
        [ 'mouse middle with motion and alt',                  Cancer::Ansi::MouseMiddle,     1, 0, 1, 0, 0b0010_1001 ],
        [ 'mouse right with shift, alt, and ctrl',             Cancer::Ansi::MouseRight,      0, 1, 1, 1, 0b0001_1110 ],
        [ 'mouse button 10 with motion, shift, alt, and ctrl', Cancer::Ansi::MouseButton10,   1, 1, 1, 1, 0b1011_1110 ],
        [ 'mouse left with motion, shift, and ctrl',           Cancer::Ansi::MouseLeft,       1, 1, 0, 1, 0b0011_0100 ],
        [ 'invalid mouse button',                              255,                           0, 0, 0, 0, 0b1111_1111 ],
        [ 'mouse wheel down with motion',                      Cancer::Ansi::MouseWheelDown,  1, 0, 0, 0, 0b0110_0001 ],
        [ 'mouse wheel down with shift and ctrl',              Cancer::Ansi::MouseWheelDown,  0, 1, 0, 1, 0b0101_0101 ],
        [ 'mouse wheel left with alt',                         Cancer::Ansi::MouseWheelLeft,  0, 0, 1, 0, 0b0100_1010 ],
        [ 'mouse middle with all modifiers',                   Cancer::Ansi::MouseMiddle,     1, 1, 1, 1, 0b0011_1101 ],
    );
    for my $tc (@tests) {
        my ( $name, $btn, $motion, $shift, $alt, $ctrl, $want ) = @$tc;
        my $got = Cancer::Ansi::encode_mouse_button( $btn, $motion, $shift, $alt, $ctrl );
        is $got, $want, $name;
    }
};
subtest 'TestMouseSgr' => sub {
    my @tests = (
        [ 'mouse left',                            Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseLeft,      0, 0, 0, 0 ), 0,  0,  0 ],
        [ 'wheel down',                            Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseWheelDown, 0, 0, 0, 0 ), 1,  10, 0 ],
        [ 'mouse right with shift, alt, and ctrl', Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseRight,     0, 1, 1, 1 ), 10, 1,  0 ],
        [ 'mouse release',                         Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseNone,      0, 0, 0, 0 ), 5,  5,  1 ],
        [   'mouse button 10 with motion, shift, alt, and ctrl',
            Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseButton10, 1, 1, 1, 1 ),
            10, 10, 0
        ],
        [ 'mouse wheel up with motion',          Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseWheelUp,   1, 0, 0, 0 ), 15,  15,  0 ],
        [ 'mouse middle with all modifiers',     Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseMiddle,    1, 1, 1, 1 ), 20,  20,  0 ],
        [ 'mouse wheel left at max coordinates', Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseWheelLeft, 0, 0, 0, 0 ), 223, 223, 0 ],
        [ 'mouse forward release',               Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseForward,   0, 0, 0, 0 ), 100, 100, 1 ],
        [ 'mouse backward with shift and ctrl',  Cancer::Ansi::encode_mouse_button( Cancer::Ansi::MouseBackward,  0, 1, 0, 1 ), 50,  50,  0 ],
    );
    for my $tc (@tests) {
        my ( $name, $btn, $x, $y, $release ) = @$tc;
        my $got    = Cancer::Ansi::mouse_sgr( $btn, $x, $y, $release );
        my $action = $release ? 'm' : 'M';
        my $want   = sprintf "\e[<%d;%d;%d$action", $btn, $x + 1, $y + 1;
        is $got, $want, $name;
    }
};
done_testing;
