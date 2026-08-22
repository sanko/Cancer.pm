use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input mouse_test.go TestParseX10MouseDownEvent
use Cancer::Input qw[new_parser MOD_ALT MOD_CTRL MOUSE_NONE MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT];
use Cancer::Input qw[MOUSE_WHEEL_UP MOUSE_WHEEL_DOWN MOUSE_WHEEL_LEFT MOUSE_WHEEL_RIGHT];
use Cancer::Input qw[MOUSE_BACKWARD MOUSE_FORWARD MOUSE_BUTTON10 MOUSE_BUTTON11];
my $P = new_parser('Cancer::Input');

# Go: byte(32)+b, byte(x+32+1), byte(y+32+1) -- byte() truncates to 8 bits.
sub encode ( $b, $x, $y ) {
    return "\e[M" . chr( 32 + $b ) . chr( ( $x + 33 ) & 0xFF ) . chr( ( $y + 33 ) & 0xFF );
}

sub parse_one ($seq) {
    my ( undef, $ev ) = $P->parse_sequence($seq);
    return $ev;
}

sub expect ( $name, $buf, $cls, %f ) {
    subtest $name => sub {
        my $got = parse_one($buf);
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
expect( 'zero position', encode( 0b0000_0000, 0, 0 ), MouseClickEvent => button => MOUSE_LEFT );
expect( 'max position', encode( 0b0000_0000, 222, 222 ), MouseClickEvent => x => 222, y => 222, button => MOUSE_LEFT )
    ;    # Because 255 (max int8) - 32 - 1.

# Simple.
expect( 'left',             encode( 0b0000_0000, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'left in motion',   encode( 0b0010_0000, 32, 16 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'middle',           encode( 0b0000_0001, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_MIDDLE );
expect( 'middle in motion', encode( 0b0010_0001, 32, 16 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_MIDDLE );
expect( 'right',            encode( 0b0000_0010, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_RIGHT );
expect( 'right in motion',  encode( 0b0010_0010, 32, 16 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_RIGHT );
expect( 'motion',           encode( 0b0010_0011, 32, 16 ), MouseMotionEvent  => x => 32, y => 16, button => MOUSE_NONE );
expect( 'wheel up',         encode( 0b0100_0000, 32, 16 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_UP );
expect( 'wheel down',       encode( 0b0100_0001, 32, 16 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_DOWN );
expect( 'wheel left',       encode( 0b0100_0010, 32, 16 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_LEFT );
expect( 'wheel right',      encode( 0b0100_0011, 32, 16 ), MouseWheelEvent   => x => 32, y => 16, button => MOUSE_WHEEL_RIGHT );
expect( 'release',          encode( 0b0000_0011, 32, 16 ), MouseReleaseEvent => x => 32, y => 16, button => MOUSE_NONE );
expect( 'backward',         encode( 0b1000_0000, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_BACKWARD );
expect( 'forward',          encode( 0b1000_0001, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_FORWARD );
expect( 'button 10',        encode( 0b1000_0010, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_BUTTON10 );
expect( 'button 11',        encode( 0b1000_0011, 32, 16 ), MouseClickEvent   => x => 32, y => 16, button => MOUSE_BUTTON11 );

# Combinations.
expect( 'alt+right',            encode( 0b0000_1010, 32, 16 ), MouseClickEvent  => x => 32, y => 16, mod    => MOD_ALT,  button => MOUSE_RIGHT );
expect( 'ctrl+right',           encode( 0b0001_0010, 32, 16 ), MouseClickEvent  => x => 32, y => 16, mod    => MOD_CTRL, button => MOUSE_RIGHT );
expect( 'left in motion (2)',   encode( 0b0010_0000, 32, 16 ), MouseMotionEvent => x => 32, y => 16, button => MOUSE_LEFT );
expect( 'alt+right in motion',  encode( 0b0010_1010, 32, 16 ), MouseMotionEvent => x => 32, y => 16, mod    => MOD_ALT,  button => MOUSE_RIGHT );
expect( 'ctrl+right in motion', encode( 0b0011_0010, 32, 16 ), MouseMotionEvent => x => 32, y => 16, mod    => MOD_CTRL, button => MOUSE_RIGHT );
expect( 'ctrl+alt+right', encode( 0b0001_1010, 32, 16 ), MouseClickEvent => x => 32, y => 16, mod => MOD_ALT | MOD_CTRL, button => MOUSE_RIGHT );
expect( 'ctrl+wheel up',  encode( 0b0101_0000, 32, 16 ), MouseWheelEvent => x => 32, y => 16, mod => MOD_CTRL,           button => MOUSE_WHEEL_UP );
expect( 'alt+wheel down', encode( 0b0100_1001, 32, 16 ), MouseWheelEvent => x => 32, y => 16, mod => MOD_ALT,            button => MOUSE_WHEEL_DOWN );
expect(
    'ctrl+alt+wheel down', encode( 0b0101_1001, 32, 16 ), MouseWheelEvent => x => 32,
    y      => 16,
    mod    => MOD_ALT | MOD_CTRL,
    button => MOUSE_WHEEL_DOWN
);

# Overflow position.
expect( 'overflow position', encode( 0b0010_0000, 250, 223 ), MouseMotionEvent => x => -6, y => -33, button => MOUSE_LEFT )
    ;    # Because 255 (max int8) - 32 - 1.
#
done_testing;
