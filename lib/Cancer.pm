package Cancer 0.01 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::for_list';    # Be quiet.
    use feature 'class';
    use experimental 'try';
    #
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    use POSIX qw[:termios_h];
    use IO::Select;
    use Time::HiRes;
    use Carp qw[croak];
    #
    my $Win32 = $^O eq 'MSWin32' ? 1 : !1;

    # https://gist.github.com/klaus03/e1910904104552765e6b
    system 'chcp 65001 >NUL' if $Win32;
    #
    use Cancer::Colors;
    use Cancer::terminfo;
    use Cancer::terminfo::xterm::256color;
    #
    class Cancer {
        field $term : param     //= $Win32 ? fileno(STDOUT) : '/dev/tty';
        field $tty : param      //= ();
        field $type : param     //= 'Cancer::terminfo::xterm::256color';
        field $terminfo : param //= '';
        #
        field $front_buffer : param //= ();
        field $back_buffer : param  //= ();
        method front_buffer {$front_buffer}
        method back_buffer  {$back_buffer}
        field $width : param  //= ();
        field $height : param //= ();

        # events
        field $winch : param //= ();

        # Restore state
        field $cflag;
        field $iflag;
        field $oflag;
        field $lflag;
        field $sig_winch;
        #
        ADJUST {
            if ( !defined $tty ) {
                if ($Win32) {
                    require IO::Handle;
                    $tty = IO::Handle->new_from_fd( $term, '+<' );
                }
                else {
                    croak sprintf 'Cannot open %s: %s', $term, $! unless sysopen $tty, $term, O_RDWR | O_NDELAY | O_NOCTTY;
                    croak 'Not a terminal.' unless -t $tty;
                }
            }
            $terminfo = $type->new;
            if ( !defined $height || !defined $width ) {
                my ( $w, $h ) = $self->get_win_size();
                $width  //= $w;
                $height //= $h;
            }
            $front_buffer //= Cancer::Buffer->new( width => $width, height => $height );
            $back_buffer  //= Cancer::Buffer->new( width => $width, height => $height );
            if ($Win32) { }
            else {
                my $fileno = fileno $tty;

                # Keep an original copy
                my $raw = POSIX::Termios->new();
                $raw->getattr($fileno);

                # backup
                my $_cflag = $cflag = $raw->getcflag;
                my $_iflag = $iflag = $raw->getiflag;
                my $_oflag = $oflag = $raw->getoflag;
                my $_lflag = $lflag = $raw->getlflag;

                # https://man7.org/linux/man-pages/man3/termios.3.html
                $_iflag = $_iflag & ~( IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON );
                $raw->setiflag($_iflag);
                $_oflag = $_oflag & ~OPOST;    # Disables post-processing output. Like turning \n into \r\n
                $raw->setoflag($_oflag);
                $_lflag = $_lflag & ~( ECHO | ECHONL | ICANON | ISIG | IEXTEN );
                $raw->setlflag($_lflag);
                $_cflag = $_cflag & ~( CSIZE | PARENB );
                $_cflag |= CS8;
                $raw->setcflag($_cflag);

                # This is setup for blocking reads.  In the past we attempted to
                # use non-blocking reads, but now a separate input loop and timer
                # copes with the problems we had on some systems (BSD/Darwin)
                # where close hung forever.
                $raw->setcc( VMIN,  1 );
                $raw->setcc( VTIME, 0 );
                #
                $sig_winch = $SIG{WINCH} if $SIG{WINCH};
                #<<V
                $SIG{WINCH} = method {
                    $sig_winch->() if defined $sig_winch;
                    my ( $rows, $cols ) = $self->get_win_size();
                    return $self->winch_event( Cancer::Event::Resize->new( w => $cols, h => $rows ) );
                };
                #>>V
                $SIG{WINCH}->($self);
                $raw->setattr( $fileno, TCSANOW );

                # enter mouse
                syswrite $tty, "\x1b[?1000h\x1b[?1002h\x1b[?1015h\x1b[?1006h";

#define TB_HARDCAP_ENTER_MOUSE  "\x1b[?1000h\x1b[?1002h\x1b[?1015h\x1b[?1006h"
#define TB_HARDCAP_EXIT_MOUSE   "\x1b[?1006l\x1b[?1015l\x1b[?1002l\x1b[?1000l"
#define TB_HARDCAP_STRIKEOUT    "\x1b[9m"
#define TB_HARDCAP_UNDERLINE_2  "\x1b[21m"
#define TB_HARDCAP_OVERLINE     "\x1b[53m"
            }
        }
        #
        method cls ( $now //= !1 ) {    # immediate
            $now ? syswrite $tty, $terminfo->Clear : 'TODO: clear front and back buffers';
        }

        method get_win_size {
            my $w = "\0" x 8;
            $tty // Carp::confess 'WHAT?';
            ioctl( $tty, $self->TIOCGWINSZ(), $w );
            my ( $rows, $cols ) = unpack 'S2', $w;    # rows, cols, pix_x, pix_y
            $rows //= $ENV{LINES};
            $cols //= $ENV{COLUMNS};
            return ( $rows, $cols );

            #Fallback: split ' ', qx[stty size </dev/tty 2>/dev/null];
        }

        method render() {
            syswrite $tty, $front_buffer->data;
            $front_buffer->data('');                  # Clear buffer
        }

        method write_at ( $x, $y, $string ) {
            $front_buffer->data( $front_buffer->data . sprintf "\033[%d;%dH%s", $y, $x, $string );
            $self->render;
        }

        method write ($string) {
            $front_buffer->data( $front_buffer->data . $string );
            $self->render;
        }
        method read ($len//=1){
        sysread $tty, my( $ret), $len;
$ret;
        }

        method hide_cursor () {
            syswrite $tty, "\e[?25l"    # immediate
        }

        method show_cursor () {
            syswrite $tty, "\e[0H\e[0J\e[?25h"    # immediate
        }

        # Event system
        method winch_event ($e) { $winch->($e) if defined $winch; }

        # Platform utils
        method TIOCGWINSZ () {    # See Perl::osnames
            return 0x800c     if $^O =~ qr/\A(?:beos)\z/;
            return 0x40087468 if $^O =~ qr/\A(?:MacOS|iphoneos|bitrig|dragonfly|(free|net|open)bsd|bsdos)\z/;
            return 0x5468     if $^O =~ qr/\A(?:solaris|sunos)\z/;
            return 0x5413         # Linux and android
        }

        method DESTROY ( $global = 0 ) {    # TODO: Reset everything else we've done so far like enable mouse
            $tty // return;

            #~ $s->title('') if $s->has_title();
            #~ $s->mouse(0)  if $s->mouse;
            #
            my $fileno = fileno($tty);
            $fileno // return;
            if ($Win32) {
            }
            else {
                # Restore original copy
                my $raw = POSIX::Termios->new();
                $raw->getattr($fileno);
                $raw->setcflag($cflag);
                $raw->setiflag($iflag);
                $raw->setoflag($oflag);
                $raw->setlflag($lflag);
                #
                $raw->setattr( $fileno, TCSANOW );

                #$s
                $SIG{WINCH} = $sig_winch if defined $sig_winch;    # Restore original winch
                close $;;

            # exit mouse
            syswrite $tty,    "\x1b[?1006l\x1b[?1015l\x1b[?1002l\x1b[?1000l"
        }
        }
    };
    class Cancer::Buffer 0.01 {
        field $width : param;          # int, required
        field $height : param;         # width, required
        field $data : param //= '';    # data

        #
        method width                   {$width}
        method height                  {$height}
        method data ( $append //= () ) { $data = $append if defined $append; $data }
    };
    class Cancer::Cell 0.01 {
        use feature 'unicode_strings';
        field $chr : param   //= ();    # char
        field $dirty : param //= 1;     # bool; only redraw if true
        field $style : param //= ();    # Unknown right now; I need to decide what styles look like

        method chr ( $c //= () ) {
            if ( defined $c ) {
                Carp::croak "'$c' is too wide" if 1 < ( 0 + ( () = $c =~ /\w/g ) );
                $chr   = $c;
                $dirty = 1;
            }
            $chr;
        }
        method clean { $dirty = 0 }
        #
        method width  { 0 + ( defined $chr ? () = $chr =~ /\X/gu : 0 ) }    # Grapheme size
        method length { 0 + ( defined $chr ? () = $chr =~ /\w/gu : 0 ) }    # Display size
    };
    class Cancer::Event 0.01 {

        #define TB_KEY_F1               (0xFFFF - 0);
        #define TB_KEY_F2               (0xFFFF - 1);
        #define TB_KEY_F3               (0xFFFF - 2);
        #define TB_KEY_F4               (0xFFFF - 3);
        #define TB_KEY_F5               (0xFFFF - 4);
        #define TB_KEY_F6               (0xFFFF - 5);
        #define TB_KEY_F7               (0xFFFF - 6);
        #define TB_KEY_F8               (0xFFFF - 7);
        #define TB_KEY_F9               (0xFFFF - 8);
        #define TB_KEY_F10              (0xFFFF - 9);
        #define TB_KEY_F11              (0xFFFF - 10);
        #define TB_KEY_F12              (0xFFFF - 11);
        #define TB_KEY_INSERT           (0xFFFF - 12);
        #define TB_KEY_DELETE           (0xFFFF - 13);
        #define TB_KEY_HOME             (0xFFFF - 14);
        #define TB_KEY_END              (0xFFFF - 15);
        #define TB_KEY_PGUP             (0xFFFF - 16);
        #define TB_KEY_PGDN             (0xFFFF - 17);
        #define TB_KEY_ARROW_UP         (0xFFFF - 18);
        #define TB_KEY_ARROW_DOWN       (0xFFFF - 19);
        #define TB_KEY_ARROW_LEFT       (0xFFFF - 20);
        #define TB_KEY_ARROW_RIGHT      (0xFFFF - 21);
        sub TB_KEY_MOUSE_LEFT       { 0xFFFF - 22 }
        sub TB_KEY_MOUSE_RIGHT      { 0xFFFF - 23 }
        sub TB_KEY_MOUSE_MIDDLE     { 0xFFFF - 24 }
        sub TB_KEY_MOUSE_RELEASE    { 0xFFFF - 25 }
        sub TB_KEY_MOUSE_WHEEL_UP   { 0xFFFF - 26 }
        sub TB_KEY_MOUSE_WHEEL_DOWN { 0xFFFF - 27 }
        #
        # Alt modifier constant, see tb_event.mod field and tb_select_input_mode
        # function. Mouse-motion modifier
        sub TB_MOD_ALT    { 0x01; }
        sub TB_MOD_MOTION { 0x02; }
        #
        field $time : param //= method { Time::HiRes::time() }

        #has [qw[type mod key ch x y]] => ( is => 'rw', isa => Int );
    };

    class Cancer::Event::Key : isa(Cancer::Event) {
        field $glyph : param;        # string, required
        field $mod : param //= 0;    # int
    };

    class Cancer::Event::Mouse : isa(Cancer::Event) {
        field $button : param //= ();    # int
        field $mod : param    //= ();    # int
        field $x : param      //= ();    # int
        field $y : param      //= ();    # int
    };

    class Cancer::Event::Resize : isa(Cancer::Event) {
        field $w : param //= ();         # int
        field $h : param //= ();         # int
        method w () {$w}
        method h () {$h}
    };
    1;
}
1;
__END__
    # Store these and restore them on destruction
    CORE::state( $cflag, $iflag, $oflag, $lflag );
    has [qw[cflag iflag oflag lflag]] => ( is => 'rw', isa => Int, predicate => 1 );

    sub BUILD ( $s, $args ) {
        Role::Tiny->apply_roles_to_object( $s, join '::', 'Cancer', 'terminfo', split '-', $ENV{TERM} // '' );
        #
        my $fileno = fileno( $s->tty );
        if ($Win32) {
            Role::Tiny->apply_roles_to_object( $s, 'Cancer::terminfo::xterm' );

            #Role::Tiny->apply_roles_to_object( $s, 'Cancer::Platform::Windows' );
        }
        else {
            # Keep an original copy
            #moved
        }
        #
        # Todo: If the user's platform exists, load it
        # Todo: If the user has AnyEvnet, POE, or IO::Async loaded, use them
        Role::Tiny->apply_roles_to_object( $s, 'Cancer::IO::Select' );
    }

    # Resize
    has winch_event        => ( is => 'rw',  isa => InstanceOf ['Cancer::Event'], lazy => 1, predicate => 1, clearer => 1 );
    has sig_winch          => ( is => 'rwp', isa => CodeRef, lazy => 1, predicate => 1 );
    has [qw[width height]] => ( is => 'ro',  isa => Int,     lazy => 1, builder   => 1, clearer => 1 );



    sub raw_write ( $s, $data ) {
        $s->front_buffer->data( $s->front_buffer->data . $data );
    }


    has mouse => (
        is      => 'rw',
        isa     => Bool,
        lazy    => 1,
        trigger => sub ( $s, $on ) {

#  "", "", "\033[?25h\033[?0c", "\033[?25l\033[?1c", "\033[H\033[J", "\033[0;10m", "\033[4m", "\033[1m", "\033[5m", "\033[7m", "", "", "", "",
#"\0337\033[?47h", "\033[2J\033[?47l\0338", "\033[?25h", "\033[?25l", "\033[H\033[2J", "\033[m", "\033[4m", "\033[1m", "\033[5m", "\033[7m", "\033=", "\033>", ENTER_MOUSE_SEQ, EXIT_MOUSE_SEQ,
#"\0337\033[?47h", "\033[2J\033[?47l\0338", "\033[?25h", "\033[?25l", "\033[H\033[2J",
#"\033[m", "\033[4m", "\033[1m", "\033[5m", "\033[7m", "\033=", "\033>", ENTER_MOUSE_SEQ, EXIT_MOUSE_SEQ,
# 1000 -
#my $data = "\x1b[?1000;1002;1003;1005;1006;1015" . ( $on ? 'h' : 'l' );    # high/low
#$data = "\033=\n" . $data;
#return $s->raw_write($data) unless $s->has_tty;
#syswrite $s->tty, $data                                                    # immediate
#define Mouse     => "\x1b[M";
#define MouseMode => "%?%p1%{1}%=%t%'h'%Pa%e%'l'%Pa%;\x1b[?1000%ga%c\x1b[?1002%ga%c\x1b[?1003%ga%c\x1b[?1006%ga%c";
        },
    );

    sub clear_screen ($s) {
        $s->front_buffer->data( $s->front_buffer->data . "\033[2J\033[" . $s->height . ";3H" );
    }

    #has color_mode => ();
    has _unused_data => ( is => 'rw', isa => Str, default => '', predicate => 1 );

    sub __readURXVT {
        my $c = chr( $_[0] );
        my $str;
        while ( $c ne ';' && $c ne 'M' ) {
            $str .= $c;
            $c = shift @_;
        }
        return $str;
    }

    sub _parseEventsFromInput ($s) {
        if ( $s->has_winch_event ) {
            my $retval = $s->winch_event;
            $s->clear_winch_event( () );
            return $retval;
        }
        #
        return if !length $s->_unused_data();    # Don't bother when we have no data

        # Parse runes first
        my @bytes = split //, $s->_unused_data();

        #if ($bytes[0] <= ord ' ' && ord $bytes[0] <= 0x7F) { # handle runes
        # printable ASCII can be handled without encoding
        # Use this: /[^[:print:]]/g
        #}
        #ddx \@bytes;
        #ddx @bytes[0..2];
        #ddx join('', @bytes[0..2]);
        #ddx "\033[M";
        if ( $s->mouse ) {    # Only bother if we have the mouse enabled
            if ( scalar @bytes >= 6 && join( '', @bytes[ 0 .. 2 ] ) eq "\033[M" ) {

                # X10 mouse encoding
                my $b     = ord( $bytes[3] ) - 32;
                my $match = $b & 3;
                my $event = Cancer::Event::Mouse->new();
                if ( $match == 0 ) {
                    $event->button( ( ( $b & 64 ) != 0 ) ? Cancer::Event::TB_KEY_MOUSE_WHEEL_UP() : Cancer::Event::TB_KEY_MOUSE_LEFT() );
                }
                elsif ( $match == 1 ) {
                    $event->button( ( ( $b & 64 ) != 0 ) ? Cancer::Event::TB_KEY_MOUSE_WHEEL_DOWN() : Cancer::Event::TB_KEY_MOUSE_MIDDLE() );
                }
                elsif ( $match == 2 ) {
                    $event->button( Cancer::Event::TB_KEY_MOUSE_RIGHT() );
                }
                elsif ( $match == 3 ) {
                    $event->mod( $event->mod & Cancer::Event::TB_KEY_MOUSE_RELEASE() );
                }
                if ( $match != 0 ) {
                    $event->mod( $event->mod & Cancer::Event::TB_MOD_MOTION() );
                }
                $event->x( ( ord $bytes[4] ) - 1 - 32 );
                $event->y( ( ord $bytes[5] ) - 1 - 32 );
                #
                $s->_unused_data( join '', @bytes[ 7 .. -1 ] );    # break off six chars
                return $event;
            }
            elsif ( $s->_unused_data() =~ m[^\033\[<?(\d+);(\d+);(\d+)(M)]i ) {

                # xterm 1006 extended mode or urxvt 1015 extended mode
                my $event = Cancer::Event::Mouse->new();
                my $state = 0;

                #die join '', @bytes;
                # left:         0;33;5M0;33;5m
                # right:        2;43;10M2;43;10m
                # middle_click: 1;62;10M
                # middle_up:    64;16;9M64;16;9M
                # middle_down:  65;66;11M
                #ddx $s->_unused_data();
                $event->button(
                    $1 == 0      ? Cancer::Event::TB_KEY_MOUSE_LEFT() :
                        $1 == 2  ? Cancer::Event::TB_KEY_MOUSE_RIGHT() :
                        $1 == 1  ? Cancer::Event::TB_KEY_MOUSE_MIDDLE() :
                        $1 == 64 ? Cancer::Event::TB_KEY_MOUSE_WHEEL_UP() :
                        $1 == 65 ? Cancer::Event::TB_KEY_MOUSE_WHEEL_DOWN() :
                        ()    # Unknown
                );
                $event->x($2);
                $event->y($3);
                $event->mod( $4 eq 'M' ? Cancer::Event::TB_KEY_MOUSE_RELEASE() : Cancer::Event::TB_KEY_MOUSE_RELEASE() );

                #warn $btn;
                #warn length $s->_unused_data();
                $s->write_at( 10, 12, 'before: ' . length( $s->_unused_data() ) . '               ' );
                $s->_unused_data( substr $s->_unused_data(), length $& );
                $s->write_at( 10, 13, 'after: ' . length( $s->_unused_data() ) . '               ' );
                return $event;
            }
        }
        if ( $bytes[0] =~ m[[[:print:]]] ) {
            $s->_unused_data( substr $s->_unused_data(), 1 );
            return Cancer::Event::Key->new( glyph => $bytes[0] );
            die 'printable character!';
        }
        else {
            $s->_unused_data( substr $s->_unused_data(), 1 );
            $s->write_at( 10, 15, 'char:   ' . Data::Dump::pp( \@bytes ) . '               ' );
            $s->write_at( 10, 16, 'unpack: ' . Data::Dump::pp( unpack 'C*', join '', @bytes ) . '               ' );
            return Cancer::Event::Key->new( glyph => join '', @bytes );
        }
        ();
    }

    sub get_win_size ($s) {

        #use Data::Dump;
        #ddx \@_;
        my $w = "\0" x 8;
        $s->tty // Carp::confess 'WHAT?';
        ioctl( $s->tty, $s->TIOCGWINSZ(), $w );
        my ( $rows, $cols ) = unpack 'S2', $w;    # rows, cols, pix_x, pix_y
        $rows //= $ENV{LINES};
        $cols //= $ENV{COLUMNS};
        return ( $rows, $cols );

        #Fallback: split ' ', qx[stty size </dev/tty 2>/dev/null];
    }

    sub resize ($s) {

        # Force the terminal to a new size
    }





    sub draw_cell ( $s, $x, $y ) {

        #ddx $s->cells;
        my $cell = $s->cells->[$x]->[$y];
        $cell->dirty || return;

        #define SetCursor       => "\x1b[%i%p1%d;%p2%dH";
        #my $SetCursor =  "\x1b[%d;%dH";
        syswrite $s->tty, sprintf( $s->SetCursor, $x, $y ) . $cell->chr;

        #ddx $cell;
        #die;
    }
    has title => (
        is      => 'rw',
        isa     => Str,
        trigger => sub ( $s, $title ) {
            syswrite $s->tty, sprintf( "\033]0;%s\007\n", $title );
        },
        predicate => 1
    );

    sub clear_buffer ($s) {
    }    # Clears the internal buffer using TB_DEFAULT or the default_bg and default_fg
    has [qw[default_bg default_fg]] => ( is => 'rw', isa => Int, default => Cancer::Colors::TB_DEFAULT() );



=pod

=begin todo

has terminfo; # TODO:       has h   (isa => Int, default => $ENV{LINES}  //0);
 has w   (isa => Int, default => $ENV{COLUMNS}//0);      has done(isa => Bool);
     #       has tty(isa => FileHandle, is => rw );      has buffering (isa =>
Bool ); # True if we are collecting writes to a buffer instead of sending
directly        has buffer(isa => Maybe[Str]);      #       has curstyle (isa
=> InstanceOf['Cancer::Style']);      has style(isa =>
InstanceOf['Cancer::Style']);

		# Events
		has evch (isa => InstanceOf['Cancer::Event']);
		has sigwinch (isa => CodeRef);
		#
		has quit ( isa => HashRef );
		#has indoneq # No idea what this is
		has keyexist ( isa => HashRef[Bool] );
		has keycodes ( isa => HashRef[Str] );
		has keychan  ( isa => Str); # NFI
		has keytimer; # TODO: I need to write a timeout system :| 50ms default
		has keyexpire ( isa => Int);
		#
		has cx (isa => Int);
		has cy (isa => Int);
		has mouse;
		#
		has clear (isa => Bool);
		#
		has cursorx (isa => Int);
		has cursory (isa => Int);
		#
		has tiosp; # Private Termios; NFI
		has wasbtn (isa => Bool);
		# Encoding
		has acs (isa => HashRef[Str]); # HashRef[Rune]
		has charset (isa => Str, default => 'UTF-8');
		has encoder; # TODO: Encoder for wide charset
		has decoder; # TODO: Decoder for wide charset
		has fallback (isa => HashRef[Str]); # If encoder/decoder fails
		#
		has colors (isa => HashRef[Int]);
		has palette(isa => ArrayRef[Int]);
		has truecolor ( isa => Bool, default => ($ENV{CANCER_TRUECOLOR}//'') eq 'disable' ? 0 : 1 );
		has escaped (isa => Bool);
		has buttondn (isa => Bool);

		#
        method DEMOLISH {
            #warn 'DEMOLISH';
        }
        after new() {
            warn 'NEW!';
            ddx \@_;
            ddx $self;
        }
        method tick( Int $width, Int $height) {
            warn 'hey!';
            $self;
        };
        method init() {
        }
        method finish() { }
        #method clear() { }
        method fill( Char $rune, Style $style) { }
        method set_cell( Int $x, Int $y, Style $style, Char $rune) { }
        method get_content( Int $x, Int $y) {...}
        method set_content( Int $x, Int $y, Str $rune, ArrayRef[Str] $runes, Style $style) { }
        method set_style( Style $style) { }
        method show_cursor( Int $x, Int $y) { }
        method hide_cursor() { }
        method size() { }
        method poll_event() { }
        method post_event( Event $ev) { }
        method post_event_wait( Event $ev) { }
        method enable_mouse() { }
        method disable_mouse() { }
        method has_mouse() { }
        #method colors() { }
        method show() { }
        method sync() { }
        #method character_set() { }
        method register_rune_fallback( Rune $r, Str $subst) { }
        method unregister_rune_fallback( Rune $r) { }
        method can_display( Rune $r, Bool $check_fallbacks) { }
        method resize( Int $x, Int $y, Int $w, Int $h) { }
        method has_key( Key $key) { }
        method beep() { }

=end todo

=cut

};
1;

=encoding utf-8

=head1 NAME

Cancer - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;

=head1 DESCRIPTION

Cancer is a text-based UI library inspired by L<termbox-go|https://github.com/nsf/termbox-go>. Use it to create
L<TUI|https://en.wikipedia.org/wiki/Text-based_user_interface> in pure perl.

=head1 Functions

Cancer is needlessly object oriented so you'll need the following constructor first...

=head2 C<new( [...] )>

    my $term = Cancer->new( '/dev/ttyS06' ); # Don't do this

Creates a new Cancer object.

The optional parameter is the tty you'd like to bind to and defaults to C</dev/tty>.

All setup is automatically done for your platform. This constructor will croak on failure (such as not being in a
supported terminal).

=head2 C<hide_cursor( )>

=head2 C<show_cursor( )>


=head2 C<mouse( [...] )>

	$term->mouse;

Returns a boolean value. True if the mouse is enabled.

	$term->mouse( 1 );

Enable the mouse.

	$term->mouse( 0 );

Disable the mouse.

=head2 C<cls( )>

Immediatly clears the screen.

=head2 C<render( )>

Syncronizes the internal back buffer with the terminal. ...it makes things show up on screen.

=head2 C<title( $title )>

Immediatly sets the terminal's title.

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
