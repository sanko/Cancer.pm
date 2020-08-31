package Cancer 1.0 {
    use strictures 2;
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    use POSIX qw[:termios_h];
    use IO::Select;
    use Carp qw[];
    #
    use Moo;
    use Types::Standard qw[ArrayRef Bool CodeRef Enum HashRef FileHandle InstanceOf Int Num Str];
    use experimental 'signatures';
    use Role::Tiny qw[];
    #
    use Cancer::Cell;
    use Cancer::Colors;
    use Cancer::terminfo;
    #
    has term => ( is => 'ro', isa => Str, default => '/dev/tty' );
    has tty  => (
        is        => 'ro',
        isa       => FileHandle,
        required  => 1,
        predicate => 1,

        #lazy      => 1,
        builder => sub ($s) {
            Carp::confess 'Not a terminal.' unless -t 1;
            Carp::confess "Cannot open /dev/tty: $!"
                unless sysopen my $tty_fh, $s->term, O_RDWR | O_NDELAY | O_NOCTTY;
            $tty_fh;
        }
    );

    # Store these and restore them on destruction
    CORE::state( $cflag, $iflag, $oflag, $lflag );
    has [qw[cflag iflag oflag lflag]] => ( is => 'rw', isa => Int, predicate => 1 );

    sub BUILD ( $s, $args ) {
        Role::Tiny->apply_roles_to_object( $s, join '::', 'Cancer', 'terminfo', split '-',
            $ENV{TERM} );
        #
        my $fileno = fileno( $s->tty );

        # Keep an original copy
        my $raw = POSIX::Termios->new();
        $raw->getattr($fileno);

        # backup
        $s->cflag( $raw->getcflag ) if !$s->has_cflag;
        $s->iflag( $raw->getiflag ) if !$s->has_iflag;
        $s->oflag( $raw->getoflag ) if !$s->has_oflag;
        $s->lflag( $raw->getlflag ) if !$s->has_lflag;

        # CORE::state
        $cflag //= $raw->getcflag;
        $iflag //= $raw->getiflag;
        $oflag //= $raw->getoflag;
        $lflag //= $raw->getlflag;

        # https://man7.org/linux/man-pages/man3/termios.3.html
        $iflag = $iflag & ~( IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON );
        $raw->setiflag($iflag);
        $oflag = $oflag & ~OPOST;    # Disables post-processing output. Like turning \n into \r\n
        $raw->setoflag($oflag);
        $lflag = $lflag & ~( ECHO | ECHONL | ICANON | ISIG | IEXTEN );
        $raw->setlflag($lflag);
        $cflag = $cflag & ~( CSIZE | PARENB );
        $cflag |= CS8;
        $raw->setcflag($cflag);

        # This is setup for blocking reads.  In the past we attempted to
        # use non-blocking reads, but now a separate input loop and timer
        # copes with the problems we had on some systems (BSD/Darwin)
        # where close hung forever.
        $raw->setcc( VMIN,  1 );
        $raw->setcc( VTIME, 0 );
        #
        $s->sig_winch( $SIG{WINCH} ) if $SIG{WINCH};
        $SIG{WINCH} = sub {
            $s->sig_winch->() if $s->has_sig_winch;
            my ( $rows, $cols ) = $s->get_win_size();
            $s->winch_event( Cancer::Event::Resize->new( w => $cols, h => $rows ) );
            $s;
        };
        $SIG{WINCH}->();
        $raw->setattr( $fileno, TCSANOW );
        #
        # Todo: If the user's platform exists, load it
        Role::Tiny->apply_roles_to_object( $s, 'Cancer::Platform::Windows' ) if $^O eq 'MSWin32';

        # Todo: If the user has AnyEvnet, POE, or IO::Async loaded, use them
        Role::Tiny->apply_roles_to_object( $s, 'Cancer::IO::Select' );
    }

    sub DEMOLISH ( $s, $global = 0 )
    {    # TODO: Reset everything else we've done so far like enable mouse
        return        if !$s->has_tty;
        $s->title('') if $s->has_title();
        $s->mouse(0)  if $s->mouse;
        #
        my $fileno = fileno( $s->tty );

        # Restore original copy
        my $raw = POSIX::Termios->new();
        $raw->getattr($fileno);
        $raw->setcflag( $s->cflag ) if $s->has_cflag;
        $raw->setiflag( $s->iflag ) if $s->has_iflag;
        $raw->setoflag( $s->oflag ) if $s->has_oflag;
        $raw->setlflag( $s->lflag ) if $s->has_lflag;
        #
        $raw->setattr( $fileno, TCSANOW );

        #$s
        $SIG{WINCH} = $s->sig_winch if $s->has_sig_winch;    # Restore original winch
        close $s->tty;
    }
    has [qw[back_buffer front_buffer]] => (
        is  => 'ro',
        isa => InstanceOf ['Cancer::Buffer'],
        #
        #        #required => 1,
        lazy    => 1,
        builder => sub ($s) {
            Cancer::Buffer->new( width => $s->width, height => $s->height );
        }
    );
    has cells => (
        is      => 'rwp',
        isa     => ArrayRef [ ArrayRef [ InstanceOf ['Cancer::Cell'] ] ],
        lazy    => 1,
        builder => sub($s) {
            [   map {
                    [ map { Cancer::Cell->new() } 1 .. $s->width ]
                } 1 .. $s->height
            ]
        }
    );

    # Resize
    has winch_event => (
        is        => 'rw',
        isa       => InstanceOf ['Cancer::Event'],
        lazy      => 1,
        predicate => 1,
        clearer   => 1
    );
    has sig_winch => ( is => 'rwp', isa => CodeRef, lazy => 1, predicate => 1 );
    has [qw[width height]] => ( is => 'ro', isa => Int, lazy => 1, builder => 1, clearer => 1 );

    sub _build_width ($s) {
        my ( undef, $width ) = $s->get_win_size;
        $width;
    }

    sub _build_height ($s) {
        my ( $height, undef ) = $s->get_win_size;
        $height;
    }

    sub raw_write ( $s, $data ) {
        $s->front_buffer->data( $s->front_buffer->data . $data );
    }

=head2 C<hide_cursor( )>


=cut

    sub hide_cursor($s) {
        syswrite $s->tty, "\e[?25l"    # immediate
    }

=head2 C<show_cursor( )>


=cut

    sub show_cursor($s) {
        syswrite $s->tty, "\e[0H\e[0J\e[?25h"    # immediate
    }

=head2 C<mouse( [...] )>

	$term->mouse;

Returns a boolean value. True if the mouse is enabled.

	$term->mouse( 1 );

Enable the mouse.

	$term->mouse( 0 );

Disable the mouse.

=cut

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

    sub clear_screen($s) {
        $s->front_buffer->data( $s->front_buffer->data . "\033[2J\033[" . $s->height . ";3H" );
    }

    #has color_mode => ();
    sub out ( $s, $string ) {    # Red and blinking
        my $fg = 0xE6E6FA;
        my $bg = 0xEE82EE;
        $s->front_buffer->data( $s->front_buffer->data . "\e[38;2;" );
        $s->front_buffer->data( $s->front_buffer->data . ( $fg >> 16 & 0xFF ) );    # fg R
        $s->front_buffer->data( $s->front_buffer->data . ';' );
        $s->front_buffer->data( $s->front_buffer->data . ( $fg >> 8 & 0xFF ) );     # fg G
        $s->front_buffer->data( $s->front_buffer->data . ';' );
        $s->front_buffer->data( $s->front_buffer->data . ( $fg & 0xFF ) );          # fg B
        $s->front_buffer->data( $s->front_buffer->data . 'm' );
        $s->front_buffer->data( $s->front_buffer->data . "\e[48;2;" );
        $s->front_buffer->data( $s->front_buffer->data . ( $bg >> 16 & 0xFF ) );    # bg R
        $s->front_buffer->data( $s->front_buffer->data . ';' );
        $s->front_buffer->data( $s->front_buffer->data . ( $bg >> 8 & 0xFF ) );     # bg B
        $s->front_buffer->data( $s->front_buffer->data . ';' );
        $s->front_buffer->data( $s->front_buffer->data . ( $bg & 0xFF ) );          #bg G

        #$s->front_buffer->data( $s->front_buffer->data .  '')
        #$s->front_buffer->data( $s->front_buffer->data .  );
        #$s->front_buffer->data( $s->front_buffer->data .  );
        #$s->front_buffer->data( $s->front_buffer->data .  );
        #	// write RGB color to buffer
        #WRITE_INT(fg >> 8 & 0xFF);  // fg G
        #WRITE_LITERAL(";");
        #WRITE_INT(fg & 0xFF);       // fg B
        #WRITE_LITERAL(";48;2;");
        #WRITE_INT(bg >> 16 & 0xFF); // bg R
        #WRITE_LITERAL(";");
        #WRITE_INT(bg >> 8 & 0xFF);  // bg G
        #WRITE_LITERAL(";");
        #WRITE_INT(bg & 0xFF);       // bg B
        $s->front_buffer->data( $s->front_buffer->data . 'm' . $string . "\033[25;0m\n" );
    }
    has _unused_data => ( is => 'rw', isa => Str, default => '', predicate => 1 );


    sub __readURXVT(@bytes) {
        my $c = chr( $_[0] );
        my $str;
        while ( $c ne ';' && $c ne 'M' ) {
            $str .= $c;
            $c = shift @_;
        }
        return $str;
    }

    sub _parseEventsFromInput($s) {
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
                    $event->button( ( ( $b & 64 ) != 0 ) ? Cancer::Event::TB_KEY_MOUSE_WHEEL_UP() :
                            Cancer::Event::TB_KEY_MOUSE_LEFT() );
                }
                elsif ( $match == 1 ) {
                    $event->button(
                        ( ( $b & 64 ) != 0 ) ? Cancer::Event::TB_KEY_MOUSE_WHEEL_DOWN() :
                            Cancer::Event::TB_KEY_MOUSE_MIDDLE() );
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
                $event->mod( $4 eq 'M' ? Cancer::Event::TB_KEY_MOUSE_RELEASE() :
                        Cancer::Event::TB_KEY_MOUSE_RELEASE() );

                #warn $btn;
                #warn length $s->_unused_data();
                $s->write_at( 10, 12,
                    'before: ' . length( $s->_unused_data() ) . '               ' );
                $s->_unused_data( substr $s->_unused_data(), length $& );
                $s->write_at( 10, 13,
                    'after: ' . length( $s->_unused_data() ) . '               ' );
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
            $s->write_at( 10, 16,
                'unpack: ' . Data::Dump::pp( unpack 'C*', join '', @bytes ) . '               ' );
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

    sub resize($s) {

        # Force the terminal to a new size
    }

    sub write_at ( $s, $x, $y, $string ) {
        $s->front_buffer->data( $s->front_buffer->data . sprintf "\033[%d;%dH%s", $y, $x, $string );
        $s->render;
    }

    sub write ( $s, $string ) {
        $s->front_buffer->data( $s->front_buffer->data . $string );
        $s->render;
    }

=head2 C<cls( )>

Immediatly clears the screen.

=cut

    sub cls($s) {
        syswrite $s->tty, $s->Clear;

        #$s->
        #$s->front_buffer->data( $s->front_buffer->data . $s->Clear );
        #$s->render;    # No waiting
    }

=head2 C<render( )>

Syncronizes the internal back buffer with the terminal. ...it makes things show up on screen.

=cut

    sub render($s) {
        my ( $x, $y, $w, $i );
        my $data = '';
        my ( $back, $front );    # = Cell->new();
        for my $y ( 0 .. $s->front_buffer->height ) {
            for my $x ( 0 .. $s->front_buffer->width ) {
            }
        }
        syswrite $s->tty, $s->front_buffer->data;
        $s->front_buffer->data('');    # Clear buffer
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

=head2 C<title( $title )>

Immediatly sets the terminal's title.

=cut

    has title => (
        is      => 'rw',
        isa     => Str,
        trigger => sub ( $s, $title ) {
            syswrite $s->tty, sprintf( "\033]0;%s\007\n", $title );
        },
        predicate => 1
    );

    sub clear_buffer($s) {
    }    # Clears the internal buffer using TB_DEFAULT or the default_bg and default_fg
    has [qw[default_bg default_fg]] =>
        ( is => 'rw', isa => Int, default => Cancer::Colors::TB_DEFAULT() );

    # Platform utils
    sub TIOCGWINSZ($s) {    # See Perl::osnames
        return 0x800c if $^O =~ qr/\A(?:beos)\z/;
        return 0x40087468
            if $^O =~ qr/\A(?:MacOS|iphoneos|bitrig|dragonfly|(free|net|open)bsd|bsdos)\z/;
        return 0x5468 if $^O =~ qr/\A(?:solaris|sunos)\z/;
        return 0x5413       # Linux and android
    }

=cut

has terminfo; # TODO:
		has h   (isa => Int, default => $ENV{LINES}  //0);
		has w   (isa => Int, default => $ENV{COLUMNS}//0);
		has done(isa => Bool);
		#
		has tty(isa => FileHandle, is => rw );
		has buffering (isa => Bool ); # True if we are collecting writes to a buffer instead of sending directly
		has buffer(isa => Maybe[Str]);
		#
		has curstyle (isa => InstanceOf['Cancer::Style']);
		has style(isa => InstanceOf['Cancer::Style']);

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

=cut

};
1;

=encoding utf-8

=head1 NAME

Cancer - Terminal UI Toolkit

=head1 SYNOPSIS

    use Cancer;

=head1 DESCRIPTION

Cancer is ...

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
