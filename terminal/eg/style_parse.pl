use v5.36;
use utf8;
$|++;
#
use Data::Dump;
#
package Cancer {
    my $ControlType = {
        BELL                  => 1,
        CARRIAGE_RETURN       => 2,
        HOME                  => 3,
        CLEAR                 => 4,
        SHOW_CURSOR           => 5,
        HIDE_CURSOR           => 6,
        ENABLE_ALT_SCREEN     => 7,
        DISABLE_ALT_SCREEN    => 8,
        CURSOR_UP             => 9,
        CURSOR_DOWN           => 10,
        CURSOR_FORWARD        => 11,
        CURSOR_BACKWARD       => 12,
        CURSOR_MOVE_TO_COLUMN => 13,
        CURSOR_MOVE_TO        => 14,
        ERASE_IN_LINE         => 15,
        SET_WINDOW_TITLE      => 16
    };

    sub ControlCode ( $type, $alpha = undef, $beta = undef ) {
        ...;
    }
}

package Cancer::Segment {

    sub new ( $class, $text, $style ||= Cancer::Style->new(), $control = undef ) {
        bless { text => $text, style => $style, control => $control }, $class;
    }

    sub render ($self) {
        return $self->{style}->open() . $self->{text} . $self->{style}->close();
    }
}

package Cancer::Style {

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
        $ret .= Cancer::Terminal::bold()       if $self->{bold};
        $ret .= Cancer::Terminal::italic()     if $self->{italic};
        $ret .= Cancer::Terminal::slow_blink() if $self->{blink};
        $ret .= Cancer::Terminal::fast_blink() if $self->{blink2};
        $ret;
    }

    sub close ($self) {
        my $ret = '';
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
    sub new ($class) { bless {}, $class }
}

package Cancer::Terminal {
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
#
my $list = [
    Cancer::Segment->new( 'hi', Cancer::Style->new( bold   => 1 ) ), Cancer::Segment->new(' '),
    Cancer::Segment->new( 'hi', Cancer::Style->new( italic => 1 ) ), Cancer::Segment->new("\n")
];
ddx $list;
print join '', map { $_->render } @$list;
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
