use v5.42;

package Cancer::ColorProfile v0.0.1 {
    use Exporter     qw[import];
    use Cancer::Util qw[_max _to6cube _dist_sq];
    our %EXPORT_TAGS = (
        constants => [qw[Unknown NoTTY ASCII ANSI ANSI256 TrueColor]],
        all       => [
            our @EXPORT_OK
                = qw[
                Unknown NoTTY ASCII ANSI ANSI256 TrueColor
                Detect Env Profile_String Convert
                force_color
                ]
        ]
    );
    use constant { Unknown => 0, NoTTY => 1, ASCII => 2, ANSI => 3, ANSI256 => 4, TrueColor => 5 };

    # ansi256 to 16 color mapping table
    my @ANSI256_TO_16 = (
        0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 0,  4,  4,  4,  12, 12, 2,  6,  4,  4,  12, 12, 2,  2,  6,  4,
        12, 12, 2,  2,  2,  6,  12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10, 14, 1,  5,  4,  4,  12, 12, 3,  8,  4,  4,  12, 12,
        2,  2,  6,  4,  12, 12, 2,  2,  2,  6,  12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10, 14, 1,  1,  5,  4,  12, 12, 1,  1,
        5,  4,  12, 12, 3,  3,  8,  4,  12, 12, 2,  2,  2,  6,  12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10, 14, 1,  1,  1,  5,
        12, 12, 1,  1,  1,  5,  12, 12, 1,  1,  1,  5,  12, 12, 3,  3,  3,  7,  12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10, 14,
        9,  9,  9,  9,  13, 12, 9,  9,  9,  9,  13, 12, 9,  9,  9,  9,  13, 12, 9,  9,  9,  9,  13, 12, 11, 11, 11, 11, 7,  12, 10, 10,
        10, 10, 10, 14, 9,  9,  9,  9,  9,  13, 9,  9,  9,  9,  9,  13, 9,  9,  9,  9,  9,  13, 9,  9,  9,  9,  9,  13, 9,  9,  9,  9,
        9,  13, 11, 11, 11, 11, 11, 15, 0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  7,  7,  7,  7,  7,  7,  15, 15, 15, 15, 15, 15
    );

    # Conversion cache: profile => { original_color => converted_color }
    my %CACHE;

    sub Profile_String ($p) {
        return 'TrueColor' if $p == TrueColor;
        return 'ANSI256'   if $p == ANSI256;
        return 'ANSI'      if $p == ANSI;
        return 'Ascii'     if $p == ASCII;
        return 'NoTTY'     if $p == NoTTY;
        return 'Unknown';
    }

    sub _cache_key ($color) {
        return '' unless defined $color;
        my $type = $color->{type} // '';
        return "${type}:$color->{code}"                      if $type eq 'basic';
        return "${type}:$color->{index}"                     if $type eq '256';
        return "${type}:$color->{r}:$color->{g}:$color->{b}" if $type eq 'rgb';
        return '';
    }

    # Convert a color hashref to one supported by the given profile.
    # Color types: {type=>'basic', code=>0..15}, {type=>'256', index=>0..255},
    #              {type=>'rgb', r=>0..255, g=>0..255, b=>0..256}
    # Returns undef (nil) for profiles that strip all color.
    sub Convert ( $profile, $color ) {
        return undef  if $profile <= ASCII;
        return $color if $profile == TrueColor;    # passthrough
        my $key = _cache_key($color);

        # Check cache
        return $CACHE{$profile}{$key} if $key ne '' && exists $CACHE{$profile} && exists $CACHE{$profile}{$key};
        #
        my $converted = _do_convert( $profile, $color );

        # Cache the result
        $CACHE{$profile}{$key} = $converted if defined $converted && $key ne '' && $profile != TrueColor;
        return $converted;
    }

    sub _do_convert ( $profile, $color ) {
        return undef unless defined $color;
        my $type = $color->{type};
        if ( $type eq 'basic' ) {
            return $color;    # basic colors pass through
        }
        if ( $type eq '256' ) {
            if ( $profile == ANSI ) {
                return _convert_256_to_16( $color->{index} );
            }
            return $color;    # ANSI256 keeps 256
        }

        # RGB or any other color type - downsample
        if ( $profile == ANSI256 ) {
            return _convert_rgb_to_256($color);
        }
        if ( $profile == ANSI ) {
            return _convert_rgb_to_16($color);
        }
        return $color;
    }

    # Convert 256-color index to 16-color basic
    sub _convert_256_to_16 ($index) {
        $index = 0   if $index < 0;
        $index = 255 if $index > 255;
        return { type => 'basic', code => $ANSI256_TO_16[$index] };
    }

    # Convert RGB to 256-color index
    sub _convert_rgb_to_256 ($color) {
        my ( $r, $g, $b ) = ( $color->{r} // 0, $color->{g} // 0, $color->{b} // 0 );
        return { type => '256', index => _rgb_to_256( $r, $g, $b ) };
    }

    # Convert RGB to 16-color basic (via 256 intermediate)
    sub _convert_rgb_to_16 ($color) {
        my $idx = _rgb_to_256( $color->{r} // 0, $color->{g} // 0, $color->{b} // 0 );
        return { type => 'basic', code => $ANSI256_TO_16[$idx] };
    }

    # RGB to xterm-256 index
    sub _rgb_to_256 ( $r, $g, $b ) {
        my @q2c = ( 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff );
        my $qr  = _to6cube($r);
        my $cr  = $q2c[$qr];
        my $qg  = _to6cube($g);
        my $cg  = $q2c[$qg];
        my $qb  = _to6cube($b);
        my $cb  = $q2c[$qb];
        my $ci  = 36 * $qr + 6 * $qg + $qb;
        return 16 + $ci if $cr == $r && $cg == $g && $cb == $b;
        my $grey_avg = int( ( $r + $g + $b ) / 3 );
        my $grey_idx = $grey_avg > 238 ? 23 : int( ( $grey_avg - 3 ) / 10 );
        my $grey     = 8 + 10 * $grey_idx;
        return 16 + $ci if _dist_sq( $cr, $cg, $cb, $r, $g, $b ) <= _dist_sq( $grey, $grey, $grey, $r, $g, $b );
        return 232 + $grey_idx;
    }

    # Detect profile from a writer/filehandle and environment.
    # In Perl, we use %ENV directly (unlike Go which passes []string).
    sub Detect {
        my $output  = shift;
        my $environ = @_ ? shift : \%ENV;
        my $isatty  = is_tty_forced($environ) || force_color($environ) || _is_tty($output);
        my $term    = $environ->{TERM} // '';
        my $is_dumb = ( $term eq '' || $term eq 'dumb' );
        my $envp    = _color_profile( $isatty, $environ );
        if ( $envp == TrueColor || env_no_color($environ) ) {
            return $envp;
        }
        if ( $isatty && !$is_dumb ) {
            my $tip   = Terminfo($term);
            my $tmuxp = _tmux($environ);
            return _max( $envp, _max( $tip, $tmuxp ) );
        }
        return $envp;
    }

    # Detect profile purely from environment variables (assumes isatty).
    sub Env { my $environ = @_ ? shift : \%ENV; return _color_profile( 1, $environ ) }

    sub _color_profile ( $isatty, $environ ) {
        my $term    = $environ->{TERM} // '';
        my $is_dumb = ( ( !defined $environ->{TERM} && $^O ne 'MSWin32' ) || $term eq 'dumb' );
        my $envp    = _env_color_profile($environ);

        # https://force-color.org/ - FORCE_COLOR overrides dumb and non-TTY
        if ( force_color($environ) ) {
            my $p = $envp;
            $p = ANSI  if $p < ANSI;
            $p = $envp if $envp > $p;
            return $p;
        }
        return NoTTY if !$isatty || $is_dumb;
        my $p = $envp;
        if ( env_no_color($environ) ) {
            $p = ASCII if $p > ASCII;
            return $p;
        }
        if ( cli_color_forced($environ) ) {
            $p = ANSI  if $p < ANSI;
            $p = $envp if $envp > $p;
            return $p;
        }
        if ( cli_color($environ) ) {
            $p = ANSI if $isatty && !$is_dumb && $p < ANSI;
        }
        return $p;
    }

    sub _env_color_profile ($environ) {
        my $term = $environ->{TERM} // '';
        my $p;
        if ( $term eq '' || $term eq 'dumb' ) {
            $p = NoTTY;
            if ( $^O eq 'MSWin32' ) {
                my ( $wcp, $ok ) = _windows_color_profile($environ);
                $p = $wcp if $ok;
            }
        }
        else {
            $p = ANSI;
        }

        # Known truecolor terminals
        for my $name (qw[alacritty contour foot ghostty kitty rio st wezterm]) {
            return TrueColor if index( $term, $name ) >= 0;
        }

        # Google Cloud Shell
        return TrueColor if ( ( $environ->{GOOGLE_CLOUD_SHELL} // '' ) eq '1' );

        # tmux/screen
        if ( index( $term, 'tmux' ) == 0 || index( $term, 'screen' ) == 0 ) {
            $p = ANSI256 if $p < ANSI256;
        }

        # xterm variants
        $p = ANSI if $p < ANSI && index( $term, 'xterm' ) == 0;

        # Windows Terminal
        if ( ( $environ->{WT_SESSION} // '' ) ne '' ) {
            return TrueColor;
        }

        # COLORTERM (not for screen/tmux)
        my $ct = lc( $environ->{COLORTERM} // '' );
        if ( ( $ct eq 'truecolor' || $ct eq '24bit' || $ct eq 'yes' || $ct eq 'true' ) &&
            index( $term, 'screen' ) != 0 &&
            index( $term, 'tmux' ) != 0 ) {
            return TrueColor;
        }

        # 256color suffix
        $p = ANSI256 if ( $term =~ /256color$/ && $p < ANSI256 );

        # Direct color
        return TrueColor if $term =~ /direct$/;
        #
        return $p;
    }

    # Windows-specific color profile detection
    sub _windows_color_profile ($environ) {
        return ( TrueColor, 1 ) if ( ( $environ->{ConEmuANSI} // '' ) eq 'ON' );
        if ( $^O eq 'MSWin32' ) {
            my ( $maj, $min, $build ) = _windows_version();
            if ( $build < 10586 || $maj < 10 ) {
                my $ansicon = $environ->{ANSICON} // '';
                if ( length $ansicon ) {
                    my $ver = $environ->{ANSICON_VER} // '0';
                    return ( ANSI256, 1 ) if int($ver) >= 181;
                    return ( ANSI,    1 );
                }
                return ( NoTTY, 1 );
            }
            return ( ANSI256,   1 ) if $build < 14931;
            return ( TrueColor, 1 );
        }
        return ( Unknown, 0 );
    }

    sub _windows_version {
        state $cache //= ();
        if ( !defined $cache ) {
            require Win32;
            my ( undef, $major, $minor, $build ) = Win32::GetOSVersion();
            $cache = [ $major, $minor, $build ];
        }
        return @$cache;

        #state $ver //= `cmd /c ver 2>&1`;
        #if ( $ver =~ /(\d+)\.(\d+)\.(\d+)/ ) {
        #    return ( int($1), int($2), int($3) );
        #}
        #return ( 0, 0, 0 );
    }

    # Detect color profile from terminfo database
    sub Terminfo ($term) {
        return NoTTY if !defined $term || $term eq '' || $term eq 'dumb';
        my $p = ANSI;
        eval {
            require Term::Terminfo;
            my $ti = Term::Terminfo->new($term);

            # Check for Tc or RGB extended boolean capabilities
            my $tc = eval { $ti->getstr('Tc') };
            return TrueColor if defined $tc && $tc ne '';
            my $rgb = eval { $ti->getstr('RGB') };
            return TrueColor if defined $rgb && $rgb ne '';
        };
        return $p;
    }
    #
    sub env_no_color ($environ) {
        my $v = $environ->{NO_COLOR} // '';
        return _parse_bool($v);
    }

    sub cli_color ($environ) {
        return _parse_bool( $environ->{CLICOLOR} // '' );
    }

    sub cli_color_forced ($environ) {
        return _parse_bool( $environ->{CLICOLOR_FORCE} // '' );
    }

    sub is_tty_forced ($environ) {
        return _parse_bool( $environ->{TTY_FORCE} // '' );
    }

    # https://force-color.org/
    # When FORCE_COLOR is present and non-empty, force ANSI color regardless of NO_COLOR or TTY state.
    # Unlike _parse_bool, FORCE_COLOR=0 still counts as forced.
    sub force_color ($environ) {
        return 0 if !exists $environ->{FORCE_COLOR};
        return 0 if $environ->{FORCE_COLOR} eq '';
        return 1;
    }

    sub _parse_bool ($v) {
        return 0 if !defined $v || $v eq '';
        return 1 if $v eq '1' || lc($v) eq 'true' || lc($v) eq 'yes';
        return 0;
    }

    sub _is_tty ($fh) {
        return 0 unless defined $fh;
        if ( ref $fh eq 'GLOB' ) {
            return -t $fh;
        }
        if ( ref $fh && $fh->can('fileno') ) {
            my $fd = $fh->fileno;
            return 0 unless defined $fd && $fd >= 0;
            return -t $fh;
        }
        return 0;
    }

    sub _tmux ($environ) {
        my $tmux = $environ->{TMUX} // '';
        return NoTTY if $tmux eq '';
        my $p = ANSI256;
        eval {
            require IPC::Open3;
            my ( $child_out, $child_in, $child_err );
            my $pid = IPC::Open3::open3( $child_in, $child_out, $child_err, 'tmux', 'info' );
            local $/;
            my $out = <$child_out>;
            close $child_out;
            close $child_in;
            close $child_err if defined $child_err;
            waitpid( $pid, 0 );

            for my $line ( split /\n/, $out // '' ) {
                if ( ( index( $line, 'Tc' ) >= 0 || index( $line, 'RGB' ) >= 0 ) && index( $line, 'true' ) >= 0 ) {
                    $p = TrueColor;
                    last;
                }
            }
        };
        return $p;
    }
};
#
1;
