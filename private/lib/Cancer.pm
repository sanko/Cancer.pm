use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../lib';
#
class Cancer {
    field $_color_system : param

    #~ {'_color_system': ColorSystem.WINDOWS,
    #~ '_emoji': True,
    #~ '_emoji_variant': None,
    #~ '_file': <_io.StringIO object at 0x00000255A3AAB880>,
    #~ '_force_terminal': True,
    #~ '_height': None,
    #~ '_highlight': True,
    #~ '_is_alt_screen': False,
    #~ '_live': None,
    #~ '_lock': <unlocked _thread.RLock object owner=0 count=0 at 0x00000255A3CBBC40>,
    #~ '_log_render': <rich._log_render.LogRender object at 0x00000255A3CDC440>,
    #~ '_markup': True,
    #~ '_record_buffer': [],
    #~ '_record_buffer_lock': <unlocked _thread.RLock object owner=0 count=0 at 0x00000255A2FBEC80>,
    #~ '_render_hooks': [],
    #~ '_thread_locals': ConsoleThreadLocals(theme_stack=<rich.theme.ThemeStack object at 0x00000255A3CDCAD0>,
    #~ buffer=[],
    #~ buffer_index=0),
    #~ '_width': None,
    #~ 'get_datetime': <built-in method now of type object at 0x00007FFF2DDCF270>,
    #~ 'get_time': <built-in function monotonic>,
    #~ 'highlighter': <rich.highlighter.ReprHighlighter object at 0x00000255A34FAE40>,
    #~ 'is_interactive': True,
    #~ 'is_jupyter': False,
    #~ 'legacy_windows': True,
    #~ 'no_color': False,
    #~ 'quiet': False,
    #~ 'record': False,
    #~ 'safe_box': True,
    #~ 'soft_wrap': False,
    #~ 'stderr': False,
    #~ 'style': None,
    #~ 'tab_size': 8
}

package main;

#~ my $c = Cancer->new();
#~ my $text = Cancer::Text->new();
#~ use Data::Printer;
#~ p $text;
#~ $text .= 'Hey' . 'Two';
#~ p $text;
#~ warn $text->[3];
__END__
class Cancer::Region {
    field $x : param;
    field $y : param;
    field $width : param;
    field $height : param;
}

class Cancer::Box {
    field $ascii : param //= 0;
    field $box : param;
    ADJUST {
        use Data::Dump;
        ddx $box;
        if ( !ref $box ) {
            my @lines = split /\n/, $box;
            $box = {};
            #
            use Data::Dump;
            ddx \@lines;

            #~ ...;
            ( $box->{top_left},      $box->{top}, $box->{top_divider}, $box->{top_right} ) = split '', shift @lines;
            ( $box->{head_left},     undef, $box->{head_vertical}, $box->{head_right} ) = split '', shift @lines;
            ( $box->{head_row_left}, $box->{head_row_horizontal}, $box->{head_row_cross}, $box->{head_row_right} ) = split '', shift @lines;
            ( $box->{mid_left},      undef, $box->{mid_vertical}, $box->{mid_right} ) = split '', shift @lines;
            ( $box->{row_left},      $box->{row_horizontal}, $box->{row_cross}, $box->{row_right} ) = split '', shift @lines;
            ( $box->{foot_row_left}, $box->{foot_row_horizontal}, $box->{foot_row_cross}, $box->{foot_row_right}, ) = split '', shift @lines;
            ( $box->{foot_left},     undef, $box->{foot_vertical}, $box->{foot_right} ) = split '', shift @lines;
            ( $box->{bottom_left},   $box->{bottom}, $box->{bottom_divider}, $box->{bottom_right} ) = split '', shift @lines;
        }
        use Data::Dump;
        ddx $box;
    }

    method get_top($widths) {
        my $ret = $box->{top_left};
        for my $i ( 0 .. $#$widths ) {
            $ret .= $box->{top} x $widths->[$i];
            $ret .= $box->{top_divider} unless $i == $#$widths;
        }
        $ret . $box->{top_right};
    }

    method get_row( $widths, $level //= 'row', $edge //= 1 ) {
        my ( $ret, $left, $horizontal, $cross, $right );
        if ( $level eq 'head' ) {
            $left       = $box->{head_row_left};
            $horizontal = $box->{head_row_horizontal};
            $cross      = $box->{head_row_cross};
            $right      = $box->{head_row_right};
        }
        elsif ( $level eq 'row' ) {
            $left       = $box->{row_left};
            $horizontal = $box->{row_horizontal};
            $cross      = $box->{row_cross};
            $right      = $box->{row_right};
        }
        elsif ( $level eq 'mid' ) {
            $left       = $box->{mid_left};
            $horizontal = ' ';
            $cross      = $box->{mid_vertical};
            $right      = $box->{mid_right};
        }
        elsif ( $level eq 'foot' ) {
            $left       = $box->{foot_row_left};
            $horizontal = $box->{foot_row_horizontal};
            $cross      = $box->{foot_row_cross};
            $right      = $box->{foot_row_right};
        }
        else {
            die 'level must be "head", "row", "mid", or "foot"';
        }
        my $ret = '';
        $ret .= $left if $edge;
        for my $i ( 0 .. $#$widths ) {
            $ret .= $horizontal x $widths->[$i];
            $ret .= $cross unless $i == $#$widths;
        }
        $ret .= $right if $edge;
        $ret;
    }

    method get_bottom($widths) {
        my $ret = $box->{bottom_left};
        for my $i ( 0 .. $#$widths ) {
            $ret .= $box->{bottom} x $widths->[$i];
            $ret .= $box->{bottom_divider} unless $i == $#$widths;
        }
        $ret . $box->{bottom_right};
    }
}
#
class Cancer {
    use Time::HiRes qw[time sleep];
    field $double_buffer : param : reader //= 1;          # bool
    field $max_scope                  = 20;
    field $max_cells : param : reader = 2**17;
    field $max_buf : reader           = $max_cells * 4;
    field $alignment : reader : param = 0;                # auto center, width, height
    field $state : param : reader //= {
        cells => [ map {0} 0 .. ( $max_cells << $double_buffer ) ],    # screen buffer
        buf   => chr(0) x $max_buf                                     #  output buffer
    };
    #
    field $platform : reader;

    # events
    method is_event_key( $type, $key ) { }
    method is_key_press($key)          { }
    method is_mouse_over($rect)        { }
    method is_click_over($rect)        { }

    # drawing
    method cell( $str, $fg, $bg )                 { }
    method clear_cells()                          { }
    method draw_chr( $cell, $x, $y )              { }
    method draw_row( $cell, $x, $h, $w )          { }
    method draw_col( $cell, $x, $y, $h )          { }
    method draw_lot( $cell, $x, $y, $w, $h )      { }
    method draw_str( $str, $x, $y, $w, $fg, $bg ) { }
    method draw_box( $x, $y, $w, $h, $fg, $bg )   { }
    method draw_invert( $x, $y, $w )              { }
    method abs_xywh( $x, $y, $w, $h )             { }
    method enter_scope( $x, $y, $w, $h )          { }
    method exit_scope()                           { }

    # widgets
    method frame( $x, $y, $w, $h, $color )               { }
    method label( $str, $x, $y, $w, $h, $color )         { }
    method button( $str, $x, $y, $w, $h, $color )        { }
    method edit( $edit, $x, $y, $w, $color )             { }
    method check( $str, $state, $x, $y, $w, $color )     { }
    method radio( $str, $state, $v, $x, $y, $w, $color ) { }

    # widget tasks
    method edit_insert( $edit, $str ) { }
    method edit_delete($edit)         { }
    method edit_event( $edit, $rect ) { }

    # rendering
    method put_chr($chr)          { }
    method put_str( $str, $size ) { }
    method put_int($i)            { }
    method render()               { }

    # event loop
    sub layout_frames ( $x, $y, $w, $h ) {

        # Assuming a simple 2x2 grid layout for demonstration
        my $num_rows = 2;
        my $num_cols = 2;

        # Calculate the width and height of each frame and content
        my $frame_width    = $w / $num_cols;
        my $frame_height   = $h / $num_rows;
        my $content_width  = $frame_width * 0.8;    # Adjust content size as needed
        my $content_height = $frame_height * 0.8;

        # Initialize arrays to store frame and content positions
        my @frame_positions;
        my @content_positions;

        # Iterate over rows and columns to calculate positions
        for my $row ( 0 .. $num_rows - 1 ) {
            for my $col ( 0 .. $num_cols - 1 ) {
                my $frame_x = $x + $col * $frame_width;
                my $frame_y = $y + $row * $frame_height;
                push @frame_positions, [ $frame_x, $frame_y ];
                my $content_x = $frame_x + ( $frame_width - $content_width ) / 2;
                my $content_y = $frame_y + ( $frame_height - $content_height ) / 2;
                push @content_positions, [ $content_x, $content_y ];
            }
        }
        return ( \@frame_positions, \@content_positions );
    }

    sub generate_coordinates( $x, $y, $w, $h ) {
        my @x_coords = ();
        my @y_coords = ();
        for my $i ( 0 .. $w - 1 ) {
            push @x_coords, $x + $i;
        }
        for my $i ( 0 .. $h - 1 ) {
            push @y_coords, $y + $i;
        }
        my @coordinates = ();
        for my $x_coord (@x_coords) {
            for my $y_coord (@y_coords) {
                push @coordinates, [ $x_coord, $y_coord ];
            }
        }
        return @coordinates;
    }
    my $slide              = 1;
    my $dir                = 1;
    my $SQUARE_DOUBLE_HEAD = Cancer::Box->new( box => <<'');
┌─┬┐
│ ││
╞═╪╡
│ ││
├─┼┤
├─┼┤
│ ││
└─┴┘

    my $ROUNDED = Cancer::Box->new( box => <<'');
╭─┬╮
│ ││
├─┼┤
│ ││
├─┼┤
├─┼┤
│ ││
╰─┴╯


    sub hsl2hsv ( $h, $s, $l ) {
        $h >= 0 && $h <= 360 or $h = _wrap_h($h);

        #~ $s>=0 && $s<=1 or die "Invalid S in HSL '$hsl', must be in 0-1";
        #~ $l>=0 && $l<=1 or die "Invalid L in HSL '$hsl', must be in 0-1";
        my $_h = $h;
        my $_s;
        my $_v;
        $l *= 2;
        $s *= ( $l <= 1 ) ? $l : 2 - $l;
        $_v = ( $l + $s ) / 2;
        $_s = ( 2 * $s ) / ( $l + $s );
        ( $_h, $_s, $_v );
    }

    sub hsv2hsl( $h, $s, $v ) {
        $h >= 0 && $h <= 360 or $h = _wrap_h($h);

        #~ $s>=0 && $s<=1 or die "Invalid S in HSV '$hsv', must be in 0-1";
        #~ $v>=0 && $v<=1 or die "Invalid V in HSV '$hsv', must be in 0-1";
        my $_h = $h;
        my $_s = $s * $v;
        my $_l = ( 2 - $s ) * $v;
        $_s /= $_l <= 1 ? ( $_l == 0 ? 1 : $_l ) : ( 2 - $_l );
        $_l /= 2;
        ( $_h, $_s, $_l );
    }

    sub hsl2rgb ( $h, $s, $l ) {
        hsv2rgb( hsl2hsv( $h, $s, $l ) );
    }

    sub hls_to_rgb ( $h, $l, $s ) {
        hsv2rgb( hsl2hsv( $h, $s, $l ) );
    }

    sub hsv2rgb( $h, $s, $v ) {
        $h >= 0 && $h <= 360 or $h = _wrap_h($h);

        #~ $s>=0 && $s<=1 or die "Invalid S in HSV '$hsv', must be in 0-1";
        #~ $v>=0 && $v<=1 or die "Invalid V in HSV '$hsv', must be in 0-1";
        my $i = int( $h / 60 );
        my $f = $h / 60 - $i;
        my $p = $v * ( 1 - $s );
        my $q = $v * ( 1 - $f * $s );
        my $t = $v * ( 1 - ( 1 - $f ) * $s );
        my ( $r, $g, $b );
        if ( $i == 0 ) {
            $r = $v;
            $g = $t;
            $b = $p;
        }
        elsif ( $i == 1 ) {
            $r = $q;
            $g = $v;
            $b = $p;
        }
        elsif ( $i == 2 ) {
            $r = $p;
            $g = $v;
            $b = $t;
        }
        elsif ( $i == 3 ) {
            $r = $p;
            $g = $q;
            $b = $v;
        }
        elsif ( $i == 4 ) {
            $r = $t;
            $g = $p;
            $b = $v;
        }
        else {
            $r = $v;
            $g = $p;
            $b = $q;
        }
        ( $r, $g, $b );
    }

    sub _hls_to_rgb ( $h, $l, $s ) {
        my $c = $s * ( 1 - abs( 2 * $l - 1 ) );
        my $x = $c * ( 1 - abs( ( $h / 60 ) % 2 - 1 ) );
        my $m = $l - $c / 2;
        my ( $r, $g, $b )
            = ( $h < 60 ) ? ( $c, $x, 0 ) :
            ( $h < 120 )  ? ( $x, $c, 0 ) :
            ( $h < 180 )  ? ( 0, $c, $x ) :
            ( $h < 240 )  ? ( 0, $x, $c ) :
            ( $h < 300 )  ? ( $x, 0, $c ) :
            ( $c, 0, $x );
        ( $r + $m ), ( $g + $m ), ( $b + $m );
    }

    method one_frame($frame_time) {
        my $deadline = time + $frame_time;
        print { $platform->tty_o } Cancer::Terminal::erase_display_all() . Cancer::Terminal::cursor_position( 0, 0 );

        #~ print { $platform->tty_o } Cancer::Terminal::cursor_position( 0, 0 );
        #~ for my $xy ( generate_coordinates( 1 + $slide, 1, 20, 10 ) ) {
        #~ print { $platform->tty_o } Cancer::Terminal::write_at( @$xy, '█' );
        #~ }
        if (0) {
            for ( my $red = 0; $red < 256; $red += 51 ) {
                for ( my $blue = 0; $blue < 256; $blue += 51 ) {
                    for ( my $green = 0; $green < 256; $green += 51 ) {
                        print { $platform->tty_o } Cancer::Terminal::fg_rgb( $red, $green, $blue ) .
                            Cancer::Terminal::bg_rgb( $red, $green, $blue ) . "▄";
                    }
                }
                print { $platform->tty_o } "\n";
            }
        }
        {
            use Graphics::Toolkit::Color;
            my $c1     = Graphics::Toolkit::Color->new('red');                               # create color object
            my @colors = $c1->gradient( to => [ 0, 0, 255 ], steps => 100, dynamic => 3, in => 'HSL' );
            print { $platform->tty_o } Cancer::Terminal::bg_rgb( $_->values ) . '▄' for @colors;

            #~ print { $platform->tty_o } Cancer::Terminal::fg_rgb( int( $r2 * 255 ), int( $g2 * 255 ), int( $b2 * 255 ) );
        }
        if (1) {
            my $max_x = 100;
            for my $y ( 0 .. 4 ) {
                for my $x ( 1 .. $max_x - 1 ) {
                    my $h = ( $x / $max_x ) * 360;
                    my $l = 0.1 + ( ( $y / 5 ) * 0.7 )/10;
                    my ( $r1, $g1, $b1 ) = _hls_to_rgb( $h, $l, 1.0 );
                    my ( $r2, $g2, $b2 ) = _hls_to_rgb( $h, $l + 0.07, 1.0 );
                    print { $platform->tty_o } Cancer::Terminal::bg_rgb( int( $r1 * 255 ), int( $g1 * 255 ), int( $b1 * 255 ) );
                    print { $platform->tty_o } Cancer::Terminal::fg_rgb( int( $r2 * 255 ), int( $g2 * 255 ), int( $b2 * 255 ) );
                    print { $platform->tty_o } '▄';

                    #~ print { $platform->tty_o } $h;
                    #~ warn sprintf "X: %d, H: %f, L: %f, R: %f, G: %f, B: %f", $x, $h, $l, $r1, $g1, $b1;
                }
                print { $platform->tty_o } "\n";
            }
        }

        #~ die;
        {
            my $box  = $ROUNDED;         # $SQUARE_DOUBLE_HEAD;
            my $cols = [ 10, 10, 30 ];
            my $row  = 0;
            print { $platform->tty_o } Cancer::Terminal::fg_rgb( 0, 1, 255 ) .
                Cancer::Terminal::bg_rgb( 245, 222, 179 ) .
                Cancer::Terminal::write_at( $slide, 19, $box->get_top($cols) ) .

                #~ Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'head', 1 ) ) .
                #~ Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'row',  1 ) ) .
                Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'mid', 1 ) ) .
                Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'mid', 1 ) ) .
                Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'mid', 1 ) ) .

                #~ Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_row( $cols, 'foot', 1 ) ) .
                Cancer::Terminal::write_at( $slide, 20 + $row++, $box->get_bottom($cols) )
        }
        $dir = $slide == 0 ? 1 : $slide == 80 ? -1 : $dir;

        #~ $slide = 0 if $slide >= 120;
        $slide += $dir;
        #
        my $diff = $deadline - time;
        $platform->read_event($diff) if $diff > 0;
        $platform->tty_o->flush;
    }

    method loop( $fps //= 60 ) {
        my $frame_time = 1 / $fps;
        while (1) {
            my $start_time = time;
            $self->one_frame($frame_time);
            my $sleep_time = $frame_time - ( time - $start_time );
            sleep $sleep_time if $sleep_time > 0;
        }
    }
    #
    ADJUST {
        #~ warn __CLASS__ . '::ADJUST()';
        $platform = $^O eq 'MSWin32' ? Cancer::Platform::Windows->new() : Cancer::Platform::Unix->new();
    };
    method DESTROY { }
    #
    use constant {    # event_type
        DRAW_EVENT  => 0,    # draw screen
        KEY_EVENT   => 1,    # a key was pressed
        MOUSE_EVENT => 2,    # mouse button, scroll or move
        VOID_EVENT  => 3     # set when an event was consumed
    };
    use constant {           #event.key
        LEFT_BUTTON   => 1,
        BACKSPACE_KEY => 8,
        TAB_KEY       => 9,
        ENTER_KEY     => 13,
        ESCAPE_KEY    => 27,
        INSERT_KEY    => -1,
        DELETE_KEY    => -2,
        HOME_KEY      => -3,
        END_KEY       => -4,
        PAGEUP_KEY    => -5,
        PAGEDOWN_KEY  => -6,
        UP_KEY        => -7,
        DOWN_KEY      => -8,
        LEFT_KEY      => -9,
        RIGHT_KEY     => -10
    };

    method ztrlen($str) {    # strlen bur returns 0 on overflow
        my $n = $str ? length $str : 0;
        $n > 0 ? $n : 0;
    }

    method bsr8($x) {        # bit scan reverse, count leading zeros
        my $n = 0;
        for ( ; $n < 8 && !( $x & 128 ); $n++, $x <<= 1 ) {;}
        $n;
    }

    method utfchr( $str //= '' ) {    # decode one utf8 code point

        # use bit magic to mask out leading utf8 1s
        my $c = substr( $str, 0, 1 ) & ( ( 1 << ( 8 - bsr8( ~substr( $str, 0, 1 ) ) ) ) - 1 );
        for ( my $i = 1; substr( $str, 0, 1 ) && substr( $str, $i, 1 ) && $i < 4; $i++ ) {
            $c = ( $c << 6 ) | ( substr( $str, $i, 1 ) & 63 );
        }
        $c;
    }

    method utflen ($str) {            # number of utf8 code points
        my $n = 0;
        for ( my $i = 0; $str && substr( $str, $i, 1 ); $i++ ) {
            $n += ( substr( $str, $i, 1 ) & 192 ) != 128;
        }
        $n;
    }

=c

    // index of utf8 code point at pos
static int utfpos(const char* s, int pos) {
    int i = 0;
    for (int n = 0; pos >= 0 && s && s[i]; i++) {
        n += (s[i] & 192) != 128;
        if (n == pos + 1) {
            return i;
        }
    }
    return i;
}

// scan string for width and lines
static struct text scan_str(const char* str) {
    const char* s = str ? str : "";
    struct text t = {
        .width = 0,
        .lines = (s[0] != 0),
    };
    int width = 0;
    for (t.size = 0; s[t.size]; t.size++) {
        char ch      = s[t.size];
        int  newline = (ch == '\n');
        width = newline ? 0 : width;
        width += (ch & 192) != 128 && (uint8_t)ch > 31;
        t.lines += newline;
        t.width = MAX(t.width, width);
    }
    return t;
}

// iterate through lines, false when end is reached
static bool next_line(struct line* l) {
    if (!l->str || !l->str[0]) {
        return false;
    }
    l->line  = l->str;
    l->size  = 0;
    l->width = 0;
    for (const char* s = l->str; s[0] && s[0] != '\n'; s++) {
        l->size  += 1;
        l->width += (s[0] & 192) != 128 && (uint8_t)s[0] > 31;
    }
    l->str += l->size + !!l->str[l->size];
    return true;
}

// true if utf8 code point could be wide
static bool is_wide_perhaps(const uint8_t* s, int n) {
    // Character width depends on character, terminal and font. There is no
    // reliable method, however most frequently used characters are narrow.
    // Zero with characters are ignored, and hope that user input is benign.
    if (n < 3 || s[0] < 225) {
        // u+0000 - u+1000, basic latin - tibetan
        return false;
    } else if (s[0] == 226 && s[1] >= 148 && s[1] < 152) {
        // u+2500 - u+2600 box drawing, block elements, geometric shapes
        return false;
    }
    return true;
}
=cut

}

package Cancer::Terminal {
    use v5.40;
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

    # DEC Private Mode Reset
    sub hide_cursor() { CSI . '?' . CURSOR() . 'l' }
    sub show_cursor() { CSI . '?' . CURSOR() . 'h' }

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

    # Erase in Display (DECSED), VT220.
    sub erase_display_below() { CSI . 0 . 'J' }
    sub erase_display_above() { CSI . 1 . 'J' }
    sub erase_display_all()   { CSI . 2 . 'J' }
    sub erase_display_saved() { CSI . 3 . 'J' }

    # Erase in Line (EL), VT100.
    sub erase_line_right () { CSI . 0 . 'K' }
    sub blank_line_left ()  { CSI . 1 . 'K' }
    sub blank_line_all ()   { CSI . 2 . 'K' }
    #
    sub cursor_position ( $x, $y ) {
        ESC . '[' . ( $y + 1 ) . ';' . ( $x + 1 ) . 'H';
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

class Cancer::Platform::Unix {
    use Time::HiRes qw[time];
    method write_str( $str, $size ) { }
    method signal_handler($sig)     { }
    method update_screen_size()     { }
    ADJUST {
        #~ warn __CLASS__ . '::ADJUST()';
    }
    method DESTROY()                 { }
    method parse_input( $event, $n ) { }
    method read_event($timeout)      { }
    method timeus()                  { time; }
    #
    # events
    method on_mouse( $x, $y, $bnts, $ctrl_keys, $event ) { }

    method on_keyboard( $down, $repeat_x, $key, $scan, $ascii, $ctrl_keys ) {
        warn chr $ascii if $down;
        exit            if chr $ascii eq 'q';
    }
}

class Cancer::Platform::Windows : isa(Cancer::Platform::Unix) {
    use Win32::Console qw[/STD_.+PUT_HANDLE/ /ENABLE_/];
    use Fcntl          qw[O_RDWR O_NDELAY O_NOCTTY];
    use Time::HiRes    qw[sleep];
    require Win32;
    require IO::Handle;
    use feature 'try';
    no warnings 'experimental::try';
    #
    use Carp qw[croak];
    #
    field $tty_i;
    field $tty_o : reader;
    #
    field $stdin;
    field $stdout;

    # Store these for reset_terminal
    field $mode_i;
    field $mode_o;
    method write_str( $str, $size ) { }
    method update_screen_size()     { }
    ADJUST {
        #~ warn __CLASS__ . '::ADJUST()';
        # Get console handles
        $stdin  = Win32::Console->new(STD_INPUT_HANDLE);
        $stdout = Win32::Console->new(STD_OUTPUT_HANDLE);

        #~ https://learn.microsoft.com/en-us/windows/console/setconsolemode
        # Modify input mode
        my $mode = $mode_i = $stdin->Mode;
        $mode &= ~ENABLE_ECHO_INPUT;
        $mode &= ~ENABLE_LINE_INPUT;
        $mode &= ~ENABLE_PROCESSED_INPUT;
        $mode |= ENABLE_WINDOW_INPUT;
        $mode |= ENABLE_MOUSE_INPUT;
        $mode |= ENABLE_LINE_INPUT;
        $mode |= 0x80;                  # ENABLE_EXTENDED_FLAGS
        $mode &= ~0x0040;               # ENABLE_QUICK_EDIT_MODE
        $stdin->Mode($mode);

        # Modify output mode
        $mode = $mode_o = $stdout->Mode;
        $mode |= ENABLE_PROCESSED_OUTPUT;
        $mode |= 0x0004;                    # ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        $stdout->Mode($mode);
        #
        sysopen( $tty_i, 'CONIN$', O_RDWR ) or croak "Unable to open console input: $!";
        croak 'Not a terminal.' unless -t $tty_i;

        #~ binmode $tty_i;
        sysopen( $tty_o, 'CONOUT$', O_RDWR ) or croak "Unable to open console output: $!";
        croak 'Not a terminal.' unless -t $tty_o;
        #
        binmode $tty_i, ':encoding(UTF-8)';
        Win32::Console::InputCP(65001);
        #
        binmode $tty_o, ':encoding(UTF-8)';
        Win32::Console::OutputCP(65001);
        #
        print $tty_o Cancer::Terminal::SCP();                      # Store cursor position
        print $tty_o Cancer::Terminal::hide_cursor();              # Hide cursor
        print $tty_o Cancer::Terminal::ALT_BUFF_ON();              # Switch to alternate buffer
        print $tty_o Cancer::Terminal::FOCUS_ON();                 # Report changes in window focus
        print $tty_o Cancer::Terminal::osc_title('Cancer');        # change window title
        print $tty_o Cancer::Terminal::cursor_position( 0, 0 );    # Move cursor
        $tty_o->flush;
    }

    method DESTROY {
        print $tty_o Cancer::Terminal::RCP();                                                        # Restore cursor position
        print $tty_o Cancer::Terminal::color_default_fg() . Cancer::Terminal::color_default_bg();    # Reset colors
        print $tty_o Cancer::Terminal::show_cursor();                                                # show cursor
        print $tty_o Cancer::Terminal::FOCUS_OFF();                                                  # Stop reporting changes in window focus
        print $tty_o Cancer::Terminal::ALT_BUFF_OFF();                                               # Exit alternate buffer
        $tty_o->flush;
        #
        close $tty_i;
        close $tty_o;
        #
        $stdin->Mode($mode_i);
        $stdout->Mode($mode_o);
    }

    method read_event( $timeout //= 0.01 ) {    # TODO: timeout should be based on FPS
        my $dest = time + $timeout;
        while ( time < $dest ) {
            $stdin->GetEvents() || last;
            my @event = $stdin->Input;
            last unless scalar @event;
            my $type = shift @event;
            if ( $type == 1 ) {
                $self->on_keyboard(@event);
                last;
            }
            elsif ( $type == 2 ) {
                $self->on_mouse(@event);
                last;
            }
            else {
                ...;
            }
        }
        my @info = $stdin->Info;
        my ( $x, $y, $cx, $cy, $w, $x0, $y0, $wx, $hx, $maxc, $maxr ) = @info;
        #
        $dest - time;
    }
}
#
$|++;
use Time::HiRes qw[sleep];
my $c = Cancer->new();
$c->loop(120) while 1;
sleep 5;




1;
__END__
=encoding utf-8

=head1 NAME

Cancer - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;
    ...;

=head1 DESCRIPTION

Rich console stuff

=head1 See Also

TODO

=head1 LICENSE

This software is Copyright (c) 2024 by Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=begin stopwords


=end stopwords

=cut
