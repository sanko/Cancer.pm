#~ Windows: https://conemu.github.io/en/wsl.html
#~ https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Controls-beginning-with-ESC
use v5.38;
use experimental 'class';
use IO::Select;
use Carp qw[];
my $Win32 = $^O eq 'MSWin32' ? 1 : !1;
my $TERM  = $ENV{TERM} // '';
my $urxvt = $TERM =~ m[rxvt-unicode];

class Cancer {
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    #
    field $mouse : param      //= 1;    # modes (0..3)
    field $winch : param      //= ();
    field $alt_buffer : param //= 1;
    field $cursor : param     //= 0;
    #
    field $tty_i;
    field $tty_o;
    field $select_i = IO::Select->new();
    field $select_o = IO::Select->new();
    field $cache_i  = '';
    field $cache_o  = '';
    field $cflag;
    field $iflag;
    field $oflag;
    field $lflag;
    field $mode;
    field $attr;
    field $cc;
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
            $tty_i = \*STDIN;
            $tty_o = \*STDOUT;
        }
        Carp::carp 'Not a terminal.' unless -t $tty_i;
        {
            my $fileno = fileno $tty_i;
            use POSIX qw[:termios_h];
            my $raw = POSIX::Termios->new();

            # backup
            my $_cflag = $cflag = $raw->getcflag;
            my $_iflag = $iflag = $raw->getiflag;
            my $_oflag = $oflag = $raw->getoflag;
            my $_lflag = $lflag = $raw->getlflag;
            $attr = $raw->getattr($fileno);
            $cc   = [ map { $raw->getcc($_) } 1 .. 11 ];

            # https://man7.org/linux/man-pages/man3/termios.3.html
            $_iflag = $_iflag & ~( IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON );
            $_oflag = $_oflag & ~OPOST;                                        # Disables post-processing output. Like turning \n into \r\n
            $_lflag = $_lflag & ~( ECHO | ECHONL | ICANON | ISIG | IEXTEN );
            $_cflag = $_cflag & ~(PARENB);
            $_cflag |= CS8;
            $raw->setiflag($_iflag);
            $raw->setoflag($_oflag);
            $raw->setlflag($_lflag);
            $raw->setcflag($_cflag);

            #~ # This is setup for blocking reads.  In the past we attempted to
            #~ # use non-blocking reads, but now a separate input loop and timer
            #~ # copes with the problems we had on some systems (BSD/Darwin)
            #~ # where close hung forever.
            $raw->setcc( VMIN,  1 );
            $raw->setcc( VTIME, 0 );
            $raw->setattr( $fileno, TCSANOW );

            #~ # Debug
            #~ my $raw = POSIX::Termios->new();
            #~ use Data::Dump;
            #~ $raw->getattr($fileno);
            #~ warn $raw->getcflag;
            #~ warn $raw->getiflag;
            #~ warn $raw->getispeed;
            #~ warn $raw->getlflag;
            #~ warn $raw->getoflag;
            #~ warn $raw->getospeed;
        }
        if ( defined $winch ) {
            my $hold = $SIG{WINCH};
            $SIG{WINCH} = defined $hold ? sub { $winch->($self); $hold->(); } : sub { $winch->($self) };
        }
        $select_i->add($tty_i);
        $select_o->add($tty_o);
        $self->set_mouse($mouse);
        $self->set_cursor($cursor);
        $self->write( $alt_buffer ? ALT_BUFF_ON() : ALT_BUFF_OFF() );
    }

    method DESTROY ( $global //= 0 ) {
        my $fileno = fileno $tty_i;

        # Restore original flags
        my $raw = POSIX::Termios->new();
        $raw->setcflag($cflag);
        $raw->setlflag($lflag);
        $raw->setoflag($oflag);
        $raw->setiflag($iflag);
        $raw->setcc( $_, $cc->[0] ) for 0 .. scalar @$cc;
        $raw->setattr( $fileno, $attr );
        #
        $self->set_mouse(0);
        $self->set_cursor(1);
        $self->blank_screen;

        #~ $SIG{WINCH} = $sig_winch       if defined $sig_winch;    # Restore original winch
        $self->write( ALT_BUFF_OFF() ) if $alt_buffer;
    }

    method write ( $data //= () ) {
        $cache_o .= $data if defined $data;
        return            if !length $cache_o;
        if ( !$select_o->can_write() ) {
            $cache_o .= $data;
            return;
        }
        my $wrote = syswrite $tty_o, $cache_o, length $cache_o;
        substr $cache_o, 0, $wrote, '';
        $wrote;
    }

    method read ( $length //= 1024 ) {
        $select_i->can_read() || return;
        sysread $tty_i, my ($ret), $length;
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
    sub SCP() { CSI . 's' }       # Save current cursor position
    sub RCP() { CSI . 'u' }       # Restore cursor position

    #
    #
    sub FOCUS_ON()     { CSI . '?1004h' }    # Enable focus reporting (CSI . 'I' is in, CSI . 'O' is out)
    sub FOCUS_OFF()    { CSI . '?1004l' }    # Disable focus reporting
    sub ALT_BUFF_ON()  { CSI . '?1049h' }    # Enable alt screen buffer [xterm]
    sub ALT_BUFF_OFF() { CSI . '?1049l' }    # Disalbe alt screen buffer [xterm]

    #
    sub CURSOR () {25}
    #
    sub MOUSE_X10()              {9}
    sub MOUSE_VT200()            {1000}
    sub MOUSE_VT200_HIGHLIGHT()  {1001}
    sub MOUSE_BTN_EVENT()        {1002}
    sub MOUSE_ANY_EVENT()        {1003}
    sub MOUSE_FOCUS_EVENT()      {1004}
    sub MOUSE_ALTERNATE_SCROLL() {1007}
    sub MOUSE_EXT_MODE()         {1005}
    sub MOUSE_SGR_EXT_MODE()     {1006}
    sub MOUSE_URXVT_EXT_MODE()   {1015}
    sub MOUSE_PIXEL_POSITION()   {1016}

    # https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
    sub BRACKET_PASTE_ON()  { CSI . '?2004h' }    # Enable bracketed paste mode
    sub BRACKET_PASTE_OFF() { CSI . '?2004l' }    # Disable bracketed paste mode

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
    sub fg_8bit    ($c)                                { SGR 38 . ';5;' . $c }
    sub fg_rgb     ( $r //= '', $g //= '', $b //= '' ) { SGR 38 . ';2;' . $r . ';' . $g . ';' . $b }
    sub fg_reset() { SGR 39 }
    sub bg_indexed ($c)                                { Carp::confess 'background color should be between 0 and 7' unless 0 <= $c <= 7; SGR $c + 40 }
    sub bg_8bit    ($c)                                { SGR 48 . ';5;' . $c }
    sub bg_rgb     ( $r //= '', $g //= '', $b //= '' ) { SGR 48 . ';2;' . $r . ';' . $g . ';' . $b }
    sub bg_reset() { SGR 49 }

    # Underline color. VTE, Kitty, mintty, and iTerm2
    sub ul_8bit ($c)           { SGR 58 . '5;' . $c }
    sub ul_rgb  ( $r, $g, $b ) { SGR 58 . '2;' . $r . ';' . $g . ';' . $b }
    sub ul_reset () { SGR 59 }

    # Operating System Command (OSC) sequences
    sub osc_title ($text) { OSC . '0;' . $text . BEL }    # xterm

    #~ https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
    #~ https://github.com/Alhadis/OSC8-Adoption
    sub osc_hyperlink ( $link, $text //= $link ) {
        ESC . OSC . qq'8;;' . $link . ST . $text . ESC . OSC . '8;;' . ST;
    }
    #
    method blank_screen() { $self->write( CSI . '2J' ) }
    method blank_line ()  { $self->write( CSI . '2K' ) }
    #
    method cursor_position ( $x, $y ) {
        $self->write( ESC . "[" . ( $y + 1 ) . ';' . ( $x + 1 ) . 'H' );
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
    method set_title   ($text)  { $self->write( osc_title($text) ) }
    #
    #
    #~ method clear_traits()        { $self->write("\033[22;23;24;25;27;28;29m") }
    #~ method set_traits ($_traits) { $traits = $_traits; $self->write("\033[22;23;24;25;27;28;29${traits}m") }
    #
    method write_at ( $x, $y, $string ) {
        $self->write( sprintf CSI . '%d;%dH%s', $y, $x, $string );
    }

    # Platform utils
    sub TIOCGWINSZ () {    # See Perl::osnames
        return 0x800c     if $^O =~ qr/\A(?:beos)\z/;
        return 0x40087468 if $^O =~ qr/\A(?:MacOS|iphoneos|bitrig|dragonfly|(free|net|open)bsd|bsdos)\z/;
        return 0x5468     if $^O =~ qr/\A(?:solaris|sunos)\z/;
        return 0x5413      # Linux and android
    }

    method terminal_size () {
        my $winsize = "\0" x 8;
        ( ( ioctl( $tty_o, TIOCGWINSZ(), $winsize ) ) ? ( unpack 'S4', $winsize ) : ( map { $_ * 0 } ( 1 .. 4 ) ) );
    }

    method terminal_width() {
        my ( $rows, $cols, $xpix, $ypix ) = $self->terminal_size;
        return $cols;
    }

    method terminal_height() {
        my ( $rows, $cols, $xpix, $ypix ) = $self->terminal_size;
        return $rows;
    }

    # 0: off
    # 1: basic
    # 2: drag
    # 3: move
    method set_mouse ($mode) {
        $mouse = $mode;
        CORE::state $switch //= {
            0 => sub {
                CSI . '?' . ( join ';', MOUSE_VT200, MOUSE_BTN_EVENT, MOUSE_ANY_EVENT, $urxvt ? MOUSE_URXVT_EXT_MODE : MOUSE_URXVT_EXT_MODE ) . 'l';
            },
            1 => sub {
                CSI . '?' .     ( join ';', MOUSE_BTN_EVENT, MOUSE_ANY_EVENT ) . 'l' .                                       # off
                    CSI . '?' . ( join ';', MOUSE_VT200,     $urxvt ? MOUSE_URXVT_EXT_MODE : MOUSE_URXVT_EXT_MODE ) . 'h';
            },
            2 => sub {
                CSI . '?' .     ( join ';', MOUSE_VT200,     MOUSE_ANY_EVENT ) . 'l' .                                       # off
                    CSI . '?' . ( join ';', MOUSE_BTN_EVENT, $urxvt ? MOUSE_URXVT_EXT_MODE : MOUSE_URXVT_EXT_MODE ) . 'h';
            },
            3 => sub {
                CSI . '?' .     ( join ';', MOUSE_VT200,     MOUSE_BTN_EVENT ) . 'l' .                                       # off
                    CSI . '?' . ( join ';', MOUSE_ANY_EVENT, $urxvt ? MOUSE_URXVT_EXT_MODE : MOUSE_URXVT_EXT_MODE ) . 'h';
            }
        };
        $self->write( $switch->{$mode}->() );
    }

    method set_cursor ($mode) {
        $cursor = $mode;
        $self->write( CSI . '?' . CURSOR() . ( $mode ? 'h' : 'l' ) );
    }
    #
    method parse_event ($data) {
        CORE::state $letters //= '';
        return if !length $data;
        my $first = substr $data, 1;
        if ( $data =~ /^\e/ ) {
            $self->write_at( 0, 6, 'Escape' );
            return 0;
        }
        else {
            $self->write_at( 0, 5, CSI . '2k' );
            $self->write_at( 0, 5, $letters .= $data );

            # Must be keyboard input
        }
    }

    method one_loop () {
        use Time::HiRes qw[sleep];
        sleep 0.01;
        my $in = $self->read;
        use Data::Dump;
        $self->write_at( 0, 0, localtime() . ': ' . Data::Dump::pp($in) );
        $self->parse_event($in);
        $in // return 1;
        return $in ne 'q';
    }
    method loop() { 1 while $self->one_loop; }
    #
    sub parse_style ( $style, $on //= 1 ) {
        CORE::state $styles //= {
            default => [ Cancer::reset(), Cancer::reset() ],
            #
            bold => [ normal_weight(), bold() ],
            b    => [ normal_weight(), bold() ],
            #
            blink  => [ disable_blink(), slow_blink() ],
            blink2 => [ disable_blink(), fast_blink() ],
            #
            conceal => [ disable_hide(), hide() ],
            #
            italic => [ normal_emphasis(), italic() ],
            i      => [ normal_emphasis(), italic() ],
            #
            reverse => [ disable_invert(), invert() ],
            r       => [ disable_invert(), invert() ],
            #
            strike => [ disable_strike(), strike() ],
            s      => [ disable_strike(), strike() ],
            #
            underline => [ disable_underline(), underline() ],
            u         => [ disable_underline(), underline() ],
            #
            underline2 => [ disable_underline(), double_underline() ],
            uu         => [ disable_underline(), double_underline() ],

            # TODO:
            # frame
            # encircle
            # overline
            # o
        };
        my $ret   = '';
        my @words = split /\s+/, lc $style;
        my $mode  = 0;    # 0: normal; 1: 'on' (expect color)
        while (@words) {
            my $word = shift @words;
            if    ( $word eq 'on' ) { $mode = 1 }
            elsif ( defined $styles->{$word} ) {
                $ret .= $styles->{$word}[$on];
            }
            elsif ( $word =~ /^#(?'r'[[:xdigit:]]{2})(?'g'[[:xdigit:]]{2})(?'b'[[:xdigit:]]{2})$/ ) {
                $ret .= $mode == 1 ? bg_rgb( hex $+{r}, hex $+{g}, hex $+{b} ) : fg_rgb( hex $+{r}, hex $+{g}, hex $+{b} );
                $mode = 0;
            }
            elsif ( $word =~ /^#(?'r'[[:xdigit:]])(?'g'[[:xdigit:]])(?'b'[[:xdigit:]])$/ ) {
                $ret .= $mode == 1 ? bg_rgb( hex $+{r} . $+{r}, hex $+{g} . $+{g}, hex $+{b} . $+{b} ) :
                    fg_rgb( hex $+{r} . $+{r}, hex $+{g} . $+{g}, hex $+{b} . $+{b} );
                $mode = 0;
            }
            else { }
        }
        return $ret;
    }
    #
    sub print ( $text, %attrs ) {
        CORE::print STDOUT ( defined $attrs{style} ? parse_style( $attrs{style} ) : '' ) . $text;
    }

    sub generate {
        die "ColorCount and at least one color needed" if @_ < 2;
        my $cnt  = $_[0];
        my $col1 = $_[1];
        $_[2] ||= $_[1];
        my $col2 = $_[2];

        # expand 3 hex chars to 6
        $col1 =~ s/^([a-f0-9])([a-f0-9])([a-f0-9])$/$1$1$2$2$3$3/i;
        $col2 =~ s/^([a-f0-9])([a-f0-9])([a-f0-9])$/$1$1$2$2$3$3/i;
        my $clockwise = 0;

        #~ $clockwise++ if ( $cnt < 0 );
        $cnt = int( abs($cnt) );
        my @murtceps = ( uc "#$col1" );
        return ( wantarray() ? @murtceps                 : \@murtceps )                if $cnt <= 1;
        return ( wantarray() ? ( uc "#$col1", "#$col2" ) : [ uc "#$col1", "#$col2" ] ) if $cnt == 2;

        # The RGB values need to be on the decimal scale,
        # so we divide em by 255 enpassant.
        my ( $h1, $s1, $i1 ) = rgb2hsi( map { hex() / 255 } unpack( 'a2a2a2', $col1 ) );
        my ( $h2, $s2, $i2 ) = rgb2hsi( map { hex() / 255 } unpack( 'a2a2a2', $col2 ) );
        $cnt--;
        my $sd = ( $s2 - $s1 ) / $cnt;
        my $id = ( $i2 - $i1 ) / $cnt;
        my $hd = $h2 - $h1;
        if ( uc($col1) eq uc($col2) ) {
            $hd = ( $clockwise ? -1 : 1 ) / $cnt;
        }
        else {
            $hd = ( ( $hd < 0 ? 1 : 0 ) + $hd - $clockwise ) / $cnt;
        }
        while ( --$cnt ) {
            $s1 += $sd;
            $i1 += $id;
            $h1 += $hd;
            $h1 -= 1 if $h1 > 1;
            $h1 += 1 if $h1 < 0;
            push @murtceps, sprintf "#%02X%02X%02X", map { int( $_ * 255 + .5 ) } hsi2rgb( $h1, $s1, $i1 );
        }
        push @murtceps, uc "#$col2";
        return wantarray() ? @murtceps : \@murtceps;
    }

    sub hsi2rgb {
        my ( $h, $s, $i ) = @_;
        my ( $r, $g, $b ) = ( 0, 0, 0 );

        # degenerate cases. If !intensity it's black, if !saturation it's grey
        return ( $r, $g, $b ) if ( $i == 0 );
        return ( $i, $i, $i ) if ( $s == 0 );
        $h = $h * 2 * 3.1415926535;
        my $x = $s * cos($h);
        my $y = $s * sin($h);
        $r = $i + ( 2 / 3 * $x );
        $g = $i - ( $x / 3 ) + ( $y / 2 / 0.866025403 );
        $b = $i - ( $x / 3 ) - ( $y / 2 / 0.866025403 );

        # limit 0<=x<=1  ## YUCK but we go outta range without it.
        ( $r, $b, $g ) = map { $_ < 0 ? 0 : $_ > 1 ? 1 : $_ } ( $r, $b, $g );
        return ( $r, $g, $b );
    }

    sub rgb2hsi {
        my ( $r, $g, $b ) = @_;
        my ( $h, $s, $i ) = ( 0, 0, 0 );
        $i = ( $r + $g + $b ) / 3;
        return ( $h, $s, $i ) if $i == 0;
        my $x = $r - 0.5 * ( $g + $b );
        my $y = 0.866025403 * ( $g - $b );
        $s = ( $x**2 + $y**2 )**0.5;
        return ( $h, $s, $i ) if $s == 0;
        $h = POSIX::atan2( $y, $x ) / ( 2 * 3.1415926535 );
        return ( $h, $s, $i );
    }
}
$|++;
use Time::HiRes qw[];
print Cancer::CSI() . '?' . Cancer::CURSOR() . 'l';
my @steps = ( Cancer::generate( 60, 'FFFFFF', 'FF0000' ), Cancer::generate( 60, 'FF0000', '0000FF' ) );
for my $bg (@steps) {
    Cancer::print( "Hi\r", style => ' bold  #ccF on ' . $bg );
    Time::HiRes::sleep(0.01);
}
print "\n";
print Cancer::CSI() . '?' . Cancer::CURSOR() . 'h';
use Data::Dump;
ddx exit;

class Cancer::Widget {
    field $x : param;
    field $y : param;
    field $w : param;
    field $h : param;
    field $cancer : param;
    field $box = [
        qw[
            ┌ ─ ┐
            │   │
            └ ─ ┘
        ]
    ];

    method draw() {
        $cancer->cursor_position( $x, $y );
        $cancer->write( $box->[0] . ( $box->[1] x ( $w - 2 ) ) . $box->[2] );
        $cancer->cursor_position( $x, $y + 1 );
        for my $row ( 1 .. $h - 1 ) {
            $cancer->cursor_position( $x, $y + $row );
            $cancer->write( $box->[3] );
            $cancer->cursor_position( $x + $w - 1, $y + $row );
            $cancer->write( $box->[4] );
        }

        #~ $cancer->write("hi");
        $cancer->cursor_position( $x, $y + $h );
        $cancer->write( $box->[5] . ( $box->[6] x ( $w - 2 ) ) . $box->[7] );
    }
}

=encoding utf-8

=head1 NAME

Cancer - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;
    my $term = Cancer->new( mouse => 2 );

=head1 DESCRIPTION

Cancer is yet another text-based UI library.

It's inspired by L<TermOx|https://github.com/a-n-t-h-o-n-y/TermOx> and
L<termbox-go|https://github.com/nsf/termbox-go>. Use it to create
L<TUI|https://en.wikipedia.org/wiki/Text-based_user_interface> in pure perl.

=head1 Functions

Cancer is needlessly object oriented so you'll need the following constructor first...

=head2 C<new( [...] )>

    my $term = Cancer->new( );

Creates a new Cancer object.

Expected parameters are all optional and include:

=over

=item C<alt_buffer>

Boolean value.

If C<true>, the alternate buffer is set. This provides a blank terminal screen while the normal buffer provides the existing terminal display.

On destruction, the normal buffer is set after using the alternate buffer in order to restore the terminal screen to how it was before the application started.

See L<the xterm docs|https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-The-Alternate-Screen-Buffer>

=item C<mouse>

Integer. Default value is C<1>.

Options include:

=over

=item C<0>

Generates no mouse events. Consider this 'off' mode.

=item C<1>

Generate mouse press and release events for all buttons and the scroll wheel. This would be 'normal' terminal mouse behavior.

=item C<2>

Normal (C<1>) events, plus mouse movement events while a button is pressed. The mouse is in a 'drag' mode.

=item C<3>

Normal (C<1>) events, plus mouse movement events are generated with or without a button pressed.

=back

=item C<cursor>

Boolean value. Default value is C<false>.

If C<true>, the cursor will be displayed on screen.

=item C<winch>

=back

=head2 C<set_cursor( ... )>

    $term->set_cursor( 1 );

Set the cursor mode.

=head2 C<set_mouse( ... )>

    $term->set_mouse( 3 );

Set the mouse mode.

=head1 Author

Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2024 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the terms of The Artistic License 2.0.
See http://www.perlfoundation.org/artistic_license_2_0.  For clarification, see
http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the Creative Commons Attribution-Share Alike
3.0 License. See http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification, see
http://creativecommons.org/licenses/by-sa/3.0/us/.

=begin stopwords

termbox tty

=end stopwords

=cut

my $box;
my $cancer = Cancer->new(
    mouse      => 3,
    alt_buffer => 1,
    winch      => sub ($cancer) {
        $cancer->blank_screen;
        $box->draw if $box;
    }
);
$cancer->blank_screen;
$cancer->set_title( 'Testing! ' . scalar localtime );
$cancer->terminal_width;

#~ $cancer->write_at( 0, 5,
#~ Cancer::slow_blink() .
#~ Cancer::osc_hyperlink( 'http://google.com/', Cancer::bold . Cancer::fg_rgb( 0, 29, 33 ) . Cancer::bg_rgb( 255, 0, 0 ) . 'Hi!' ) );
#~ $cancer->write_at( 0, 6,
#~ Cancer::reset() .
#~ Cancer::osc_hyperlink( 'http://google.com/', Cancer::bold . Cancer::fg_rgb( 0, 29, 33 ) . Cancer::bg_rgb( 255, 0, 0 ) . 'Hi!' ) );
#~ $cancer->cursor_down(10);
$box = Cancer::Widget->new( x => 5, y => 10, w => 30, h => 10, cancer => $cancer );
$box->draw;
$cancer->loop;
