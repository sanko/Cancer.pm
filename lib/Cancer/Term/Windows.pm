use v5.42;
use warnings;

package Cancer::Term::Windows v0.0.1 {
    use Carp qw[croak];
    use Cancer::Term::State;

    # Win32 console mode constants
    use constant {
        _ENABLE_ECHO_INPUT             => 0x0004,
        _ENABLE_LINE_INPUT             => 0x0002,
        _ENABLE_PROCESSED_INPUT        => 0x0001,
        _ENABLE_PROCESSED_OUTPUT       => 0x0001,
        _ENABLE_VIRTUAL_TERMINAL_INPUT => 0x0200
    };

    # Import Win32 API functions via Win32::API
    require Win32::API;
    Win32::API->Import( 'msvcrt',   'long _get_osfhandle(int fd)' )                       or croak 'Cannot import _get_osfhandle';
    Win32::API->Import( 'kernel32', 'int GetConsoleMode(int h, int *mode)' )              or croak 'Cannot import GetConsoleMode';
    Win32::API->Import( 'kernel32', 'int SetConsoleMode(int h, int mode)' )               or croak 'Cannot import SetConsoleMode';
    Win32::API->Import( 'kernel32', 'int GetConsoleScreenBufferInfo(int h, void *info)' ) or croak 'Cannot import GetConsoleScreenBufferInfo';

    # --- Helpers ---------------------------------------------------------------
    sub _handle ($fd) {
        my $h = _get_osfhandle($fd);
        return if $h == -1;    # _get_osfhandle returns -1 on error
        return $h;
    }

    sub _get_console_mode ($handle) {
        my $mode = pack( 'L', 0 );
        return GetConsoleMode( $handle, $mode ) ? unpack( 'L', $mode ) : undef;
    }

    sub _set_console_mode ( $handle, $mode ) {
        return SetConsoleMode( $handle, $mode );
    }

    # --- Public API -----------------------------------------------------------
    sub is_terminal ( $class, $fd ) {
        my $h = _handle($fd) // return 0;
        return defined _get_console_mode($h) ? 1 : 0;
    }

    sub get_state ( $class, $fd ) {
        my $h    = _handle($fd) // return undef;
        my $mode = _get_console_mode($h);
        return defined $mode ? Cancer::Term::State->new( fd => $fd, data => $mode ) : undef;
    }

    sub set_state ( $class, $fd, $state ) {
        return 0 if !defined $state;
        my $h = _handle($fd) // return 0;
        return _set_console_mode( $h, $state->data );
    }

    sub make_raw ( $class, $fd ) {
        my $old = $class->get_state($fd) or return undef;
        my $raw = $old->data & ~( _ENABLE_ECHO_INPUT | _ENABLE_PROCESSED_INPUT | _ENABLE_LINE_INPUT );
        $raw |= _ENABLE_VIRTUAL_TERMINAL_INPUT;
        my $h = _handle($fd) // return undef;
        return _set_console_mode( $h, $raw ) ? $old : undef;
    }

    sub get_size ( $class, $fd ) {
        my $h = _handle($fd) // return ();

        # CONSOLE_SCREEN_BUFFER_INFO: 22 bytes
        #   COORD dwSize (4) + COORD dwCursorPos (4) + WORD wAttr (2)
        #   + SMALL_RECT srWindow (8) + COORD dwMaxSize (4)
        my $buf = "\0" x 22;
        return () if !GetConsoleScreenBufferInfo( $h, $buf );
        my @win = unpack( 'vvvv', substr( $buf, 10, 8 ) );
        return ( $win[2] - $win[0] + 1, $win[3] - $win[1] + 1 );
    }

    sub read_password ( $class, $fd ) {
        my $old = $class->get_state($fd) or return undef;
        my $new = $old->data & ~( _ENABLE_ECHO_INPUT | _ENABLE_LINE_INPUT );
        $new |= ( _ENABLE_PROCESSED_OUTPUT | _ENABLE_PROCESSED_INPUT );
        my $h = _handle($fd) // return undef;
        _set_console_mode( $h, $new );
        my $pass = eval {
            my $fh;
            open( $fh, "<&=$fd" ) or return undef;
            _read_password_line($fh);
        };
        _set_console_mode( $h, $old->data );
        return $pass;
    }

    # --- readPasswordLine (ported from Go util.go) ----------------------------
    sub _read_password_line ($reader) {
        my @ret;
        while ( sysread( $reader, my $byte, 1 ) ) {
            if ( $byte eq "\x08" ) {    # backspace
                pop @ret if @ret;
            }
            elsif ( $byte eq "\r" ) {
                last;                   # \r = enter on Windows
            }
            elsif ( $byte eq "\n" ) {
                next;                   # ignore \n on Windows
            }
            else {
                push @ret, $byte;
            }
        }
        return join( '', @ret );
    }
}
1;
