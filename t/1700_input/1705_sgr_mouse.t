use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input mouse_test.go TestParseSGRMouseEvent
use Cancer::Input qw[new_parser MOD_ALT MOD_CTRL MOD_SHIFT MOUSE_NONE MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT];
use Cancer::Input qw[MOUSE_WHEEL_UP MOUSE_WHEEL_DOWN MOUSE_WHEEL_LEFT MOUSE_WHEEL_RIGHT];
use Cancer::Input qw[MOUSE_BACKWARD MOUSE_FORWARD];
my $P = new_parser('Cancer::Input');

sub encode ( $b, $x, $y, $r ) {
    return sprintf( "\e[<%d;%d;%d%s", $b, $x + 1, $y + 1, $r ? 'm' : 'M' );
}

sub expect ( $name, $buf, $cls, %f ) {
    subtest $name => sub {
        my ( undef, $got ) = $P->parse_sequence($buf);
        isa_ok $got, ["Cancer::Input::$cls"], "isa $cls";
        if ($got) {
            is $got->x,      $f{x}      // 0, 'x';
            is $got->y,      $f{y}      // 0, 'y';
            is $got->button, $f{button} // 0, 'button';
            is $got->mod,    $f{mod}    // 0, 'mod';
        }
    };
}

# Position.
expect( 'zero position', encode( 0, 0, 0, 0 ), MouseClickEvent => button => MOUSE_LEFT );
expect( '225 position', encode( 0, 225, 225, 0 ), MouseClickEvent => x => 225, y => 225, button => MOUSE_LEFT );

# Simple.
expect( 'left press',         encode( 0,   32, 16, 0 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'left in motion',     encode( 32,  32, 16, 0 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'left release',       encode( 0,   32, 16, 1 ), MouseReleaseEvent => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'middle',             encode( 1,   32, 16, 0 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_MIDDLE );
expect( 'middle in motion',   encode( 33,  32, 16, 0 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_MIDDLE );
expect( 'middle release',     encode( 1,   32, 16, 1 ), MouseReleaseEvent => x => 32, y => 16, button => MOUSE_MIDDLE );
expect( 'right',              encode( 2,   32, 16, 0 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_RIGHT );
expect( 'right release',      encode( 2,   32, 16, 1 ), MouseReleaseEvent => x => 32, y => 16, button => MOUSE_RIGHT );
expect( 'motion',             encode( 35,  32, 16, 0 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_NONE );
expect( 'wheel up',           encode( 64,  32, 16, 0 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_UP );
expect( 'wheel down',         encode( 65,  32, 16, 0 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_DOWN );
expect( 'wheel left',         encode( 66,  32, 16, 0 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_LEFT );
expect( 'wheel right',        encode( 67,  32, 16, 0 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_RIGHT );
expect( 'backward',           encode( 128, 32, 16, 0 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_BACKWARD );
expect( 'backward in motion', encode( 160, 32, 16, 0 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_BACKWARD );
expect( 'forward',            encode( 129, 32, 16, 0 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_FORWARD );
expect( 'forward in motion',  encode( 161, 32, 16, 0 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_FORWARD );

# Combinations.
expect( 'alt+right',      encode( 10, 32, 16, 0 ), MouseClickEvent => x => 32, y => 16, mod => MOD_ALT,            button => MOUSE_RIGHT );
expect( 'ctrl+right',     encode( 18, 32, 16, 0 ), MouseClickEvent => x => 32, y => 16, mod => MOD_CTRL,           button => MOUSE_RIGHT );
expect( 'ctrl+alt+right', encode( 26, 32, 16, 0 ), MouseClickEvent => x => 32, y => 16, mod => MOD_ALT | MOD_CTRL, button => MOUSE_RIGHT );
expect( 'alt+wheel',      encode( 73, 32, 16, 0 ), MouseWheelEvent => x => 32, y => 16, mod => MOD_ALT,            button => MOUSE_WHEEL_DOWN );
expect( 'ctrl+wheel',     encode( 81, 32, 16, 0 ), MouseWheelEvent => x => 32, y => 16, mod => MOD_CTRL,           button => MOUSE_WHEEL_DOWN );
expect( 'ctrl+alt+wheel', encode( 89, 32, 16, 0 ), MouseWheelEvent => x => 32, y => 16, mod => MOD_ALT | MOD_CTRL, button => MOUSE_WHEEL_DOWN );
expect(
    'ctrl+alt+shift+wheel', encode( 93, 32, 16, 0 ), MouseWheelEvent => x => 32,
    y      => 16,
    mod    => MOD_ALT | MOD_SHIFT | MOD_CTRL,
    button => MOUSE_WHEEL_DOWN
);
#
done_testing;
