use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input key_test.go TestParseSequence plus the
# parser-level cases of TestReadInput.
use utf8;
use Encode        qw[encode];
use Cancer::Input qw[new_parser];
use Cancer::Input qw[MOD_SHIFT MOD_ALT MOD_CTRL MOD_META];
use Cancer::Input qw[KEY_UP KEY_DOWN KEY_RIGHT KEY_LEFT];
use Cancer::Input qw[KEY_DOWN KEY_END KEY_ESCAPE KEY_BACKSPACE KEY_CAPS_LOCK KEY_TAB KEY_SPACE KEY_ENTER];
use Cancer::Input qw[MOUSE_LEFT MOUSE_WHEEL_UP];
my $P = new_parser('Cancer::Input');
sub enc ($s) { encode( 'UTF-8', $s ) }

sub parse_all ($seq) {
    my @events;
    my $buf = $seq;
    while ( defined $buf && length $buf ) {
        my ( $w, $ev ) = $P->parse_sequence($buf);
        last if !$w;
        if ( ref($ev) eq 'Cancer::Input::MultiEvent' ) { push @events, @{ $ev->events // [] } }
        else                                           { push @events, $ev }
        substr( $buf, 0, $w, '' );
    }
    return \@events;
}

sub K ( $code, $mod = 0, $text = '', $is_repeat = 0 ) {
    return {
        class        => 'KeyPressEvent',
        code         => $code,
        mod          => $mod,
        text         => $text,
        shifted_code => 0,
        base_code    => 0,
        is_repeat    => $is_repeat ? 1 : 0
    };
}

sub KR ( $code, $mod = 0, $text = '' ) {
    my $k = K( $code, $mod, $text );
    $k->{class} = 'KeyReleaseEvent';
    return $k;
}
sub M   ( $cls, $x, $y, $btn, $mod = 0 ) { return { class => $cls, x => $x, y => $y, button => $btn, mod => $mod } }
sub UNK ($bytes)            { return { class => 'UnknownEvent',         bytes   => $bytes } }
sub CP  ( $x, $y )          { return { class => 'CursorPositionEvent',  x       => $x,  y    => $y } }
sub WO  ( $op, @args )      { return { class => 'WindowOpEvent',        op      => $op, args => [@args] } }
sub BG  (@rgba)             { return { class => 'BackgroundColorEvent', color   => [@rgba] } }
sub KG  ( $opts, $payload ) { return { class => 'KittyGraphicsEvent',   options => {%$opts}, payload => $payload } }
my $FOCUS = { class => 'FocusEvent' };
my $BLUR  = { class => 'BlurEvent' };
my $PS    = { class => 'PasteStartEvent' };
my $PE    = { class => 'PasteEndEvent' };

sub snap ($e) {
    my $c     = ref $e or return undef;
    my $short = do { local $_ = $c; s/^Cancer::Input:://r };
    if ( $c eq 'Cancer::Input::KeyPressEvent' || $c eq 'Cancer::Input::KeyReleaseEvent' ) {
        return {
            class        => $short,
            code         => $e->code         // 0,
            mod          => $e->mod          // 0,
            text         => $e->text         // '',
            shifted_code => $e->shifted_code // 0,
            base_code    => $e->base_code    // 0,
            is_repeat    => $e->is_repeat ? 1 : 0
        };
    }
    elsif ( $c =~ /^Cancer::Input::Mouse/ ) {
        return { class => $short, x => $e->x // 0, y => $e->y // 0, button => $e->button // 0, mod => $e->mod // 0 };
    }
    elsif ( $c eq 'Cancer::Input::UnknownEvent' ) { return UNK( $e->bytes ) }
    elsif ( $c eq 'Cancer::Input::FocusEvent' ||
        $c eq 'Cancer::Input::BlurEvent'       ||
        $c eq 'Cancer::Input::PasteStartEvent' ||
        $c eq 'Cancer::Input::PasteEndEvent' ) {
        return { class => $short };
    }
    elsif ( $c eq 'Cancer::Input::CursorPositionEvent' ) { return CP( $e->x, $e->y ) }
    elsif ( $c eq 'Cancer::Input::WindowOpEvent' )       { return WO( $e->op, @{ $e->args // [] } ) }
    elsif ( $c =~ /ColorEvent$/ )                        { return { class => $short, color => [ @{ $e->color } ] } }
    elsif ( $c eq 'Cancer::Input::KittyGraphicsEvent' )  { return KG( $e->options, $e->payload ) }
    die "unhandled event class: $c";
}

# X10 wheel up: "\e[M" . chr(32+0b0100_0000) . chr(65) . chr(49)
my $x10_wheelup = "\e[M" . chr( 32 + 0b0100_0000 ) . chr(65) . chr(49);
my @cases       = (

    # --- TestParseSequence appended cases ---
    [ 'background color BEL',     "\e]11;rgb:1234/1234/1234\a",          [ BG( 0x12, 0x12, 0x12, 255 ) ] ],
    [ 'background color ST',      "\e]11;rgb:1234/1234/1234\e\\",        [ BG( 0x12, 0x12, 0x12, 255 ) ] ],
    [ 'incomplete osc ignored',   "\e]11;rgb:1234/1234/1234\e",          [ UNK("\e]11;rgb:1234/1234/1234\e") ] ],
    [ 'kitty graphics transmit',  "\e_Ga=t;OK\e\\",                      [ KG( { a => 't' }, 'OK' ) ] ],
    [ 'kitty graphics id number', "\e_Gi=99,I=13;OK\e\\",                [ KG( { i => 99, I => 13 }, 'OK' ) ] ],
    [ 'kitty graphics einval',    "\e_Gi=1337,q=1;EINVAL:your face\e\\", [ KG( { i => 1337, q => 1 }, 'EINVAL:your face' ) ] ],
    [ 'mok 你 alt',         "\e[27;3;" . ord('你') . "~", [ K( ord('你'), MOD_ALT ) ] ], [ 'mok A alt', "\e[27;3;65~", [ K( ord 'A', MOD_ALT ) ] ],
    [ 'mok backspace alt', "\e[27;3;8~",   [ K( KEY_BACKSPACE, MOD_ALT ) ] ],   [ 'mok esc alt',     "\e[27;3;27~", [ K( KEY_ESCAPE, MOD_ALT ) ] ],
    [ 'mok del alt',       "\e[27;3;127~", [ K( KEY_BACKSPACE, MOD_ALT ) ] ],   [ 'window op size',  "\e[4;24;80t", [ WO( 4, 24, 80 ) ] ],
    [ 'csi 1B',            "\e[1B",        [ K(KEY_DOWN) ] ],                   [ 'csi 1;B',         "\e[1;B",      [ K(KEY_DOWN) ] ],
    [ 'csi 1;4B',          "\e[1;4B", [ K( KEY_DOWN, MOD_SHIFT | MOD_ALT ) ] ], [ 'csi 1;4:1B', "\e[1;4:1B", [ K( KEY_DOWN, MOD_SHIFT | MOD_ALT ) ] ],
    [ 'csi 1;4:2B',        "\e[1;4:2B",   [ K( KEY_DOWN, MOD_SHIFT | MOD_ALT, '', 1 ) ] ],
    [ 'csi 1;4:3B',        "\e[1;4:3B",   [ KR( KEY_DOWN, MOD_SHIFT | MOD_ALT ) ] ], [ 'csi 8~', "\e[8~", [ K(KEY_END) ] ],
    [ 'csi 8;~',           "\e[8;~",      [ K(KEY_END) ] ], [ 'csi 8;10~', "\e[8;10~", [ K( KEY_END, MOD_SHIFT | MOD_META ) ] ],
    [ 'csiu esc',          "\e[27;4u",    [ K( KEY_ESCAPE,    MOD_SHIFT | MOD_ALT ) ] ],
    [ 'csiu backspace',    "\e[127;4u",   [ K( KEY_BACKSPACE, MOD_SHIFT | MOD_ALT ) ] ],
    [ 'csiu capslock',     "\e[57358;4u", [ K( KEY_CAPS_LOCK, MOD_SHIFT | MOD_ALT ) ] ], [ 'csiu tab', "\e[9;2u", [ K( KEY_TAB, MOD_SHIFT ) ] ],
    [ 'csiu Ã press',   "\e[195;u",   [ K( 195, 0, chr(195) ) ] ], [ 'csiu 你 shift',   "\e[20320;2u", [ K( ord('你'), MOD_SHIFT, chr( ord('你') ) ) ] ],
    [ 'csiu Ã :1',      "\e[195;:1u", [ K( 195, 0, chr(195) ) ] ], [ 'csiu Ã release', "\e[195;2:3u", [ KR( 195, MOD_SHIFT, chr(195) ) ] ],
    [ 'csiu Ã repeat',  "\e[195;2:2u", [ K( 195, MOD_SHIFT, chr(195), 1 ) ] ], [ 'csiu Ã press2', "\e[195;2:1u", [ K( 195, MOD_SHIFT, chr(195) ) ] ],
    [ 'csiu shifted A', "\e[97;2;65u", [ K( ord 'a', MOD_SHIFT, 'A' ) ] ],     [ 'csiu alternate å', "\e[97;;229u", [ K( ord 'a', 0, chr(229) ) ] ],
    [ 'focus', "\e[I", [$FOCUS] ], [ 'blur', "\e[O", [$BLUR] ], [ 'x10 wheel up', $x10_wheelup, [ M( 'MouseWheelEvent', 32, 16, MOUSE_WHEEL_UP ) ] ],
    [ 'sgr click left', "\e[<0;33;17M", [ M( 'MouseClickEvent', 32, 16, MOUSE_LEFT ) ] ], [ 'rune a', "a", [ K( ord 'a', 0, 'a' ) ] ],
    [ 'alt+a',          "\ea",    [ K( ord 'a', MOD_ALT ) ] ], [ 'aaa', "aaa", [ K( ord 'a', 0, 'a' ), K( ord 'a', 0, 'a' ), K( ord 'a', 0, 'a' ) ] ],
    [ 'snowman',        enc("☃"), [ K( ord("☃"), 0, "☃" ) ] ],              [ 'alt+snowman',    "\e" . enc("☃"), [ K( ord("☃"), MOD_ALT ) ] ],
    [ 'lone esc',       "\e",     [ K(KEY_ESCAPE) ] ],                      [ 'ctrl+a',         "\x01",          [ K( ord 'a', MOD_CTRL ) ] ],
    [ 'ctrl+alt+a',     "\e\x01", [ K( ord 'a', MOD_CTRL | MOD_ALT ) ] ],   [ 'ctrl+space nul', "\x00",          [ K( KEY_SPACE, MOD_CTRL ) ] ],
    [ 'ctrl+alt+space', "\e\x00", [ K( KEY_SPACE, MOD_CTRL | MOD_ALT ) ] ], [ 'c1 0x80',        "\x80", [ K( 0x80 - ord '@', MOD_CTRL | MOD_ALT ) ] ],

    # Go gates this one on !windows because Go's own UTF-8 decoder accepts it
    # there; our decoder rejects invalid bytes like non-Windows Go.
    [ 'invalid 0xfe', "\xfe", [ UNK("\xfe") ] ],

    # --- Parser-level subset of TestReadInput ---
    [ 'ss3 up',        "\eOA",               [ K(KEY_UP) ] ],
    [ 'ss3 down',      "\eOB",               [ K(KEY_DOWN) ] ],
    [ 'ss3 right',     "\eOC",               [ K(KEY_RIGHT) ] ],
    [ 'ss3 left',      "\eOD",               [ K(KEY_LEFT) ] ],
    [ 'alt+enter',     "\e\r",               [ K( KEY_ENTER,     MOD_ALT ) ] ],
    [ 'alt+backspace', "\e\x7f",             [ K( KEY_BACKSPACE, MOD_ALT ) ] ],
    [ 'esc esc',       "\e\e",               [ K( KEY_ESCAPE,    MOD_ALT ) ] ],
    [ 'paste markers', "\e[200~a b\e[201~o", [ $PS, K( ord 'a', 0, 'a' ), K( KEY_SPACE, 0, ' ' ), K( ord 'b', 0, 'b' ), $PE, K( ord 'o', 0, 'o' ) ] ],
    [   'paste with ctrls',
        "\e[200~a\x03\nb\e[201~", [ $PS, K( ord 'a', 0, 'a' ), K( ord 'c', MOD_CTRL ), K( ord 'j', MOD_CTRL ), K( ord 'b', 0, 'b' ), $PE ]
    ],
    [ 'mixed invalid', "a\xfe b", [ K( ord 'a', 0, 'a' ), UNK("\xfe"), K( KEY_SPACE, 0, ' ' ), K( ord 'b', 0, 'b' ) ] ],

    # Unrecognized CSI sequence (buildBaseSeqTests special cases).
    [ 'unrecognized csi', "\e[-----X", [ UNK("\e[-----X") ] ],
    [ 'lone space',       ' ',         [ K( KEY_SPACE, 0, ' ' ) ] ],
    [ 'esc space',        "\e ",       [ K( KEY_SPACE, MOD_ALT ) ] ]
);
#
for my $case (@cases) {
    my ( $name, $seq, $want ) = @$case;
    subtest $name => sub {
        my @got = map { snap($_) } @{ parse_all($seq) };
        is \@got, $want, 'events match';
    };
}
#
done_testing;
