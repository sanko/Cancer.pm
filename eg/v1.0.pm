#~ Windows: https://conemu.github.io/en/wsl.html
use v5.38;
use experimental 'class';
use IO::Select;
use Carp qw[];
my $Win32 = $^O eq 'MSWin32' ? 1 : !1;

class Cancer {
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    #
    field $tty_i;
    field $tty_o;
    field $select_i = IO::Select->new();
    field $select_o = IO::Select->new();
    ADJUST {
        if ($Win32) {
            require IO::Handle;

            #~ $tty = IO::Handle->new_from_fd( $term, '+<' );
            #~ $tty_out = IO::Handle->new_from_fd( 'CONOUT$', '+<' );
            sysopen( $tty_i, 'CONIN$',  O_RDWR ) or die "Unable to open console input:$!";
            sysopen( $tty_o, 'CONOUT$', O_RDWR ) or die "Unable to open console output:$!";

            #                    require "sys/ioctl.ph";
            #~ my ( $rows, $cols, $xpix, $ypix ) = GetTerminalSize();
            #~ warn sprintf "(rows=%u, cols=%u, xpix=%u, ypix=%u)\n", $rows // 0, $cols // 0, $xpix, $ypix;
        }
        else {
            Carp::croak sprintf 'Cannot open terminal: %s', $! unless sysopen $tty_i, '/dev/tty', O_RDWR | O_NDELAY | O_NOCTTY;
            Carp::croak 'Not a terminal.' unless -t $tty_i;
            $tty_o = $tty_i;
        }
        $select_i->add($tty_i);
        $select_o->add($tty_o);
    }

    method write ($data) {
        $select_o->can_write() || return;
        syswrite $tty_o, $data;
    }

    method read ( $length //= 1024 ) {
        $select_i->can_read() || return;
        sysread( $tty_i, my $ret, $length );
        return $ret;
    }

    # C0 control codes
    sub BEL() { chr 0x07 }
    sub BS () { chr 0x08 }
    sub HT () { chr 0x09 }
    sub LF () { chr 0x0A }
    sub FF () { chr 0x0C }
    sub CR () { chr 0x0D }
    sub ESC() { chr 0x1B }

    # Fe Escape sequences
    sub SS2() { ESC . 'N' }
    sub SS3() { ESC . 'O' }
    sub DCS() { ESC . 'P' }
    sub CSI() { ESC . '[' }
    sub ST()  { ESC . '\\' }
    sub OSC() { ESC . ']' }
    sub SOS() { ESC . 'X' }
    sub PM()  { ESC . '^' }
    sub APC() { ESC . '_' }

    # Control Sequence Introducer (CSI)
    sub CUU ( $n //= 1 ) { CSI . $n . 'A' }
    sub CUD ( $n //= 1 ) { CSI . $n . 'B' }
    sub CUF ( $n //= 1 ) { CSI . $n . 'C' }
    sub CUB ( $n //= 1 ) { CSI . $n . 'D' }
    sub CNL ( $n //= 1 ) { CSI . $n . 'E' }
    sub CPL ( $n //= 1 ) { CSI . $n . 'F' }
    sub CHA ( $n //= 1 ) { CSI . $n . 'G' }
    sub CUP ( $n //= 1, $m //= 1 ) { CSI . $n . ';' . $m . 'H' }
    sub ED  ( $n //= 1 )           { CSI . $n . 'J' }
    sub EL  ( $n //= 1 )           { CSI . $n . 'K' }
    sub SU  ( $n //= 1 )           { CSI . $n . 'S' }
    sub SD  ( $n //= 1 )           { CSI . $n . 'T' }
    sub HVP ( $n //= 1, $m //= 1 ) { CSI . $n . 'f' }
    sub SGR ( $n //= 1 )           { CSI . $n . 'm' }
    sub DSR ( ) { CSI . '6n' }    # Look for cursor pos in CSI$n;$mR

    # Private CSI
    sub SCP()        { CSI . 's' }         # Save current cursor position
    sub RCP()        { CSI . 'u' }         # Restore cursor position
    sub CURSORON ()  { CSI . '?25h' }      # Show the cursor
    sub CURSOROFF()  { CSI . '?25l' }      # Hide the cursor
    sub FOCUSON()    { CSI . '?1004h' }    # Enable focus reporting (CSI . 'I' is in, CSI . 'O' is out)
    sub FOCUSOFF()   { CSI . '?1004l' }    # Disable focus reporting
    sub ALTBUFFON()  { CSI . '?1049h' }    # Enable alt screen buffer [xterm]
    sub ALTBUFFOFF() { CSI . '?1049l' }    # Disalbe alt screen buffer [xterm]

    # https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
    sub BRACKETPASTEON()  { CSI . '?2004h' }    # Enable bracketed paste mode
    sub BRACKETPASTEOFF() { CSI . '?2004l' }    # Disable bracketed paste mode

    # Select Graphic Rendition (SGR) params
    sub reset ()            { SGR 0 }
    sub bold()              { SGR 1 }
    sub dim()               { SGR 2 }
    sub italic()            { SGR 3 }
    sub underline()         { SGR 4 }
    sub slow_blink()        { SGR 5 }
    sub fast_blink()        { SGR 6 }
    sub invert ()           { SGR 7 }
    sub hide()              { SGR 8 }
    sub strike()            { SGR 9 }
    sub default_font()      { SGR 10 }
    sub alternate_font ($n) { Carp::confess 'Alternate font should be between 1 and 9' unless 1 <= $n <= 9; SGR 10 + $n }
    sub gothic ()           { SGR 20 }
    sub double_underline()  { SGR 21 }
    sub normal_weight()     { SGR 22 }                                                                                      # disables bold and dim
    sub normal_emphasis()   { SGR 23 }                                                                                      # disables italic
    sub disable_underline() { SGR 24 }    # disables underline and double_underline
    sub disable_blink()     { SGR 25 }    # disables slow and fast blink
    sub disable_invert()    { SGR 27 }
    sub disable_hide()      { SGR 28 }
    sub disable_strike()    { SGR 29 }
    sub fg_indexed ($c)                                { Carp::confess 'foreground color should be between 0 and 7' unless 0 <= $c <= 7; SGR $c + 30 }
    sub fg_8bit    ($c)                                { SGR 38 . '5;' . $c }
    sub fg_rgb     ( $r //= '', $g //= '', $b //= '' ) { SGR 38 . '2;' . $r . ';' . $g . ';' . $b }
    sub fg_reset() { SGR 39 }
    sub bg_indexed ($c)                                { Carp::confess 'background color should be between 0 and 7' unless 0 <= $c <= 7; SGR $c + 40 }
    sub bg_8bit    ($c)                                { SGR 48 . '5;' . $c }
    sub bg_rgb     ( $r //= '', $g //= '', $b //= '' ) { SGR 48 . '2;' . $r . ';' . $g . ';' . $b }
    sub bg_reset() { SGR 49 }

    # Underline color. VTE, Kitty, mintty, and iTerm2
    sub ul_8bit ($c)           { SGR 58 . '5;' . $c }
    sub ul_rgb  ( $r, $g, $b ) { SGR 58 . '2;' . $r . ';' . $g . ';' . $b }
    sub ul_reset () { SGR 59 }

    # indexed colors:
    # 0 Black
    # 1 Red
    # 2 Green
    # 3 Yellow
    # 4 Blue
    # 5 Magenta
    # 6 Cyan
    # 7 White
    #
    method blank_screen() { $self->write( CSI . "?2J" ) }
    method blank_line ()  { $self->write( CSI . "[2K" ) }
    #
    method cursor_position ( $x, $y ) {
        ESC . "[" . ( $y + 1 ) . ';' . ( $x + 1 ) . 'H';
    }

    # Color systems
    method color_default_fg () { ESC . "[39m" }
    method color_default_bg () { ESC . "[49m" }

    # printf "\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\n"
    method color_true_fg    ( $r, $g, $b ) { sprintf ESC . "[38;2;%d;100;0m", $b, $r, $g }
    method color_true_bg    ( $r, $g, $b ) { sprintf ESC . "[48;2;%d;%d;%dm", $b, $r, $g; }
    method color_indexed_bg ($color)       { ESC . "[48;5;" . $color . 'm'; }
    method color_indexed_fg ($color)       { ESC . "[38;5;" . $color . 'm'; }
    #
    method cursor_up   ($count) { $self->write( CUU($count) ) }
    method cursor_down ($count) { $self->write( CUD($count) ) }
    #
    #
    #~ method clear_traits()        { $self->write("\033[22;23;24;25;27;28;29m") }
    #~ method set_traits ($_traits) { $traits = $_traits; $self->write("\033[22;23;24;25;27;28;29${traits}m") }
    #
    method write_at ( $x, $y, $string ) {
        $self->write( sprintf ESC . "[%d;%dH%s", $y, $x, $string );
    }
}
my $cancer = Cancer->new();
$cancer->blank_screen;
{
    $cancer->write_at( 1, 1, 'System colors:' );
    for my $row ( 0 .. 1 ) {
        for my $i ( 0 .. 7 ) {
            $cancer->write_at(
                16 + ( $row * 2 ),
                $i,
                $cancer->color_indexed_fg( $i + ( 7 * !$row ) ) . $cancer->color_indexed_bg( $i + ( 7 * $row ) ) . sprintf '%2d',
                $i + ( 7 * $row )
            );
        }
    }
}
$cancer->cursor_down(10);
exit;
