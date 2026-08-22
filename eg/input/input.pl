use v5.42;
use warnings;
use lib '../../lib';

# Live smoke test for Cancer::Input's platform drivers.
#
#     perl input.pl            # from this directory
#
# Windows: switches the console into record mode (keys, mouse, focus, and
# resizes arrive as INPUT_RECORD structs), decodes each struct, and feeds the
# records through Cancer::Input::parse_con_input_event with shared driver
# state - exactly what Cancer.pm's Windows terminal layer will do.
#
# POSIX: puts the tty in raw mode (output stays readable via CRLF), enables
# SGR mouse reporting (with motion) and focus reporting, reports resizes from
# SIGWINCH, then feeds every byte read from stdin through parse_sequence -
# mirroring charmbracelet/x/input's driver_other.go, whose entire Unix
# "driver" is read-bytes-and-parse. INT/TERM/HUP/QUIT are trapped so cleanup
# always runs and the terminal is restored even when killed.
#
# The Kitty keyboard protocol is requested by default so POSIX terminals that
# implement it produce the same press/release/modifier-only events as the
# Windows console path. Set CANCER_KITTY=0 to stay in legacy byte mode.
# (\e[>11u: disambiguate | event types | all keys as escape codes.) The demo
# then probes the terminal (\e[?u\e[c) and reports whether the protocol was
# actually confirmed -- e.g. Windows Terminal stable (< 1.25) silently ignores
# the request, so this line tells you why releases are missing.
#
# Try typing keys (arrows, F-keys, emoji, AltGr combos), clicking /
# double-clicking / dragging / wheeling the mouse, resizing the window (and
# alt-tabbing away and back), then quit with Ctrl+Q or Ctrl+C.
binmode STDOUT, ':encoding(UTF-8)';
$| = 1;
use Cancer::Input qw[
    new_parser new_win32_state
    MOD_SHIFT MOD_ALT MOD_CTRL MOD_META MOD_SUPER MOD_HYPER
    MOUSE_NONE MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT
    MOUSE_WHEEL_UP MOUSE_WHEEL_DOWN MOUSE_WHEEL_LEFT MOUSE_WHEEL_RIGHT
    MOUSE_BACKWARD MOUSE_FORWARD
];
use Affix qw[:all];                        # kernel32 bindings are made lazily on Windows
my $P     = new_parser('Cancer::Input');
my $STATE = new_win32_state();             # consumed by the Windows record path only
my $quit  = 0;

# Driver cleanup state, restored by END blocks below.
my ( $WIN_HANDLE_IN, $WIN_HANDLE_OUT, $WIN_MODE_IN, $WIN_MODE_OUT );
my ( $POSIX_STATE, $POSIX_KITTY );

# Kitty capability probe state (POSIX only): 1 while waiting for the terminal
# to answer our \e[?u / \e[c queries, with a wall-clock deadline; the flags the
# terminal reported once it answers.
my ( $KITTY_PROBE, $KITTY_DEADLINE, $KITTY_FLAGS );
if   ( $^O eq 'MSWin32' ) { run_win32() }
else                      { run_posix() }
print "\r\nBye!\r\n";
exit;

sub decode_mods ($mod) {
    my $s = '';
    $s .= 'shift+' if $mod & MOD_SHIFT;
    $s .= 'alt+'   if $mod & MOD_ALT;
    $s .= 'ctrl+'  if $mod & MOD_CTRL;
    $s .= 'meta+'  if $mod & MOD_META;
    $s .= 'super+' if $mod & MOD_SUPER;
    $s .= 'hyper+' if $mod & MOD_HYPER;
    return $s;
}
my %BUTTON_NAME = (
    MOUSE_NONE(),     'none',     MOUSE_LEFT(),       'left',       MOUSE_MIDDLE(),     'middle',     MOUSE_RIGHT(),       'right',
    MOUSE_WHEEL_UP(), 'wheel-up', MOUSE_WHEEL_DOWN(), 'wheel-down', MOUSE_WHEEL_LEFT(), 'wheel-left', MOUSE_WHEEL_RIGHT(), 'wheel-right',
    MOUSE_BACKWARD(), 'backward', MOUSE_FORWARD(),    'forward'
);

sub render ($e) {
    my $name = ref($e) =~ s/^Cancer::Input:://r;
    if ( ref $e eq 'Cancer::Input::KeyPressEvent' || ref $e eq 'Cancer::Input::KeyReleaseEvent' ) {
        printf "%-18s %-18s code=%-6d base=%-6d text=\"%s\"\r\n", $name, $e->keystroke, $e->code, $e->base_code // 0, $e->text // '';
    }
    elsif ( ref $e =~ /^Cancer::Input::Mouse/ ) {
        printf "%-18s x=%-4d y=%-4d button=%-11s mod=%s\r\n", $name, $e->x, $e->y, $BUTTON_NAME{ $e->button } // $e->button,
            decode_mods( $e->mod ) || '-';
    }
    elsif ( ref $e eq 'Cancer::Input::WindowSizeEvent' ) {
        printf "%-18s %dx%d\r\n", $name, $e->width, $e->height;
    }
    elsif ( ref $e eq 'Cancer::Input::CursorPositionEvent' ) {
        printf "%-18s x=%-4d y=%-4d\r\n", $name, $e->x, $e->y;
    }
    elsif ( $e->can('string') ) {
        printf "%-18s %s\r\n", $name, $e->string;
    }
    else {
        print "$name\r\n";
    }
}

sub handle ($event) {
    for my $e ( ref($event) eq 'Cancer::Input::MultiEvent' ? @{ $event->events } : $event ) {
        if ($KITTY_PROBE) {
            if ( $e->isa('Cancer::Input::KittyEnhancementsEvent') ) {
                printf "kitty protocol   : confirmed, flags=0x%x -- releases and modifier events enabled\r\n", $e->flags;
                $KITTY_FLAGS = $e->flags;

                # Stay armed: swallow the DA1 reply that follows.
                next;
            }
            elsif ( $e->isa('Cancer::Input::PrimaryDeviceAttributesEvent') ) {
                print "kitty protocol   : not supported by this terminal -- legacy byte stream\r\n" unless defined $KITTY_FLAGS;
                $KITTY_PROBE = 0;
                next;
            }
        }
        if ( $e->isa('Cancer::Input::KeyPressEvent') && ( $e->mod & MOD_CTRL ) && $e->code < 128 && lc chr( $e->code ) =~ /^[cq]\z/ ) {
            $quit = 1;
            return;
        }
        render($e);
    }
}

# --- Windows: console INPUT_RECORD path ------------------------------------
sub run_win32 () {
    die 'This demo requires a console.' unless -t STDIN;
    affix( 'kernel32', 'GetStdHandle',      [Int]                                        => Long );
    affix( 'kernel32', 'GetConsoleMode',    [ Long, Pointer [Int] ]                      => Int );
    affix( 'kernel32', 'SetConsoleMode',    [ Long, Int ]                                => Int );
    affix( 'kernel32', 'ReadConsoleInputW', [ Long, Pointer [Void], Int, Pointer [Int] ] => Int );
    use constant {
        STD_INPUT_HANDLE  => -10,
        STD_OUTPUT_HANDLE => -11,

        # Input mode flags
        ENABLE_PROCESSED_INPUT        => 0x0001,
        ENABLE_LINE_INPUT             => 0x0002,
        ENABLE_ECHO_INPUT             => 0x0004,
        ENABLE_WINDOW_INPUT           => 0x0008,
        ENABLE_MOUSE_INPUT            => 0x0010,
        ENABLE_QUICK_EDIT_MODE        => 0x0040,
        ENABLE_EXTENDED_FLAGS         => 0x0080,
        ENABLE_VIRTUAL_TERMINAL_INPUT => 0x0200,

        # Output mode flags
        ENABLE_VIRTUAL_TERMINAL_PROCESSING => 0x0004,

        # INPUT_RECORD EventTypes
        KEY_EVENT                => 0x0001,
        MOUSE_EVENT              => 0x0002,
        WINDOW_BUFFER_SIZE_EVENT => 0x0004,
        MENU_EVENT               => 0x0008,
        FOCUS_EVENT              => 0x0010
    };

    # sizeof(INPUT_RECORD) is 20 on both 32- and 64-bit Windows: WORD
    # EventType, two bytes of padding, then a 16-byte union.
    use constant RECORD_SIZE => 20;
    ( $WIN_HANDLE_IN, $WIN_HANDLE_OUT ) = ( GetStdHandle(STD_INPUT_HANDLE), GetStdHandle(STD_OUTPUT_HANDLE) );
    ( $WIN_MODE_IN, $WIN_MODE_OUT ) = ( 0, 0 );
    GetConsoleMode( $WIN_HANDLE_IN,  \$WIN_MODE_IN ) or die "stdin is not a console handle\n";
    GetConsoleMode( $WIN_HANDLE_OUT, \$WIN_MODE_OUT );

    # Raw record mode: no echo, line editing, or signal processing; no VT
    # translation. QUICK_EDIT_MODE must be cleared (with EXTENDED_FLAGS) for
    # mouse records to reach us.
    SetConsoleMode(
        $WIN_HANDLE_IN, (
            $WIN_MODE_IN
                & ~( ENABLE_PROCESSED_INPUT | ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_QUICK_EDIT_MODE | ENABLE_VIRTUAL_TERMINAL_INPUT )
        ) | ENABLE_EXTENDED_FLAGS | ENABLE_MOUSE_INPUT | ENABLE_WINDOW_INPUT
        ) or
        die "SetConsoleMode(stdin): $^E\n";
    SetConsoleMode( $WIN_HANDLE_OUT, $WIN_MODE_OUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING );    # best effort

    END {
        if ( defined &SetConsoleMode ) {
            SetConsoleMode( $WIN_HANDLE_IN,  $WIN_MODE_IN )  if $WIN_MODE_IN;
            SetConsoleMode( $WIN_HANDLE_OUT, $WIN_MODE_OUT ) if $WIN_MODE_OUT;
        }
    }

    sub unpack_record ($rec) {
        my ($type) = unpack 'v', $rec;
        if ( $type == KEY_EVENT ) {
            my ( $down, $repeat, $vkc, $scan, $wchar, $cks ) = unpack 'VvvvvV', substr $rec, 4, 16;
            return { type => 'key', vkc => $vkc, scan => $scan, char => $wchar || 0, down => $down ? 1 : 0, cks => $cks, repeat => $repeat };
        }
        elsif ( $type == MOUSE_EVENT ) {
            my ( $x, $y, $btns, $cks, $flags ) = unpack 'ssVVV', substr $rec, 4, 16;
            return { type => 'mouse', x => $x, y => $y, button_state => $btns, cks => $cks, flags => $flags };
        }
        elsif ( $type == WINDOW_BUFFER_SIZE_EVENT ) {
            my ( $w, $h ) = unpack 'vv', substr $rec, 4, 4;
            return { type => 'window_size', w => $w, h => $h };
        }
        elsif ( $type == FOCUS_EVENT ) {
            my ($set) = unpack 'V', substr $rec, 4, 4;
            return { type => 'focus', set => $set ? 1 : 0 };
        }
        return { type => 'menu' };    # MENU_EVENT (and anything unknown) is ignored by the parser
    }
    print <<"EOT";

Cancer::Input live demo -- Windows console records

  keys   : type anything (arrows, F-keys, emoji Win+., AltGr combos)
  mouse  : click, double-click, drag, scroll wheel
  window : resize to see WindowSizeEvents
  focus  : alt-tab away and back
  exit   : Ctrl+Q or Ctrl+C

--------------------------------------------------------------------
EOT
    my $buf = "\0" x ( RECORD_SIZE * 64 );
    until ($quit) {
        my $read = 0;
        last unless ReadConsoleInputW( $WIN_HANDLE_IN, \$buf, 64, \$read ) && $read;
        for my $i ( 0 .. $read - 1 ) {
            my $record = unpack_record( substr $buf, $i * RECORD_SIZE, RECORD_SIZE );
            handle( $P->parse_con_input_event( $record, $STATE ) // next );
            last if $quit;
        }
    }
}

# --- POSIX: raw mode + VT byte stream --------------------------------------
sub run_posix () {
    require Cancer::Term;
    Cancer::Term->import(qw[is_terminal make_raw restore get_size]);
    is_terminal( fileno STDIN )             or die "stdin is not a terminal\n";
    $POSIX_STATE = make_raw( fileno STDIN ) or die "make_raw failed\n";

    # Raw mode clears OPOST, so "\n" no longer produces a carriage return and
    # every rendered line overprints the previous one into unreadable mush.
    # Terminate lines with CRLF ourselves instead.
    my $nl = "\r\n";
    $POSIX_KITTY = !!( $ENV{CANCER_KITTY} // 1 );
    print "\e[?1000h\e[?1002h\e[?1003h\e[?1006h\e[?1004h";    # mouse + motion + SGR, focus

    # kitty keyboard: disambiguate | report event types | report all keys as
    # escape codes -- releases and modifier-only presses for every key,
    # matching the win32 console driver. Ignored by legacy terminals;
    # popped in END below.
    print "\e[>11u" if $POSIX_KITTY;
    if ($POSIX_KITTY) {

        # Probe: a protocol-capable terminal answers CSI ? u with its active
        # flags; every terminal (supporting or not) answers the trailing DA1.
        print "\e[?u\e[c";
        ( $KITTY_PROBE, $KITTY_DEADLINE ) = ( 1, time + 2 );
    }

    # Signals: leave through the front door so END can restore the tty. A
    # default-action death (kill -TERM, SIGHUP on window close) skips END
    # blocks and strands the terminal in raw mode with mouse reporting on --
    # exactly the state that looks like ANSI garbage dumped into your shell.
    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = $SIG{QUIT} = sub { $quit = 1 };
    my ( $last_w, $last_h ) = ( 0, 0 );
    $SIG{WINCH} = sub {
        my ( $w, $h ) = eval { get_size( fileno STDIN ) };
        return unless $w && $h;
        return if $w == $last_w && $h == $last_h;
        ( $last_w, $last_h ) = ( $w, $h );
        printf "WindowSizeEvent   %dx%d%s", $w, $h, $nl;
    };

    END {
        print "\e[<u" if $POSIX_KITTY;
        print "\e[?1003l\e[?1002l\e[?1000l\e[?1006l\e[?1004l\e[?25h";
        restore( fileno STDIN, $POSIX_STATE ) if $POSIX_STATE;
        print "\r\n"                          if $POSIX_STATE;    # land the shell prompt on a fresh line
    }
    my $banner = <<"EOT";

Cancer::Input live demo -- POSIX byte stream

  keys   : type anything (arrows, F-keys, emoji, compose)
  mouse  : click, drag, scroll wheel${ \( $POSIX_KITTY ? "  [kitty protocol ON]" : '' ) }
  focus  : switch away and back to this window
  resize : shrink/grow the window to see WindowSizeEvents
  exit   : Ctrl+Q or Ctrl+C

--------------------------------------------------------------------
EOT
    $banner =~ s/\n/$nl/g;
    print $banner;
    binmode STDIN;
    my $buf = '';
    until ($quit) {
        if ($KITTY_PROBE) {

            # Waiting on the capability probe: bound the wait so a silent
            # terminal (or one that ignores CSI ? u entirely, like WT stable
            # over ConPTY) still gets its verdict.
            my $wait = $KITTY_DEADLINE - time();
            if ( $wait <= 0 ) {
                print "kitty protocol   : no response -- legacy byte stream\r\n" unless defined $KITTY_FLAGS;    # confirmed but never sent DA1
                $KITTY_PROBE = 0;
                next;
            }
            my $rin = '';
            vec( $rin, fileno STDIN, 1 ) = 1;
            my $ready = select( $rin, undef, undef, $wait );
            next if !defined $ready && $!{EINTR};    # e.g. SIGWINCH
            next unless $ready;                      # timed out; re-check deadline above
        }
        my $got = sysread STDIN, my $chunk, 4096;
        if ( !defined $got ) {

            # Signals (e.g. WINCH) interrupt reads; retry unless fatal.
            next if $!{EINTR};
            last;
        }
        last if !$got;
        $buf .= $chunk;
        while ( length $buf && !$quit ) {

            # Like upstream's Unix reader: parse what arrived; a lone ESC
            # reports early, so incomplete sequences split across reads are
            # accepted collateral in this demo.
            my ( $used, $event ) = $P->parse_sequence($buf);
            last if !$used;
            substr( $buf, 0, $used ) = '';
            handle($event) if defined $event;
        }
    }
}
