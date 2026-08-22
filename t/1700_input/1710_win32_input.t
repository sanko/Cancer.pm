use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input driver_windows_test.go TestWindowsInputEvents.
#
# Go drives these through parseConInputEvent / parseWin32InputKeyEvent with a
# win32InputState; our port exposes Cancer::Input::new_win32_state and
# Cancer::Input::parse_con_input_event. Like the Go test, one Parser and one
# state are shared across all cases.
#
# InputRecord records are plain hashrefs (see parse_con_input_event).
use utf8;
use Encode        qw[encode];
use Cancer::Input qw[
    new_parser new_win32_state
    MOD_SHIFT MOD_ALT MOD_CTRL
    KEY_LEFT_SHIFT KEY_RIGHT_SHIFT
    CKS_SHIFT CKS_LEFT_ALT CKS_LEFT_CTRL CKS_ENHANCED
    BTN_FROM_LEFT_1ST EVF_MOUSE_MOVED EVF_WHEELED EVF_HWHEELED EVF_DOUBLE_CLICK
];
my $P     = new_parser('Cancer::Input');
my $STATE = new_win32_state();
sub enc ($s) { encode( 'UTF-8', $s ) }

sub key_rec (%f) {
    return {
        type   => 'key',
        vkc    => $f{vkc}  // 0,
        scan   => $f{scan} // 0,
        char   => $f{char} // 0,
        down   => $f{down} ? 1 : 0,
        cks    => $f{cks}    // 0,
        repeat => $f{repeat} // 1
    };
}

# encodeSequence: each byte of an ANSI sequence arrives as its own key record.
sub seq_recs ($s) {
    my $b = enc($s);
    return map { key_rec( char => ord ) } split //, $b;
}

# encodeUtf16Rune: a supplementary plane codepoint as a surrogate half pair.
sub utf16_recs ($cp) {
    my $v  = $cp - 0x10000;
    my $hi = 0xD800 | ( $v >> 10 );
    my $lo = 0xDC00 | ( $v & 0x3FF );
    return ( key_rec( char => $hi, down => 1 ), key_rec( char => $lo, down => 1 ) );
}

sub mouse_rec (%f) {
    return { type => 'mouse', x => $f{x} // 0, y => $f{y} // 0, button_state => $f{button_state} // 0, cks => $f{cks} // 0, flags => $f{flags} // 0 };
}

sub snap_ev ($e) {
    my $c     = ref $e or die "not an event";
    my $short = do { local $_ = $c; s/^Cancer::Input:://r };
    if ( $c =~ /Key(Press|Release)Event/ ) {
        return {
            class        => $short,
            code         => $e->code         // 0,
            mod          => $e->mod          // 0,
            text         => $e->text         // '',
            base_code    => $e->base_code    // 0,
            shifted_code => $e->shifted_code // 0,
            is_repeat    => 0
        };
    }
    elsif ( $c =~ /^Cancer::Input::Mouse/ ) {
        return { class => $short, x => $e->x, y => $e->y, button => $e->button, mod => $e->mod // 0 };
    }
    elsif ( $c eq 'Cancer::Input::BackgroundColorEvent' || $c eq 'Cancer::Input::ForegroundColorEvent' ) {
        return { class => $short, color => $e->color };
    }
    elsif ( $c eq 'Cancer::Input::WindowSizeEvent' ) {
        return { class => $short, width => $e->width, height => $e->height };
    }
    elsif ( $c eq 'Cancer::Input::FocusEvent' || $c eq 'Cancer::Input::BlurEvent' ) {
        return { class => $short };
    }
    die "unhandled event class: $c";
}

sub K ( $code, $mod, $text, $base = 0, $shifted = 0 ) {
    return { class => 'KeyPressEvent', code => $code, mod => $mod, text => $text, base_code => $base, shifted_code => $shifted, is_repeat => 0 };
}

sub drive_case ( $name, $recs, @want ) {
    subtest $name => sub {
        my @got;
        for my $rec (@$recs) {
            my $ev = $P->parse_con_input_event( $rec, $STATE );
            push @got, $ev if defined $ev;
        }
        is [ map { snap_ev($_) } @got ], [@want], 'events match';
    };
}

# --- key events ------------------------------------------------------------
drive_case( 'single key event', [ key_rec( vkc => ord('A'), char => ord('a'), down => 1 ) ], K( ord('a'), 0, 'a', ord('a') ) );
drive_case(
    'single key event with control key',
    [ key_rec( vkc => ord('A'), char => ord('a'), down => 1, cks => CKS_LEFT_CTRL ) ],
    K( ord('a'), MOD_CTRL, '', ord('a') )
);
drive_case( 'escape alt key event', [ key_rec( vkc => 27, char => 27, down => 1, cks => CKS_LEFT_ALT ) ], K( 27, MOD_ALT, '', 27 ) );
drive_case(
    'single shifted key event',
    [ key_rec( vkc => ord('A'), char => ord('A'), down => 1, cks => CKS_SHIFT ) ],
    K( ord('A'), MOD_SHIFT, 'A', ord('a') )
);
drive_case(
    'right shift press via scan code',

    # Consoles do not set ENHANCED_KEY for right Shift; the scan code is
    # authoritative (0x2A left, 0x36 right).
    [ key_rec( vkc => 0x10, scan => 0x36, down => 1, cks => CKS_SHIFT ) ], K( KEY_RIGHT_SHIFT, MOD_SHIFT, '', KEY_RIGHT_SHIFT )
);
drive_case(
    'left shift press via scan code',
    [ key_rec( vkc => 0x10, scan => 0x2A, down => 1, cks => CKS_SHIFT ) ],
    K( KEY_LEFT_SHIFT, MOD_SHIFT, '', KEY_LEFT_SHIFT )
);
drive_case(
    'right shift release via scan code',
    [ key_rec( vkc => 0x10, scan => 0x36, down => 0 ) ],
    { class => 'KeyReleaseEvent', code => KEY_RIGHT_SHIFT, mod => 0, text => '', base_code => KEY_RIGHT_SHIFT, shifted_code => 0, is_repeat => 0 }
);

# --- utf16 surrogate pairs -------------------------------------------------
drive_case(
    'utf16 rune', [ utf16_recs(0x1F60A) ],    # smiley emoji U+1F60A
    K( 0x1F60A, 0, "\x{1F60A}" )
);

# --- ANSI sequence accumulation -------------------------------------------
drive_case(
    'background color response',
    [ seq_recs("\e]11;rgb:ff/ff/ff\x07") ],
    { class => 'BackgroundColorEvent', color => [ 255, 255, 255, 255 ] }
);
drive_case(
    'st terminated background color response',
    [ seq_recs("\e]11;rgb:ffff/ffff/ffff\e\\") ],
    { class => 'BackgroundColorEvent', color => [ 255, 255, 255, 255 ] }
);

# --- mouse events ----------------------------------------------------------
drive_case(
    'simple mouse event',
    [ mouse_rec( x => 10, y => 20, button_state => BTN_FROM_LEFT_1ST ), mouse_rec( x => 10, y => 20 ) ],
    { class => 'MouseClickEvent',   x => 10, y => 20, button => 1, mod => 0 },
    { class => 'MouseReleaseEvent', x => 10, y => 20, button => 1, mod => 0 }
);
drive_case(
    'double click reports click',

    # last_mouse_btns is 0 after the simple mouse case, so this is a press.
    [ mouse_rec( x => 3, y => 4, button_state => BTN_FROM_LEFT_1ST, flags => EVF_DOUBLE_CLICK ) ],
    { class => 'MouseClickEvent', x => 3, y => 4, button => 1, mod => 0 }
);
drive_case(
    'mouse motion event',
    [ mouse_rec( x => 5, y => 6, button_state => BTN_FROM_LEFT_1ST, flags => EVF_MOUSE_MOVED ) ],
    { class => 'MouseMotionEvent', x => 5, y => 6, button => 1, mod => 0 }
);
drive_case(
    'wheel events',
    [   mouse_rec( x => 1, y => 2, button_state => 0x00320000, flags => EVF_WHEELED ),    # positive delta
        mouse_rec( x => 1, y => 2, button_state => 0xFFCE0000, flags => EVF_WHEELED ),    # negative delta
        mouse_rec( x => 1, y => 2, button_state => 0x00320000, flags => EVF_HWHEELED ),
        mouse_rec( x => 1, y => 2, button_state => 0xFFCE0000, flags => EVF_HWHEELED )
    ],
    { class => 'MouseWheelEvent', x => 1, y => 2, button => 4, mod => 0 },    # up
    { class => 'MouseWheelEvent', x => 1, y => 2, button => 5, mod => 0 },    # down
    { class => 'MouseWheelEvent', x => 1, y => 2, button => 7, mod => 0 },    # right
    { class => 'MouseWheelEvent', x => 1, y => 2, button => 6, mod => 0 },    # left
);

# --- focus events ----------------------------------------------------------
drive_case( 'focus event', [ { type => 'focus', set => 1 }, { type => 'focus', set => 0 } ], { class => 'FocusEvent' }, { class => 'BlurEvent' } );

# --- window size events ----------------------------------------------------
drive_case(
    'window size event',
    [   { type => 'window_size', w => 10, h => 20 }, { type => 'window_size', w => 10, h => 20 },    # deduped: same size again
        { type => 'window_size', w => 30, h => 40 }
    ],
    { class => 'WindowSizeEvent', width => 10, height => 20 },
    { class => 'WindowSizeEvent', width => 30, height => 40 }
);
drive_case( 'menu events ignored', [ { type => 'menu', command_id => 42 } ] );
done_testing;
