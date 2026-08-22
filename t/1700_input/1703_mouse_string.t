use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input mouse_test.go TestMouseEvent_String
use Cancer::Input qw[
    MOD_SHIFT MOD_ALT MOD_CTRL
    MOUSE_NONE MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT MOUSE_WHEEL_UP MOUSE_WHEEL_DOWN
    MOUSE_WHEEL_LEFT MOUSE_WHEEL_RIGHT
];
my @tt = (
    { name => 'unknown',    event => Cancer::Input::MouseClickEvent->new( button => 0xff ),              expected => 'unknown' },
    { name => 'left',       event => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT ),        expected => 'left' },
    { name => 'right',      event => Cancer::Input::MouseClickEvent->new( button => MOUSE_RIGHT ),       expected => 'right' },
    { name => 'middle',     event => Cancer::Input::MouseClickEvent->new( button => MOUSE_MIDDLE ),      expected => 'middle' },
    { name => 'release',    event => Cancer::Input::MouseReleaseEvent->new( button => MOUSE_NONE ),      expected => '' },
    { name => 'wheelup',    event => Cancer::Input::MouseWheelEvent->new( button => MOUSE_WHEEL_UP ),    expected => 'wheelup' },
    { name => 'wheeldown',  event => Cancer::Input::MouseWheelEvent->new( button => MOUSE_WHEEL_DOWN ),  expected => 'wheeldown' },
    { name => 'wheelleft',  event => Cancer::Input::MouseWheelEvent->new( button => MOUSE_WHEEL_LEFT ),  expected => 'wheelleft' },
    { name => 'wheelright', event => Cancer::Input::MouseWheelEvent->new( button => MOUSE_WHEEL_RIGHT ), expected => 'wheelright' },
    { name => 'motion',     event => Cancer::Input::MouseMotionEvent->new( button => MOUSE_NONE ),       expected => 'motion' },
    {   name     => 'shift+left release',
        event    => Cancer::Input::MouseReleaseEvent->new( button => MOUSE_LEFT, mod => MOD_SHIFT ),
        expected => 'shift+left'
    },
    { name => 'shift+left click', event => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_SHIFT ), expected => 'shift+left' },
    {   name     => 'ctrl+shift+left',
        event    => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_CTRL | MOD_SHIFT ),
        expected => 'ctrl+shift+left'
    },
    { name => 'alt+left',  event => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_ALT ),  expected => 'alt+left' },
    { name => 'ctrl+left', event => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_CTRL ), expected => 'ctrl+left' },
    {   name     => 'ctrl+alt+left',
        event    => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_ALT | MOD_CTRL ),
        expected => 'ctrl+alt+left'
    },
    {   name     => 'ctrl+alt+shift+left',
        event    => Cancer::Input::MouseClickEvent->new( button => MOUSE_LEFT, mod => MOD_ALT | MOD_CTRL | MOD_SHIFT ),
        expected => 'ctrl+alt+shift+left'
    },
    { name => 'ignore coordinates', event => Cancer::Input::MouseClickEvent->new( x => 100, y => 200, button => MOUSE_LEFT ), expected => 'left' },
    { name => 'broken type',        event => Cancer::Input::MouseClickEvent->new( button => 120 ),                            expected => 'unknown' }
);
#
for my $tc (@tt) {
    subtest $tc->{name} => sub {
        is $tc->{event}->string, $tc->{expected}, "expected '$tc->{expected}'";
    };
}
#
done_testing;
