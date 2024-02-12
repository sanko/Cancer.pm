use v5.36;
use utf8;
$|++;
#
use Data::Dump;
#
package Cancer::Log 0.5 {
    use v5.36;
    use Path::Tiny;
    sub new      ( $class, $level ) { }
    sub is_info  ($self)            { }
    sub is_debug ($self)            { }
    sub context() { }
    #
    sub error ( $self, $msg ) { }
    #
    sub warn    ( $self, $msg ) { }
    sub warning ( $self, $msg ) { }
    #
    sub info ( $self, $msg ) { }
    #
    sub errorf ( $self, $msg, @fields ) { }
    sub debugf ( $self, $msg, @fields ) { }
}

package Devel::Cancer 0.5 {
    use v5.36;

    # Devel::Trace but Cancerous; perl -d:Cancer script.pl
    our $TRACE       = 0;                                                                              # off by default
    our $FORMAT      = '>> %file%:%line%: %code%';                                                     # allow custom log line formats
    our $TIME_FORMAT = '%Y-%m-%dT%H:%M:%S' . ( $POSIX::strftime::GNU::VERSION ? ',%N' : '' ) . '%z';
    our $FH          = \*STDERR;
    use Time::HiRes qw[gettimeofday];
    eval q{use POSIX 'strftime';} unless eval q{use POSIX::strftime::GNU;};                            # POSIX is core but no nanosecond support
    use Exporter 'import';
    our @EXPORT_OK = qw[$TRACE trace $FH];                                                             # symbols to export on request

    # %package% - Print current package
    # %file% - Print path
    # %line% - Print current line number
    # %date% - Print date
    # %date:[%D, %Y]% - Accept strftime format
    # %code% - Print current line of code
    sub DB::DB {
        $TRACE || return;
        my ( $package, $filename, $line ) = caller;
        my $code = \@{"::_<$filename"};
        my ( $t, $nsec ) = gettimeofday;
        my @localtime = localtime $t;
        $localtime[0] += $nsec / 10e5;
        my %args = ( package => $package, file => $filename, line => $line, date => strftime( $TIME_FORMAT, @localtime ), code => $code->[$line] );
        print $FH $FORMAT =~ s[
%
        (?:(?'var'date)\:\[(?'format'.+?)\]|
        (?'var'package|file|line|date|code))
%]
[$+{var} eq 'date' && defined $+{format} ? strftime($+{format}, @localtime) : $args{$+{var}}]gerx;
    }
    sub trace  ($switch) { $TRACE  = !!$switch }
    sub format ($format) { $FORMAT = $format }
    sub handle ($handle) { $FH     = $handle }
}

package Cancer::ColorSystem {
    use Scalar::Util qw[dualvar];
    use constant { EIGHT_BIT => dualvar( 0, 'EIGHT_BIT' ), STANDARD => dualvar( 1, 'STANDARD' ), TRUECOLOR => dualvar( 2, 'TRUECOLOR' ) };
}
#
package Cancer 0.01 {
    use v5.36;
    my $Renderer = { LIVE => 1 };
    my $TermColors
        = { kitty => Cancer::ColorSystem::EIGHT_BIT(), '256color' => Cancer::ColorSystem::EIGHT_BIT(), '16color' => Cancer::ColorSystem::STANDARD() };

    sub ControlCode ( $type, $alpha = undef, $beta = undef ) {
        ...;
    }

    sub new ( $class, %args ) {
        $args{fh_out} //= \*STDOUT;
        $args{fh_in}  //= \*STDIN;
        if ( $args{terminal_type} // '' eq 'DUMB' ) {
            $args{width}  //= 80;
            $args{height} //= 25;
        }
        elsif ( !defined $args{width} || !defined $args{height} ) {
            my ( $w, $h ) = _get_terminal_dimensions( $args{fh_out} );
            $args{width}  //= $w;
            $args{height} //= $h;
        }
        #
        bless {
            fh_out         => $args{fh_out},
            fh_in          => $args{fh_in},
            size           => [ $args{width}, $args{height} ],
            legacy_windows => !1,                                # TODO: detect old skool cmd
            min_width      => $args{min_width}  // $args{width},
            min_height     => $args{min_height} // $args{height},
            max_width      => $args{max_width}  // $args{width},
            max_height     => $args{max_height} // $args{height},
            width          => $args{width},
            height         => $args{height},
            is_terminal    => $args{is_terminal} // !!-t $args{stdin},
            encoding       => $args{encoding}    // 'utf-8',
            justify        => $args{justify}     // undef,
            overlow        => $args{overlow}     // undef,
            no_wrap        => $args{no_wrap}     // !1,
            highlight      => $args{highlight}   // undef,
            markup         => $args{markup}      // undef,
            emoji_variant  => $args{emoji_variant} //= 'emoji',
            x              => 0,
            y              => 0,
            cache_out      => '',
            cache_in       => '',
            renderer       => $Renderer->{Live}
        }, $class;
    }
    #
    sub ascii_only ($self) {
        return $self->{encoding} !~ m[^utf]i;
    }

    sub height ( $self, $height = () ) {
        $self->{height}     = $height if defined $height;
        $self->{max_height} = $height if $height > $self->{max_height};
        $self->{height};
    }

    sub width ( $self, $width = () ) {
        $self->{width}     = $width                      if defined $width;
        $self->{max_width} = $self->{min_width} = $width if $width > $self->{max_width};
        $self->{width};
    }

    sub size ( $self, $width = (), $height = () ) {
        if ( defined $width && defined $height ) {    # only update if both are defined
            $self->width($width);
            $self->height($height);
        }
        ( $self->{width}, $self->{height} );
    }

    # Output
    sub newline ( $self, $count = 1 ) {
        Cancer::Segment->new( "\n" x $count );
    }

    sub bell ($self) {
        Cancer::Segment->new( undef, undef, [ Cancer::Segment::BELL() ] );
    }

    sub move_to ( $self, $x, $y ) {
        Cancer::Segment->new( undef, undef, [ Cancer::Segment::CURSOR_MOVE_TO(), $x, $y ] );
    }

    # Render system
    sub render ( $self, $lines, $x = (), $y = () ) {
        if ( defined $x && defined $y ) {
            $self->{x} = $x;
            $self->{y} = $y;
            unshift @$lines, $self->move_to( $x, $y );
        }
        else {
            $x = $self->{x};
            $y = $self->{y};
        }
        Cancer::Renderer::Live::render($lines);
    }

    sub write ( $self, $data //= () ) {
        $self->{cache_out} .= $data if defined $data;
        return                      if !length $self->{cache_out};

        #~ if ( !$select_o->can_write() ) {
        #~ $cache_o .= $data;
        #~ return;
        #~ }
        my $wrote = syswrite $self->{fh_out}, $self->{cache_out}, length $self->{cache_out};
        substr $self->{cache_out}, 0, $wrote, '';
        $wrote;
    }

    sub read ( $self, $length //= 1024 ) {

        #~ $select_i->can_read() || return;
        sysread $self->{fh_in}, my ($ret), $length;
        return $ret;
    }
    #
    sub _TIOCGWINSZ () {    # See Perl::osnames
        return 0x800c     if $^O =~ qr/\A(?:beos)\z/;
        return 0x40087468 if $^O =~ qr/\A(?:MacOS|iphoneos|bitrig|dragonfly|(free|net|open)bsd|bsdos)\z/;
        return 0x5468     if $^O =~ qr/\A(?:solaris|sunos)\z/;
        return 0x5413       # Linux and android
    }

    sub _get_terminal_dimensions ($fh) {
        my $winsize = "\0" x 8;
        ( ( ioctl( $fh, _TIOCGWINSZ(), $winsize ) ) ? ( unpack 'S4', $winsize ) : ( map { $_ * 0 } ( 1 .. 4 ) ) );
    }
}

package Cancer::Renderer::Live 0.5 {

    sub render ($lines) {
        map { $_->render } @$lines;
    }
}

package Cancer::Segment 0.5 {
    use v5.36;
    use Scalar::Util qw[dualvar];
    use constant {
        BELL                  => dualvar( 1,  'BELL' ),
        CARRIAGE_RETURN       => dualvar( 2,  'CARRIAGE_RETURN' ),
        HOME                  => dualvar( 3,  'HOME' ),
        CLEAR                 => dualvar( 4,  'CLEAR' ),
        SHOW_CURSOR           => dualvar( 5,  'SHOW_CURSOR' ),
        HIDE_CURSOR           => dualvar( 6,  'HIDE_CURSOR' ),
        ENABLE_ALT_SCREEN     => dualvar( 7,  'ENABLE_ALT_SCREEN' ),
        DISABLE_ALT_SCREEN    => dualvar( 8,  'DISABLE_ALT_SCREEN' ),
        CURSOR_UP             => dualvar( 9,  'CURSOR_UP' ),
        CURSOR_DOWN           => dualvar( 10, 'CURSOR_DOWN' ),
        CURSOR_FORWARD        => dualvar( 11, 'CURSOR_FORWARD' ),
        CURSOR_BACKWARD       => dualvar( 12, 'CURSOR_BACKWARD' ),
        CURSOR_MOVE_TO_COLUMN => dualvar( 13, 'CURSOR_MOVE_TO_COLUMN' ),
        CURSOR_MOVE_TO        => dualvar( 14, 'CURSOR_MOVE_TO' ),
        ERASE_IN_LINE         => dualvar( 15, 'ERASE_IN_LINE' ),
        SET_WINDOW_TITLE      => dualvar( 16, 'SET_WINDOW_TITLE' ),
        OUTPUT                => dualvar( 17, 'OUTPUT' )
    };

    sub new ( $class, $text, $style = Cancer::Style->new(), $control = [OUTPUT] ) {
        bless { text => $text, style => $style, control => $control }, $class;
    }

    sub render ($self) {
        CORE::state $c //= {
            BELL => sub ($s) {
                Cancer::Terminal::BEL();
            },
            CARRIAGE_RETURN => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            HOME => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CLEAR => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            SHOW_CURSOR => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            HIDE_CURSOR => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            ENABLE_ALT_SCREEN => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            DISABLE_ALT_SCREEN => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_UP => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_DOWN => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_FORWARD => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_BACKWARD => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_MOVE_TO_COLUMN => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            CURSOR_MOVE_TO => sub ($s) {
                Cancer::Terminal::CUP( $self->{control}->[ 1, 2 ] );
            },
            ERASE_IN_LINE => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            SET_WINDOW_TITLE => sub ($s) {
                use Data::Dump;
                ddx $s;
                ...;
            },
            OUTPUT => sub ($s) {
                return $s->{style}->open() . $s->{text} . $s->{style}->close();
            },
        };
        return $c->{ $self->{control}[0] }->($self);
    }
}

package Cancer::Style 0.5 {
    use v5.36;

    # color     Color
    # bgcolor   Color
    # bold      bool
    # italic    bool
    # blink     bool
    # blink2    bool
    sub new ( $class, %args ) {
        bless \%args, $class;
    }

    sub open ($self) {
        my $ret = '';
        $ret .= Cancer::Terminal::bold()                          if $self->{bold};
        $ret .= Cancer::Terminal::italic()                        if $self->{italic};
        $ret .= Cancer::Terminal::slow_blink()                    if $self->{blink};
        $ret .= Cancer::Terminal::fast_blink()                    if $self->{blink2};
        $ret .= Cancer::Terminal::bg_rgb( $self->{bgcolor}->rgb ) if $self->{bgcolor} && $self->{bgcolor}->{type} == Cancer::ColorSystem::TRUECOLOR();
        $ret .= Cancer::Terminal::fg_rgb( $self->{color}->rgb )   if $self->{color}   && $self->{color}->{type} == Cancer::ColorSystem::TRUECOLOR();
        $ret;
    }

    sub close ($self) {
        my $ret = '';
        $ret .= Cancer::Terminal::bg_reset()        if $self->{bgcolor};
        $ret .= Cancer::Terminal::fg_reset()        if $self->{color};
        $ret .= Cancer::Terminal::disable_blink()   if $self->{blink2} || $self->{blink};
        $ret .= Cancer::Terminal::normal_emphasis() if $self->{italic};
        $ret .= Cancer::Terminal::normal_weight()   if $self->{bold};
        $ret;
    }
}

#~ sub reset ()            { SGR 0 }
#~ sub bold()              { SGR 1 }
#~ sub dim()               { SGR 2 }
#~ sub italic()            { SGR 3 }
#~ sub underline()         { SGR 4 }
#~ sub slow_blink()        { SGR 5 }
#~ sub fast_blink()        { SGR 6 }
#~ sub invert ()           { SGR 7 }
#~ sub hide()              { SGR 8 }
#~ sub strike()            { SGR 9 }
#~ sub default_font()      { SGR 10 }
#~ sub alternate_font ($n) { Carp::confess 'Alternate font should be between 1 and 9' unless 1 <= $n <= 9; SGR 10 + $n }
#~ sub gothic ()           { SGR 20 }
#~ sub double_underline()  { SGR 21 }
#~ sub normal_weight()     { SGR 22 }                                                                                      # disables bold and dim
#~ sub normal_emphasis()   { SGR 23 }                                                                                      # disables italic
#~ sub disable_underline() { SGR 24 }    # disables underline and double_underline
#~ sub disable_blink()     { SGR 25 }    # disables slow and fast blink
#~ sub disable_invert()    { SGR 27 }
#~ sub disable_hide()      { SGR 28 }
#~ sub disable_strike()    { SGR 29 }
package Cancer::Color {
    use v5.36;

    sub new ( $class, $color ) {

        #~ $color = Cancer::ColorTriplet->new( hex $+{r} . $+{r}, hex $+{g} . $+{g}, hex $+{b} . $+{b} )
        #~ if $color =~ m/^#(?'r'[[:xdigit:]])(?'g'[[:xdigit:]])(?'b'[[:xdigit:]])$/;
        bless {
            raw => $color, (
                $color =~ m/^#?(?'r'[[:xdigit:]]{2})(?'g'[[:xdigit:]]{2})(?'b'[[:xdigit:]]{2})$/ ?
                    ( type => Cancer::ColorSystem::TRUECOLOR(), triplet => Cancer::ColorTriplet->new( hex $+{r}, hex $+{g}, hex $+{b} ) ) : ()
            ), (
                $color =~ m/^#?(?'r'[[:xdigit:]])(?'g'[[:xdigit:]])(?'b'[[:xdigit:]])$/ ? (
                    type    => Cancer::ColorSystem::TRUECOLOR(),
                    triplet => Cancer::ColorTriplet->new( hex $+{r} . $+{r}, hex $+{g} . $+{g}, hex $+{b} . $+{b} )
                ) : ()
            )
        }, $class;
    }

    sub rgb ($self) {
        ( $self->{triplet}{red}, $self->{triplet}{green}, $self->{triplet}{blue} )
    }
}

package Cancer::ColorTriplet {
    use v5.36;

    sub new ( $class, $red, $green, $blue ) {
        bless { red => $red, green => $green, blue => $blue }, $class;
    }
}

package Cancer::Terminal {
    use v5.36;
    use Carp;

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
    sub CUU ( $n = 1 )         { CSI . $n . 'A' }
    sub CUD ( $n = 1 )         { CSI . $n . 'B' }
    sub CUF ( $n = 1 )         { CSI . $n . 'C' }
    sub CUB ( $n = 1 )         { CSI . $n . 'D' }
    sub CNL ( $n = 1 )         { CSI . $n . 'E' }
    sub CPL ( $n = 1 )         { CSI . $n . 'F' }
    sub CHA ( $n = 1 )         { CSI . $n . 'G' }
    sub CUP ( $n = 1, $m = 1 ) { CSI . $n . ';' . $m . 'H' }
    sub ED  ( $n = 1 )         { CSI . $n . 'J' }
    sub EL  ( $n = 1 )         { CSI . $n . 'K' }
    sub SU  ( $n = 1 )         { CSI . $n . 'S' }
    sub SD  ( $n = 1 )         { CSI . $n . 'T' }
    sub HVP ( $n = 1, $m = 1 ) { CSI . $n . 'f' }
    sub SGR ( $n = 1 )         { CSI . $n . 'm' }
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
    sub fg_indexed ($c)                          { Carp::confess 'foreground color should be between 0 and 7' unless 0 <= $c <= 7; SGR $c + 30 }
    sub fg_8bit    ($c)                          { SGR 38 . ';5;' . $c }
    sub fg_rgb     ( $r = '', $g = '', $b = '' ) { SGR 38 . ';2;' . $r . ';' . $g . ';' . $b }
    sub fg_reset() { SGR 39 }
    sub bg_indexed ($c)                          { Carp::confess 'background color should be between 0 and 7' unless 0 <= $c <= 7; SGR $c + 40 }
    sub bg_8bit    ($c)                          { SGR 48 . ';5;' . $c }
    sub bg_rgb     ( $r = '', $g = '', $b = '' ) { SGR 48 . ';2;' . $r . ';' . $g . ';' . $b }
    sub bg_reset() { SGR 49 }

    # Underline color. VTE, Kitty, mintty, and iTerm2
    sub ul_8bit ($c)           { SGR 58 . '5;' . $c }
    sub ul_rgb  ( $r, $g, $b ) { SGR 58 . '2;' . $r . ';' . $g . ';' . $b }
    sub ul_reset () { SGR 59 }

    # Operating System Command (OSC) sequences
    sub osc_title ($text) { OSC . '0;' . $text . BEL }    # xterm

    #~ https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
    #~ https://github.com/Alhadis/OSC8-Adoption
    sub osc_hyperlink ( $link, $text = $link ) {
        ESC . OSC . qq'8;;' . $link . ST . $text . ESC . OSC . '8;;' . ST;
    }
    #
    sub blank_screen() { CSI . '2J' }
    sub blank_line ()  { CSI . '2K' }
    #
    sub cursor_position ( $x, $y ) {
        ESC . "[" . ( $y + 1 ) . ';' . ( $x + 1 ) . 'H';
    }

    # Color systems
    sub color_default_fg () { ESC . "[39m" }
    sub color_default_bg () { ESC . "[49m" }

    # printf "\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\n"
    sub color_true_fg    ( $r, $g, $b ) { sprintf ESC . "[38;2;%d;100;0m", $b, $r, $g }
    sub color_true_bg    ( $r, $g, $b ) { sprintf ESC . "[48;2;%d;%d;%dm", $b, $r, $g; }
    sub color_indexed_bg ($color)       { ESC . "[48;5;" . $color . 'm'; }
    sub color_indexed_fg ($color)       { ESC . "[38;5;" . $color . 'm'; }
    #
    sub cursor_up   ($count) { CUU($count) }
    sub cursor_down ($count) { CUD($count) }
    sub set_title   ($text)  { osc_title($text) }
    #
    #
    #~ sub clear_traits()        { $self->write("\033[22;23;24;25;27;28;29m") }
    #~ sub set_traits ($_traits) { $traits = $_traits; $self->write("\033[22;23;24;25;27;28;29${traits}m") }
    #
    sub write_at ( $x, $y, $string ) {
        sprintf CSI . '%d;%dH%s', $y, $x, $string;
    }
}
1;
__END__
╭────────────────────────── <class 'list'> ───────────────────────────╮
│ Built-in mutable sequence.                                          │
│                                                                     │
│ ╭─────────────────────────────────────────────────────────────────╮ │
│ │ [                                                               │ │
│ │ │   Segment(                                                    │ │
│ │ │   │   "'",                                                    │ │
│ │ │   │   Style(                                                  │ │
│ │ │   │   │   color=Color(                                        │ │
│ │ │   │   │   │   'green',                                        │ │
│ │ │   │   │   │   ColorType.STANDARD,                             │ │
│ │ │   │   │   │   number=2                                        │ │
│ │ │   │   │   ),                                                  │ │
│ │ │   │   │   bold=False,                                         │ │
│ │ │   │   │   italic=False                                        │ │
│ │ │   │   )                                                       │ │
│ │ │   ),                                                          │ │
│ │ │   Segment(                                                    │ │
│ │ │   │   'foo',                                                  │ │
│ │ │   │   Style(                                                  │ │
│ │ │   │   │   color=Color(                                        │ │
│ │ │   │   │   │   'green',                                        │ │
│ │ │   │   │   │   ColorType.STANDARD,                             │ │
│ │ │   │   │   │   number=2                                        │ │
│ │ │   │   │   ),                                                  │ │
│ │ │   │   │   bold=True,                                          │ │
│ │ │   │   │   italic=False                                        │ │
│ │ │   │   )                                                       │ │
│ │ │   ),                                                          │ │
│ │ │   Segment(                                                    │ │
│ │ │   │   "'",                                                    │ │
│ │ │   │   Style(                                                  │ │
│ │ │   │   │   color=Color(                                        │ │
│ │ │   │   │   │   'green',                                        │ │
│ │ │   │   │   │   ColorType.STANDARD,                             │ │
│ │ │   │   │   │   number=2                                        │ │
│ │ │   │   │   ),                                                  │ │
│ │ │   │   │   bold=False,                                         │ │
│ │ │   │   │   italic=False                                        │ │
│ │ │   │   )                                                       │ │
│ │ │   ),                                                          │ │
│ │ │   Segment('\n')                                               │ │
│ │ ]                                                               │ │
│ ╰─────────────────────────────────────────────────────────────────╯ │
│                                                                     │
│ 37 attribute(s) not shown. Run inspect(inspect) for options.        │
╰─────────────────────────────────────────────────────────────────────╯


=encoding utf-8

=head1 NAME

Cancer - I'm afraid it's terminal...'

=head1 SYNOPSIS

    use Cancer;

=head1 DESCRIPTION

Cancer is a text-based UI library inspired by L<termbox-go|https://github.com/nsf/termbox-go>. Use it to create
L<TUI|https://en.wikipedia.org/wiki/Text-based_user_interface> in pure perl.

=head1 Author

Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2020-2023 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

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

