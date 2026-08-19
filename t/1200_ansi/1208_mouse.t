use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi mouse_test.go
use Cancer::Ansi qw[/[Mm]ouse/];
#
subtest button => sub {
    is encode_mouse_button( MouseNone,       0, 0, 0, 0 ), 3,   'mouse release';
    is encode_mouse_button( MouseNone,       0, 0, 0, 1 ), 19,  'mouse release with ctrl';
    is encode_mouse_button( MouseLeft,       0, 0, 0, 0 ), 0,   'mouse left';
    is encode_mouse_button( MouseRight,      0, 0, 0, 0 ), 2,   'mouse right';
    is encode_mouse_button( MouseWheelUp,    0, 0, 0, 0 ), 64,  'mouse wheel up';
    is encode_mouse_button( MouseWheelRight, 0, 0, 0, 0 ), 67,  'mouse wheel right';
    is encode_mouse_button( MouseBackward,   0, 0, 0, 0 ), 128, 'mouse backward';
    is encode_mouse_button( MouseForward,    0, 0, 0, 0 ), 129, 'mouse forward';
    is encode_mouse_button( MouseButton10,   0, 0, 0, 0 ), 130, 'mouse button 10';
    is encode_mouse_button( MouseButton11,   0, 0, 0, 0 ), 131, 'mouse button 11';
    is encode_mouse_button( MouseMiddle,     1, 0, 0, 0 ), 33,  'mouse middle with motion';
    is encode_mouse_button( MouseMiddle,     0, 1, 0, 0 ), 5,   'mouse middle with shift';
    is encode_mouse_button( MouseMiddle,     1, 0, 1, 0 ), 41,  'mouse middle with motion and alt';
    is encode_mouse_button( MouseRight,      0, 1, 1, 1 ), 30,  'mouse right with shift, alt, and ctrl';
    is encode_mouse_button( MouseButton10,   1, 1, 1, 1 ), 190, 'mouse button 10 with motion, shift, alt, and ctrl';
    is encode_mouse_button( MouseLeft,       1, 1, 0, 1 ), 52,  'mouse left with motion, shift, and ctrl';
    is encode_mouse_button( 255,             0, 0, 0, 0 ), 255, 'invalid mouse button';
    is encode_mouse_button( MouseWheelDown,  1, 0, 0, 0 ), 97,  'mouse wheel down with motion';
    is encode_mouse_button( MouseWheelDown,  0, 1, 0, 1 ), 85,  'mouse wheel down with shift and ctrl';
    is encode_mouse_button( MouseWheelLeft,  0, 0, 1, 0 ), 74,  'mouse wheel left with alt';
    is encode_mouse_button( MouseMiddle,     1, 1, 1, 1 ), 61,  'mouse middle with all modifiers';
};
subtest mouse_sgr => sub {
    my @tests = (
        [ 'mouse right with shift, alt, and ctrl',             10,  1,   0 ],
        [ 'mouse release',                                     5,   5,   1 ],
        [ 'mouse button 10 with motion, shift, alt, and ctrl', 10,  10,  0 ],
        [ 'mouse wheel up with motion',                        15,  15,  0 ],
        [ 'mouse middle with all modifiers',                   20,  20,  0 ],
        [ 'mouse wheel left at max coordinates',               223, 223, 0 ],
        [ 'mouse forward release',                             100, 100, 1 ],
        [ 'mouse backward with shift and ctrl',                50,  50,  0 ]
    );
    for my $tc (@tests) {
        my ( $name, $btn, $x, $y, $release ) = @$tc;
        my $got    = mouse_sgr( $btn, $x, $y, $release );
        my $action = $release ? 'm' : 'M';
        my $want   = sprintf "\e[<%d;%d;%d$action", $btn, $x + 1, $y + 1;
        is $got, $want, $name;
    }
};
#
done_testing;
