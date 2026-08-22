use v5.42;
use warnings;

package Cancer::Term::Unix v0.0.1 {
    use Carp qw[croak];
    use Cancer::Term::State;

    # termios struct layouts per platform
    #
    # tcflag_t is a 32-bit "unsigned int" on Linux and the BSDs but a 64-bit
    # "unsigned long" on Darwin, each field at natural alignment; c_line sits
    # between lflag and c_cc on the SysV-derived layouts. Sizes cover what the
    # kernel copies for TCGETS/TCSETS (TIOCGETA/TIOCSETA).
    my %LAYOUT = (
        linux     => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 17, 'B' ], size => 60 },
        darwin    => { iflag => [ 0, 'Q' ], oflag => [ 8, 'Q' ], cflag => [ 16, 'Q' ], lflag => [ 24, 'Q' ], cc => [ 32, 'B' ], size => 72 },
        freebsd   => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 16, 'B' ], size => 44 },
        openbsd   => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 16, 'B' ], size => 44 },
        netbsd    => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 16, 'B' ], size => 44 },
        dragonfly => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 16, 'B' ], size => 44 },
        solaris   => { iflag => [ 0, 'L' ], oflag => [ 4, 'L' ], cflag => [ 8,  'L' ], lflag => [ 12, 'L' ], cc => [ 17, 'B' ], size => 60 }
    );
    my $L = $LAYOUT{$^O} // $LAYOUT{linux};

    # termios cc indices
    use constant { _VMIN => 6, _VTIME => 5 };

    # Flag bits come in two ABI families covering every supported OS -- SysV
    # derived (linux, solaris) and BSD derived (darwin, *bsd); input/output
    # bits match between them except IXON. Values are from each platform's
    # <sys/termios.h> as captured by Go's generated syscall tables.
    my $bsd_flags = $^O =~ /^(?:darwin|freebsd|openbsd|netbsd|dragonfly)\z/;
    my ( $IGNBRK, $BRKINT, $PARMRK, $ISTRIP, $INLCR, $IGNCR, $ICRNL ) = ( 0x0001, 0x0002, 0x0008, 0x0020, 0x0040, 0x0080, 0x0100 );
    my $IXON  = $bsd_flags ? 0x0200 : 0x0400;
    my $OPOST = 0x0001;
    my ( $ECHO, $ECHONL, $ICANON, $ISIG, $IEXTEN )
        = $bsd_flags ? ( 0x0008, 0x0010, 0x0100, 0x0080, 0x0400 ) : ( 0x0008, 0x0040, 0x0002, 0x0001, 0x8000 );
    my ( $CSIZE, $PARENB, $CS8 ) = $bsd_flags ? ( 0x0300, 0x1000, 0x0300 ) : ( 0x0030, 0x0100, 0x0030 );

    # ioctl numbers
    my ( $IOCTL_READ, $IOCTL_WRITE, $IOCTL_WINSZ );
    if ( $^O =~ /^(darwin|freebsd|openbsd|netbsd|dragonfly)$/ ) {
        $IOCTL_READ  = 0x40247413;    # TIOCGETA
        $IOCTL_WRITE = 0x80247414;    # TIOCSETA
        $IOCTL_WINSZ = 0x40087468;    # TIOCGWINSZ
    }
    else {
        $IOCTL_READ  = 0x5401;        # TCGETS
        $IOCTL_WRITE = 0x5402;        # TCSETS
        $IOCTL_WINSZ = 0x5413;        # TIOCGWINSZ
    }

    # Perl's ioctl() truncates the SV's string length to the syscall return value. On Linux, TCGETS returns 0 on success, zeroing the buffer. We
    # work around this on Linux by calling ioctl via syscall() which doesn't touch the SV. On BSD/macOS, ioctl returns 1 so Perl doesn't truncate.
    my $USE_SYSCALL;
    my $SYS_IOCTL;
    if ( $^O eq 'linux' ) {

        # Prefer the kernel-provided number from syscall.ph (via h2ph) when it
        # is available; fall back to the well-known per-arch numbers otherwise.
        my $ok = eval {
            require 'syscall.ph';
            defined &main::SYS_ioctl ? 1 : 0;
        };
        if ( $ok && &main::SYS_ioctl ) {
            $SYS_IOCTL = int(&main::SYS_ioctl);
        }
        else {
            require Config;
            my $arch = $Config::Config{archname} // '';
            if    ( $arch =~ /x86_64/ )  { $SYS_IOCTL = 16 }
            elsif ( $arch =~ /aarch64/ ) { $SYS_IOCTL = 29 }
            else                         { $SYS_IOCTL = 54 }    # i386, arm, etc.
        }
        $USE_SYSCALL = 1;
    }

    sub _open_fd ($fd) {
        my $fh;
        return open( $fh, "<&=", $fd ) ? $fh : undef;
    }

    sub _read_termios ($fd) {
        my $buf = "\0" x $L->{size};
        my $ok;
        if ($USE_SYSCALL) {
            my $ret = syscall( $SYS_IOCTL, $fd, $IOCTL_READ, $buf );
            $ok = defined $ret && $ret == 0;
        }
        else {
            my $fh = _open_fd($fd) or return undef;
            $ok = ioctl( $fh, $IOCTL_READ, $buf );
            close $fh;
        }
        return undef unless $ok;
        vec( $buf, $L->{size} - 1, 8 ) = 0 if length($buf) < $L->{size};
        return $buf;
    }

    sub _write_termios ( $fd, $buf ) {
        if ($USE_SYSCALL) {
            my $ret = syscall( $SYS_IOCTL, $fd, $IOCTL_WRITE, $buf );
            return defined $ret && $ret == 0;
        }
        else {
            my $fh = _open_fd($fd) or return undef;
            my $ok = ioctl( $fh, $IOCTL_WRITE, $buf );
            close $fh;
            return $ok;
        }
    }

    sub _t_get ( $buf, $field ) {
        my ( $off, $type ) = @{ $L->{$field} };
        return
            $type eq 'S' ? unpack( 'S', substr( $buf, $off, 2 ) ) :
            $type eq 'L' ?
            unpack( 'L', substr( $buf, $off, 4 ) ) :
            unpack( 'C', substr( $buf, $off, 1 ) );
    }

    # Field setters mutate their first argument in place (callers pass the
    # working buffer by value otherwise) and also return it for chaining.
    # Signatureless on purpose: @_ aliasing is the mutation mechanism, and a
    # signature would both copy $buf and trip the experimental-@_ warning.
    sub _t_set {
        my ( $off, $type ) = @{ $L->{ $_[1] } };
        if    ( $type eq 'S' ) { substr( $_[0], $off, 2 ) = pack( 'S', $_[2] ) }
        elsif ( $type eq 'L' ) { substr( $_[0], $off, 4 ) = pack( 'L', $_[2] ) }
        else                   { substr( $_[0], $off, 1 ) = pack( 'C', $_[2] ) }
        return $_[0];
    }

    sub _t_cc ( $buf, $idx ) {
        return unpack( 'C', substr( $buf, $L->{cc}[0] + $idx, 1 ) );
    }

    sub _t_set_cc {
        substr( $_[0], $L->{cc}[0] + $_[1], 1 ) = pack( 'C', $_[2] );
        return $_[0];
    }
    #
    sub is_terminal ( $class, $fd ) {
        return defined _read_termios($fd) ? 1 : 0;
    }

    sub get_state ( $class, $fd ) {
        my $buf = _read_termios($fd);
        return defined $buf ? Cancer::Term::State->new( fd => $fd, data => $buf ) : undef;
    }

    sub set_state ( $class, $fd, $state ) {
        return defined $state ? _write_termios( $fd, $state->data ) : 0;
    }

    sub make_raw ( $class, $fd ) {
        my $old = _read_termios($fd);
        return undef if !defined $old;
        my $new = $old;

        # cfmakeraw: clear input flags
        _t_set( $new, 'iflag', _t_get( $new, 'iflag' ) & ~( $IGNBRK | $BRKINT | $PARMRK | $ISTRIP | $INLCR | $IGNCR | $ICRNL | $IXON ) );

        # clear output flags
        _t_set( $new, 'oflag', _t_get( $new, 'oflag' ) & ~$OPOST );

        # clear local flags
        _t_set( $new, 'lflag', _t_get( $new, 'lflag' ) & ~( $ECHO | $ECHONL | $ICANON | $ISIG | $IEXTEN ) );

        # 8-bit, no parity
        my $cf = _t_get( $new, 'cflag' ) & ~( $CSIZE | $PARENB ) | $CS8;
        _t_set( $new, 'cflag', $cf );

        # blocking read, no timeout
        _t_set_cc( $new, _VMIN,  1 );
        _t_set_cc( $new, _VTIME, 0 );
        return _write_termios( $fd, $new ) ? Cancer::Term::State->new( fd => $fd, data => $old ) : undef;
    }

    sub get_size ( $class, $fd ) {
        my $buf = "\0" x 8;
        my $ok;
        if ($USE_SYSCALL) {
            my $ret = syscall( $SYS_IOCTL, $fd, $IOCTL_WINSZ, $buf );
            $ok = defined $ret && $ret == 0;
        }
        else {
            my $fh = _open_fd($fd) or return ();
            $ok = ioctl( $fh, $IOCTL_WINSZ, $buf );
            close $fh;
        }
        return $ok ? ( unpack( 'S', substr( $buf, 2, 2 ) ), unpack( 'S', substr( $buf, 0, 2 ) ) ) : ();
    }

    sub read_password ( $class, $fd ) {
        my $old = _read_termios($fd);
        return undef if !defined $old;

        # Disable echo, enable canonical + signals + CR-to-NL
        my $new = $old;
        _t_set( $new, 'lflag', _t_get( $new, 'lflag' ) & ~$ECHO | ( $ICANON | $ISIG ) );
        _t_set( $new, 'iflag', _t_get( $new, 'iflag' ) | $ICRNL );
        _write_termios( $fd, $new );

        # Read line, restore on completion
        my $pass = eval {
            open( my $fh, "<&=$fd" ) or return undef;
            _read_password_line($fh);
        };
        _write_termios( $fd, $old );
        return $pass;
    }

    # readPasswordLine (ported from Go util.go)
    sub _read_password_line ($reader) {
        my @ret;
        while ( sysread( $reader, my $byte, 1 ) ) {
            if ( $byte eq "\x08" ) {    # backspace
                pop @ret if @ret;
            }
            elsif ( $byte eq "\n" ) {
                last;                   # \n = enter on Unix
            }
            elsif ( $byte eq "\r" ) {
                next;                   # ignore \r on Unix
            }
            else {
                push @ret, $byte;
            }
        }
        return join( '', @ret );
    }
}
1;
