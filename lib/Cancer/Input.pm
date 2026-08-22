use v5.42;

package Cancer::Input v0.0.1 {
    use Exporter     qw[import];
    use Encode       qw[encode];
    use MIME::Base64 qw[decode_base64];
    use lib '../../lib';
    use Cancer::Ansi qw[
        MouseNone MouseLeft MouseMiddle MouseRight MouseWheelUp MouseWheelDown MouseWheelLeft
        MouseWheelRight MouseBackward MouseForward MouseButton10 MouseButton11
        SYSTEM_CLIPBOARD PRIMARY_CLIPBOARD x_parse_color
    ];
    use constant {

        # Feature / parser flags
        FLAG_CTRL_AT           => 1 << 0,
        FLAG_CTRL_I            => 1 << 1,
        FLAG_CTRL_M            => 1 << 2,
        FLAG_CTRL_OPEN_BRACKET => 1 << 3,
        FLAG_BACKSPACE         => 1 << 4,
        FLAG_FIND              => 1 << 5,
        FLAG_SELECT            => 1 << 6,
        FLAG_TERMINFO          => 1 << 7,
        FLAG_FKEYS             => 1 << 8,
        FLAG_MOUSE_MODE        => 1 << 9,

        # Modifiers
        MOD_SHIFT       => 1 << 0,
        MOD_ALT         => 1 << 1,
        MOD_CTRL        => 1 << 2,
        MOD_META        => 1 << 3,
        MOD_HYPER       => 1 << 4,
        MOD_SUPER       => 1 << 5,
        MOD_CAPS_LOCK   => 1 << 6,
        MOD_NUM_LOCK    => 1 << 7,
        MOD_SCROLL_LOCK => 1 << 8,

        # Kitty keyboard protocol enhancement flags
        KITTY_DISAMBIGUATE_ESCAPE_CODES       => 1 << 0,
        KITTY_REPORT_EVENT_TYPES              => 1 << 1,
        KITTY_REPORT_ALTERNATE_KEYS           => 1 << 2,
        KITTY_REPORT_ALL_KEYS_AS_ESCAPE_CODES => 1 << 3,
        KITTY_REPORT_ASSOCIATED_TEXT          => 1 << 4,

        # Standard ASCII / C0 keys
        KEY_BACKSPACE => 0x7F,
        KEY_TAB       => 0x09,
        KEY_ENTER     => 0x0D,
        KEY_RETURN    => 0x0D,
        KEY_ESCAPE    => 0x1B,
        KEY_ESC       => 0x1B,
        KEY_SPACE     => 0x20,

        # Mouse button constants
        MOUSE_NONE        => 0,
        MOUSE_LEFT        => 1,
        MOUSE_MIDDLE      => 2,
        MOUSE_RIGHT       => 3,
        MOUSE_WHEEL_UP    => 4,
        MOUSE_WHEEL_DOWN  => 5,
        MOUSE_WHEEL_LEFT  => 6,
        MOUSE_WHEEL_RIGHT => 7,
        MOUSE_BACKWARD    => 8,
        MOUSE_FORWARD     => 9,
        MOUSE_BUTTON10    => 10,
        MOUSE_BUTTON11    => 11,

        # Parsing internals
        PREFIX_SHIFT        => 8,
        INTERMED_SHIFT      => 16,
        FINAL_MASK          => 0xFF,
        HAS_MORE_FLAG       => 0x80000000,
        PARAM_MASK          => 0x7FFFFFFF,
        MISSING_PARAM       => 0x7FFFFFFF,
        MAX_PARAMS_SIZE     => 32,
        MAX_DCS_PARAMS_SIZE => 16,

        # Windows ControlKeyState flags
        CKS_RIGHT_ALT  => 0x001,
        CKS_LEFT_ALT   => 0x002,
        CKS_RIGHT_CTRL => 0x004,
        CKS_LEFT_CTRL  => 0x008,
        CKS_SHIFT      => 0x010,
        CKS_NUMLOCK    => 0x020,
        CKS_SCROLLLOCK => 0x040,
        CKS_CAPSLOCK   => 0x080,
        CKS_ENHANCED   => 0x100,

        # Windows MouseEventRecord button state bits
        BTN_FROM_LEFT_1ST => 0x0001,
        BTN_RIGHTMOST     => 0x0002,
        BTN_FROM_LEFT_2ND => 0x0004,
        BTN_FROM_LEFT_3RD => 0x0008,
        BTN_FROM_LEFT_4TH => 0x0010,

        # Windows MouseEventRecord event flags
        EVF_MOUSE_MOVED  => 0x0001,
        EVF_DOUBLE_CLICK => 0x0002,
        EVF_WHEELED      => 0x0004,
        EVF_HWHEELED     => 0x0008,

        # Extended key codes (KEY_EXTENDED = unicode.MaxRune + 1 = 0x110000)
        KEY_EXTENDED => 0x110000,
        do {
            my $code = 0x110001;
            map { ( "KEY_$_" => $code++ ) } (
                qw[UP DOWN RIGHT LEFT BEGIN FIND INSERT DELETE SELECT PG_UP PG_DOWN HOME END],
                ( map {"KP_$_"} qw[ENTER EQUAL MULTIPLY PLUS COMMA MINUS DECIMAL DIVIDE], 0 .. 9 ),
                ( map {"KP_$_"} qw[SEP UP DOWN LEFT RIGHT PG_UP PG_DOWN HOME END INSERT DELETE BEGIN] ), ( map {"F$_"} 1 .. 63 ),
                qw[CAPS_LOCK SCROLL_LOCK NUM_LOCK PRINT_SCREEN PAUSE MENU],
                qw[MEDIA_PLAY MEDIA_PAUSE MEDIA_PLAY_PAUSE MEDIA_REVERSE MEDIA_STOP MEDIA_FAST_FORWARD MEDIA_REWIND
                    MEDIA_NEXT MEDIA_PREV MEDIA_RECORD], qw[LOWER_VOL RAISE_VOL MUTE], ( map {"LEFT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ),
                ( map {"RIGHT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ), qw[ISO_LEVEL3_SHIFT ISO_LEVEL5_SHIFT]
            );
        }
    };
    my @EXPORTED_CONSTANTS = (
        ( map {"FLAG_$_"} qw[CTRL_AT CTRL_I CTRL_M CTRL_OPEN_BRACKET BACKSPACE FIND SELECT TERMINFO FKEYS MOUSE_MODE] ),
        ( map {"MOD_$_"} qw[SHIFT ALT CTRL META HYPER SUPER CAPS_LOCK NUM_LOCK SCROLL_LOCK] ),
        ( map {"CKS_$_"} qw[RIGHT_ALT LEFT_ALT RIGHT_CTRL LEFT_CTRL SHIFT NUMLOCK SCROLLLOCK CAPSLOCK ENHANCED] ),
        ( map {"BTN_$_"} qw[FROM_LEFT_1ST RIGHTMOST FROM_LEFT_2ND FROM_LEFT_3RD FROM_LEFT_4TH] ),
        ( map {"EVF_$_"} qw[MOUSE_MOVED DOUBLE_CLICK WHEELED HWHEELED] ),
        (
            map {"KITTY_$_"}
                qw[DISAMBIGUATE_ESCAPE_CODES REPORT_EVENT_TYPES REPORT_ALTERNATE_KEYS REPORT_ALL_KEYS_AS_ESCAPE_CODES REPORT_ASSOCIATED_TEXT]
        ),
        qw[KEY_BACKSPACE KEY_TAB KEY_ENTER KEY_RETURN KEY_ESCAPE KEY_ESC KEY_SPACE KEY_EXTENDED], (
            map {"KEY_$_"} (
                qw[UP DOWN RIGHT LEFT BEGIN FIND INSERT DELETE SELECT PG_UP PG_DOWN HOME END],
                ( map {"KP_$_"} qw[ENTER EQUAL MULTIPLY PLUS COMMA MINUS DECIMAL DIVIDE], 0 .. 9 ),
                ( map {"KP_$_"} qw[SEP UP DOWN LEFT RIGHT PG_UP PG_DOWN HOME END INSERT DELETE BEGIN] ),
                ( map {"F$_"} 1 .. 63 ),
                qw[CAPS_LOCK SCROLL_LOCK NUM_LOCK PRINT_SCREEN PAUSE MENU],
                qw[MEDIA_PLAY MEDIA_PAUSE MEDIA_PLAY_PAUSE MEDIA_REVERSE MEDIA_STOP MEDIA_FAST_FORWARD MEDIA_REWIND MEDIA_NEXT MEDIA_PREV MEDIA_RECORD],
                qw[LOWER_VOL RAISE_VOL MUTE],
                ( map {"LEFT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ),
                ( map {"RIGHT_$_"} qw[SHIFT ALT CTRL SUPER HYPER META] ),
                qw[ISO_LEVEL3_SHIFT ISO_LEVEL5_SHIFT]
            )
        ),
        ( map {"MOUSE_$_"} qw[NONE LEFT MIDDLE RIGHT WHEEL_UP WHEEL_DOWN WHEEL_LEFT WHEEL_RIGHT BACKWARD FORWARD BUTTON10 BUTTON11] )
    );
    my @REEXPORT = qw[
        MouseNone MouseLeft MouseMiddle MouseRight MouseWheelUp MouseWheelDown MouseWheelLeft
        MouseWheelRight MouseBackward MouseForward MouseButton10 MouseButton11 SYSTEM_CLIPBOARD PRIMARY_CLIPBOARD
    ];
    our @EXPORT_OK   = ( sort(@EXPORTED_CONSTANTS), @REEXPORT, qw[new_parser build_keys_table new_win32_state] );
    our %EXPORT_TAGS = (
        all   => [@EXPORT_OK],
        flags => [ grep {/^FLAG_/} @EXPORT_OK ],
        mods  => [ grep {/^MOD_/} @EXPORT_OK ],
        keys  => [ grep {/^KEY_/} @EXPORT_OK ],
        kitty => [ grep {/^KITTY_/} @EXPORT_OK ],
        mouse => [ grep {/^MOUSE_|^Mouse/} @EXPORT_OK ]
    );
    my %KEY_TYPE_STRING;

    BEGIN {
        my @pairs = (
            ENTER       => 'enter',
            TAB         => 'tab',
            BACKSPACE   => 'backspace',
            ESCAPE      => 'esc',
            SPACE       => 'space',
            UP          => 'up',
            DOWN        => 'down',
            LEFT        => 'left',
            RIGHT       => 'right',
            BEGIN       => 'begin',
            FIND        => 'find',
            INSERT      => 'insert',
            DELETE      => 'delete',
            SELECT      => 'select',
            PG_UP       => 'pgup',
            PG_DOWN     => 'pgdown',
            HOME        => 'home',
            END         => 'end',
            KP_ENTER    => 'kpenter',
            KP_EQUAL    => 'kpequal',
            KP_MULTIPLY => 'kpmul',
            KP_PLUS     => 'kpplus',
            KP_COMMA    => 'kpcomma',
            KP_MINUS    => 'kpminus',
            KP_DECIMAL  => 'kpperiod',
            KP_DIVIDE   => 'kpdiv',
            ( map { ( "KP_$_", "kp$_" ) } 0 .. 9 ),
            KP_SEP     => 'kpsep',
            KP_UP      => 'kpup',
            KP_DOWN    => 'kpdown',
            KP_LEFT    => 'kpleft',
            KP_RIGHT   => 'kpright',
            KP_PG_UP   => 'kppgup',
            KP_PG_DOWN => 'kppgdown',
            KP_HOME    => 'kphome',
            KP_END     => 'kpend',
            KP_INSERT  => 'kpinsert',
            KP_DELETE  => 'kpdelete',
            KP_BEGIN   => 'kpbegin',
            ( map { ( "F$_", "f$_" ) } 1 .. 63 ),
            CAPS_LOCK          => 'capslock',
            SCROLL_LOCK        => 'scrolllock',
            NUM_LOCK           => 'numlock',
            PRINT_SCREEN       => 'printscreen',
            PAUSE              => 'pause',
            MENU               => 'menu',
            MEDIA_PLAY         => 'mediaplay',
            MEDIA_PAUSE        => 'mediapause',
            MEDIA_PLAY_PAUSE   => 'mediaplaypause',
            MEDIA_REVERSE      => 'mediareverse',
            MEDIA_STOP         => 'mediastop',
            MEDIA_FAST_FORWARD => 'mediafastforward',
            MEDIA_REWIND       => 'mediarewind',
            MEDIA_NEXT         => 'medianext',
            MEDIA_PREV         => 'mediaprev',
            MEDIA_RECORD       => 'mediarecord',
            LOWER_VOL          => 'lowervol',
            RAISE_VOL          => 'raisevol',
            MUTE               => 'mute',
            LEFT_SHIFT         => 'leftshift',
            LEFT_ALT           => 'leftalt',
            LEFT_CTRL          => 'leftctrl',
            LEFT_SUPER         => 'leftsuper',
            LEFT_HYPER         => 'lefthyper',
            LEFT_META          => 'leftmeta',
            RIGHT_SHIFT        => 'rightshift',
            RIGHT_ALT          => 'rightalt',
            RIGHT_CTRL         => 'rightctrl',
            RIGHT_SUPER        => 'rightsuper',
            RIGHT_HYPER        => 'righthyper',
            RIGHT_META         => 'rightmeta',
            ISO_LEVEL3_SHIFT   => 'isolevel3shift',
            ISO_LEVEL5_SHIFT   => 'isolevel5shift'
        );
        for ( my $i = 0; $i < @pairs; $i += 2 ) {
            my $sub = __PACKAGE__->can("KEY_$pairs[$i]");
            $KEY_TYPE_STRING{ $sub->() } = $pairs[ $i + 1 ] if $sub;
        }
    }
    my %KITTY_KEY_MAP;

    BEGIN {
        my %name = (
            0x08  => 'BACKSPACE',
            0x09  => 'TAB',
            0x0D  => 'ENTER',
            0x1B  => 'ESCAPE',
            0x7F  => 'BACKSPACE',
            57344 => 'ESCAPE',
            57345 => 'ENTER',
            57346 => 'TAB',
            57347 => 'BACKSPACE',
            57348 => 'INSERT',
            57349 => 'DELETE',
            57350 => 'LEFT',
            57351 => 'RIGHT',
            57352 => 'UP',
            57353 => 'DOWN',
            57354 => 'PG_UP',
            57355 => 'PG_DOWN',
            57356 => 'HOME',
            57357 => 'END',
            57358 => 'CAPS_LOCK',
            57359 => 'SCROLL_LOCK',
            57360 => 'NUM_LOCK',
            57361 => 'PRINT_SCREEN',
            57362 => 'PAUSE',
            57363 => 'MENU'
        );
        $name{ 57363 + $_ } = "F$_"   for 1 .. 35;
        $name{ 57398 + $_ } = "KP_$_" for 0 .. 9;
        my @tail = (
            57409 => 'KP_DECIMAL',
            57410 => 'KP_DIVIDE',
            57411 => 'KP_MULTIPLY',
            57412 => 'KP_MINUS',
            57413 => 'KP_PLUS',
            57414 => 'KP_ENTER',
            57415 => 'KP_EQUAL',
            57416 => 'KP_SEP',
            57417 => 'KP_LEFT',
            57418 => 'KP_RIGHT',
            57419 => 'KP_UP',
            57420 => 'KP_DOWN',
            57421 => 'KP_PG_UP',
            57422 => 'KP_PG_DOWN',
            57423 => 'KP_HOME',
            57424 => 'KP_END',
            57425 => 'KP_INSERT',
            57426 => 'KP_DELETE',
            57427 => 'KP_BEGIN',
            57428 => 'MEDIA_PLAY',
            57429 => 'MEDIA_PAUSE',
            57430 => 'MEDIA_PLAY_PAUSE',
            57431 => 'MEDIA_REVERSE',
            57432 => 'MEDIA_STOP',
            57433 => 'MEDIA_FAST_FORWARD',
            57434 => 'MEDIA_REWIND',
            57435 => 'MEDIA_NEXT',
            57436 => 'MEDIA_PREV',
            57437 => 'MEDIA_RECORD',
            57438 => 'LOWER_VOL',
            57439 => 'RAISE_VOL',
            57440 => 'MUTE',
            57441 => 'LEFT_SHIFT',
            57442 => 'LEFT_CTRL',
            57443 => 'LEFT_ALT',
            57444 => 'LEFT_SUPER',
            57445 => 'LEFT_HYPER',
            57446 => 'LEFT_META',
            57447 => 'RIGHT_SHIFT',
            57448 => 'RIGHT_CTRL',
            57449 => 'RIGHT_ALT',
            57450 => 'RIGHT_SUPER',
            57451 => 'RIGHT_HYPER',
            57452 => 'RIGHT_META',
            57453 => 'ISO_LEVEL3_SHIFT',
            57454 => 'ISO_LEVEL5_SHIFT'
        );
        $name{ $tail[$_] } = $tail[ $_ + 1 ] for grep { !( $_ % 2 ) } 0 .. $#tail;
        my %map;
        for my $k ( keys %name ) {
            my $sub = __PACKAGE__->can("KEY_$name{$k}");
            $map{$k} = [ $sub ? $sub->() : 0, 0 ];
        }
        $map{0} = [ KEY_SPACE, MOD_CTRL ];
        for my $i ( 1 .. 0x1A )    { $map{$i} //= [ $i + 0x60, MOD_CTRL ] }
        for my $i ( 0x1C .. 0x1F ) { $map{$i} //= [ $i + 0x40, MOD_CTRL ] }
        %KITTY_KEY_MAP = %map;
    }
    my %VK;

    BEGIN {
        %VK = (
            BACK             => 0x08,
            TAB              => 0x09,
            RETURN           => 0x0D,
            SHIFT            => 0x10,
            CONTROL          => 0x11,
            MENU             => 0x12,
            PAUSE            => 0x13,
            CAPITAL          => 0x14,
            ESCAPE           => 0x1B,
            SPACE            => 0x20,
            PRIOR            => 0x21,
            NEXT             => 0x22,
            END              => 0x23,
            HOME             => 0x24,
            LEFT             => 0x25,
            UP               => 0x26,
            RIGHT            => 0x27,
            DOWN             => 0x28,
            SELECT           => 0x29,
            SNAPSHOT         => 0x2C,
            INSERT           => 0x2D,
            DELETE           => 0x2E,
            LWIN             => 0x5B,
            RWIN             => 0x5C,
            APPS             => 0x5D,
            NUMPAD0          => 0x60,
            NUMPAD9          => 0x69,
            MULTIPLY         => 0x6A,
            ADD              => 0x6B,
            SEPARATOR        => 0x6C,
            SUBTRACT         => 0x6D,
            DECIMAL          => 0x6E,
            DIVIDE           => 0x6F,
            F1               => 0x70,
            F24              => 0x87,
            NUMLOCK          => 0x90,
            SCROLL           => 0x91,
            LSHIFT           => 0xA0,
            RSHIFT           => 0xA1,
            LCONTROL         => 0xA2,
            RCONTROL         => 0xA3,
            LMENU            => 0xA4,
            RMENU            => 0xA5,
            VOLUME_MUTE      => 0xAD,
            VOLUME_DOWN      => 0xAE,
            VOLUME_UP        => 0xAF,
            MEDIA_NEXT_TRACK => 0xB0,
            MEDIA_PREV_TRACK => 0xB1,
            MEDIA_STOP       => 0xB2,
            MEDIA_PLAY_PAUSE => 0xB3,
            OEM_1            => 0xBA,
            OEM_PLUS         => 0xBB,
            OEM_COMMA        => 0xBC,
            OEM_MINUS        => 0xBD,
            OEM_PERIOD       => 0xBE,
            OEM_2            => 0xBF,
            OEM_3            => 0xC0,
            OEM_4            => 0xDB,
            OEM_5            => 0xDC,
            OEM_6            => 0xDD,
            OEM_7            => 0xDE
        );
    }
    my @UTF8_RANGES;

    BEGIN {
        @UTF8_RANGES = (
            [ 0xC2, 0xDF, [ [ 0x80, 0xBF ] ] ],
            [ 0xE0, 0xE0, [ [ 0xA0, 0xBF ], [ 0x80, 0xBF ] ] ],
            [ 0xE1, 0xEC, [ [ 0x80, 0xBF ], [ 0x80, 0xBF ] ] ],
            [ 0xED, 0xED, [ [ 0x80, 0x9F ], [ 0x80, 0xBF ] ] ],
            [ 0xEE, 0xEF, [ [ 0x80, 0xBF ], [ 0x80, 0xBF ] ] ],
            [ 0xF0, 0xF0, [ [ 0x90, 0xBF ], [ 0x80, 0xBF ], [ 0x80, 0xBF ] ] ],
            [ 0xF1, 0xF3, [ [ 0x80, 0xBF ], [ 0x80, 0xBF ], [ 0x80, 0xBF ] ] ],
            [ 0xF4, 0xF4, [ [ 0x80, 0x8F ], [ 0x80, 0xBF ], [ 0x80, 0xBF ] ] ]
        );
    }

    sub new_parser ( $class, $flags = 0 ) {
        bless { flags => $flags // 0 }, ref($class) || $class;
    }
    sub flags ($self) { $self->{flags} }

    sub parse_sequence ( $self, $buf ) {
        return ( 0, undef ) unless defined $buf && length $buf;
        my $b0 = _u8( $buf, 0 );
        if ( $b0 == 0x1B ) {
            return ( 1, _press( code => KEY_ESCAPE ) ) if length $buf == 1;
            my $b1 = _u8( $buf, 1 );
            return $self->_parse_ss3($buf)                               if $b1 == ord 'O';
            return $self->_parse_dcs($buf)                               if $b1 == ord 'P';
            return $self->_parse_csi($buf)                               if $b1 == ord '[';
            return $self->_parse_osc($buf)                               if $b1 == ord ']';
            return $self->_parse_apc($buf)                               if $b1 == ord '_';
            return $self->_parse_st_terminated( 0x9E, '^', undef, $buf ) if $b1 == ord '^';
            return $self->_parse_st_terminated( 0x98, 'X', undef, $buf ) if $b1 == ord 'X';
            my ( $n, $e ) = $self->parse_sequence( substr $buf, 1 );

            if ( defined $e && $e->isa('Cancer::Input::KeyPressEvent') ) {
                $e->{text} = '';
                $e->{mod} |= MOD_ALT;
                return ( $n + 1, $e );
            }
            return ( 1, _press( code => KEY_ESCAPE ) );
        }
        return $self->_parse_ss3($buf)                               if $b0 == 0x8F;
        return $self->_parse_dcs($buf)                               if $b0 == 0x90;
        return $self->_parse_csi($buf)                               if $b0 == 0x9B;
        return $self->_parse_osc($buf)                               if $b0 == 0x9D;
        return $self->_parse_st_terminated( 0x9E, '^', undef, $buf ) if $b0 == 0x9E;
        return $self->_parse_st_terminated( 0x98, 'X', undef, $buf ) if $b0 == 0x98;
        return $self->_parse_apc($buf)                               if $b0 == 0x9F;

        if ( $b0 <= 0x1F || $b0 == 0x7F || $b0 == 0x20 ) {
            return ( 1, $self->_parse_control($b0) );
        }
        if ( $b0 >= 0x80 && $b0 <= 0x9F ) {
            return ( 1, _press( code => $b0 - 0x40, mod => MOD_CTRL | MOD_ALT ) );
        }
        return $self->_parse_utf8($buf);
    }
    sub _u8 ( $b, $i ) { ord substr $b, $i, 1 }

    sub _pparam ( $v, $def ) {
        my $p = ( $v // 0 ) & PARAM_MASK;
        return ( $def, 0 ) if $p == MISSING_PARAM;
        return ( $p,   0 );
    }

    sub _param ( $pa, $i, $def ) {
        return ( $def, 0, 0 ) if !defined $pa || $i < 0 || $i >= @$pa;
        my ( $v, $hm ) = _pparam( $pa->[$i], $def );
        return ( $v, $hm, 1 );
    }
    sub _phas_more ($v) { ( $v & HAS_MORE_FLAG ) != 0 }

    sub _scan_params ( $b, $i, $max ) {
        my @pa;
        my ( $plen, $j ) = ( 0, 0 );
        $pa[0] = 0;
        while ( $$i < length $b && $plen < $max ) {
            my $c = _u8( $b, $$i );
            last if $c < 0x30 || $c > 0x3F;
            if ( $c >= 0x30 && $c <= 0x39 ) {
                $pa[$plen] = 0 if $pa[$plen] == MISSING_PARAM;
                $pa[$plen] = $pa[$plen] * 10 + $c - 0x30;
            }
            $pa[$plen] |= HAS_MORE_FLAG if $c == 0x3A;
            if ( $c == 0x3B || $c == 0x3A ) {
                $plen++;
                $pa[$plen] = MISSING_PARAM if $plen < $max;
            }
            ( $$i, $j ) = ( $$i + 1, $j + 1 );
        }
        $plen++ if $j > 0 && $plen < $max;
        return ( $plen, \@pa );
    }
    sub _press   (%f)     { Cancer::Input::KeyPressEvent->new(%f) }
    sub _release (%f)     { Cancer::Input::KeyReleaseEvent->new(%f) }
    sub _unknown ($bytes) { Cancer::Input::UnknownEvent->new( bytes => $bytes ) }

    sub _mk_cmd ( $prefix, $intermed, $final ) {
        ( $final // 0 ) | ( ( $intermed // 0 ) << INTERMED_SHIFT ) | ( ( $prefix // 0 ) << PREFIX_SHIFT );
    }

    sub _cp_to_char ($cp) {
        $cp = 0xFFFD if !defined $cp || $cp < 0 || $cp > 0x10FFFF || ( $cp >= 0xD800 && $cp <= 0xDFFF );
        chr $cp;
    }

    sub _printable_cp ($cp) {
        return '' if !defined $cp || $cp <= 0 || $cp > 0x10FFFF || ( $cp >= 0xD800 && $cp <= 0xDFFF );
        return chr($cp) =~ /^[\p{L}\p{M}\p{N}\p{P}\p{S} ]$/ ? 1 : '';
    }
    sub _is_control_cp ($cp) { defined $cp && ( $cp <= 0x1F || ( $cp >= 0x7F && $cp <= 0x9F ) ) }

    sub _decode_rune ($b) {
        return () unless length $b;
        my $c0 = _u8( $b, 0 );
        return ( $c0, 1 ) if $c0 < 0x80;
        my $ranges;
        for my $r (@UTF8_RANGES) {
            if ( $c0 >= $r->[0] && $c0 <= $r->[1] ) { $ranges = $r->[2]; last }
        }
        return () unless $ranges;
        return () if length($b) < 1 + @$ranges;
        my $cp = $c0 < 0xE0 ? ( $c0 & 0x1F ) : $c0 < 0xF0 ? ( $c0 & 0x0F ) : ( $c0 & 0x07 );
        for my $i ( 0 .. $#$ranges ) {
            my $c = _u8( $b, $i + 1 );
            my ( $lo, $hi ) = @{ $ranges->[$i] };
            return () if $c < $lo || $c > $hi;
            $cp = ( $cp << 6 ) | ( $c & 0x3F );
        }
        return ( $cp, 1 + @$ranges );
    }

    sub _parse_csi ( $self, $b ) {
        return ( 2, _press( text => _cp_to_char( _u8( $b, 1 ) ), mod => MOD_ALT ) ) if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        my $cmd = 0;
        my $i   = 0;
        my $c0  = _u8( $b, 0 );
        $i++ if $c0 == 0x9B || $c0 == 0x1B;
        $i++ if $i >= 1 && $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord '[';
        if ( $i < length $b ) {
            my $c = _u8( $b, $i );
            $cmd |= $c << PREFIX_SHIFT if $c >= 0x3C && $c <= 0x3F;
        }
        my ( $plen, $pa ) = _scan_params( $b, \$i, MAX_PARAMS_SIZE );
        my $intermed = 0;
        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c < 0x20 || $c > 0x2F;
            $intermed = $c;
            $i++;
        }
        $cmd |= $intermed << INTERMED_SHIFT;
        my $final_missing = 1;
        if ( $i < length $b ) {
            my $fc = _u8( $b, $i );
            $final_missing = '' if $fc >= 0x40 && $fc <= 0x7E;
        }
        if ($final_missing) {
            if ( $i >= 1 && _u8( $b, $i - 1 ) == ord '$' ) {
                my ( $n, $ev ) = $self->_parse_csi( substr( $b, 0, $i - 1 ) . '~' );
                if ( defined $ev && $ev->isa('Cancer::Input::KeyPressEvent') ) {
                    $ev->{mod} |= MOD_SHIFT;
                    return ( $n, $ev );
                }
            }

            # Buffer simply ended mid-sequence: wait for more bytes rather
            # than shredding responses that arrive split across reads (e.g.
            # a DA1 reply cut between parameters). Upstream drains these as
            # UnknownEvent; that ate real terminal replies in practice.
            return ( 0, undef ) if $i >= length $b && length($b) <= 64;

            # A byte exists but cannot be a final: genuinely malformed.
            return ( $i, _unknown( substr $b, 0, $i - 1 ) );
        }
        my $final = _u8( $b, $i );
        $cmd |= $final;
        $i++;
        my $unk = sub { ( $i, _unknown( substr $b, 0, $i ) ) };
        if ( $cmd == _mk_cmd( ord '?', ord '$', ord 'y' ) ) {
            my ( $mode, undef, $ok ) = _param( $pa, 0, -1 );
            if ( !$ok || $mode == -1 ) { return $unk->() }
            my ( $value, undef, $ok2 ) = _param( $pa, 1, -1 );
            if ( !$ok2 || $value == -1 ) { return $unk->() }
            return ( $i, Cancer::Input::ModeReportEvent->new( mode => $mode, value => $value, dec => 1 ) );
        }
        elsif ( $cmd == _mk_cmd( ord '?', undef, ord 'c' ) ) {
            return ( $i, _primary_dev_attrs($pa) );
        }
        elsif ( $cmd == _mk_cmd( ord '?', undef, ord 'u' ) ) {
            my ( $flags, undef, $ok ) = _param( $pa, 0, -1 );
            if ( !$ok || $flags == -1 ) { return $unk->() }
            return ( $i, Cancer::Input::KittyEnhancementsEvent->new( flags => $flags ) );
        }
        elsif ( $cmd == _mk_cmd( ord '?', undef, ord 'R' ) ) {
            my ( $row, undef, $ok ) = _param( $pa, 0, 1 );
            if ( !$ok ) { return $unk->() }
            my ( $col, undef, $ok2 ) = _param( $pa, 1, 1 );
            if ( !$ok2 ) { return $unk->() }
            return ( $i, Cancer::Input::CursorPositionEvent->new( x => $col - 1, y => $row - 1 ) );
        }
        elsif ( $cmd == _mk_cmd( ord '<', undef, ord 'm' ) || $cmd == _mk_cmd( ord '<', undef, ord 'M' ) ) {
            return ( $i, _parse_sgr_mouse( $final, $pa ) ) if $plen == 3;
        }
        elsif ( $cmd == _mk_cmd( ord '>', undef, ord 'm' ) ) {
            my ( $mok, undef, $ok ) = _param( $pa, 0, 0 );
            if ( !$ok || $mok != 4 ) { return $unk->() }
            my ( $val, undef, $ok2 ) = _param( $pa, 1, -1 );
            if ( !$ok2 || $val == -1 ) { return $unk->() }
            return ( $i, Cancer::Input::ModifyOtherKeysEvent->new( value => $val ) );
        }
        elsif ( $cmd == ord 'I' ) {
            return ( $i, Cancer::Input::FocusEvent->new );
        }
        elsif ( $cmd == ord 'O' ) {
            return ( $i, Cancer::Input::BlurEvent->new );
        }
        elsif ( $cmd == ord 'R' && $plen == 2 ) {
            my ( $row, undef, $rok ) = _param( $pa, 0, 1 );
            my ( $col, undef, $cok ) = _param( $pa, 1, 1 );
            if ( $rok && $cok ) {
                my $cp = Cancer::Input::CursorPositionEvent->new( x => $col - 1, y => $row - 1 );
                if ( $row == 1 && $col - 1 <= ( MOD_META | MOD_SHIFT | MOD_ALT | MOD_CTRL ) ) {
                    return ( $i, Cancer::Input::MultiEvent->new( events => [ _press( code => KEY_F3, mod => $col - 1 ), $cp ] ) );
                }
                return ( $i, $cp );
            }
            return $unk->();
        }
        elsif ( ( $final >= ord('a') && $final <= ord('d') ) ||
            ( $final >= ord('A') && $final <= ord('D') ) ||
            $final == ord('E')                           ||
            $final == ord('F')                           ||
            $final == ord('H')                           ||
            $final == ord('Z')                           ||
            ( $final >= ord('P') && $final <= ord('S') ) ||
            ( $cmd == ord('R') && $plen == 0 ) ) {
            my $k;
            if ( $final >= ord('a') && $final <= ord('d') ) {
                $k = _press( code => KEY_UP + $final - ord('a'), mod => MOD_SHIFT );
            }
            elsif ( $final >= ord('A') && $final <= ord('D') ) {
                $k = _press( code => KEY_UP + $final - ord('A') );
            }
            elsif ( $final == ord('E') ) { $k = _press( code => KEY_BEGIN ) }
            elsif ( $final == ord('F') ) { $k = _press( code => KEY_END ) }
            elsif ( $final == ord('H') ) { $k = _press( code => KEY_HOME ) }
            elsif ( $final >= ord('P') && $final <= ord('S') ) {
                $k = _press( code => KEY_F1 + $final - ord('P') );
            }
            elsif ( $final == ord('Z') ) { $k = _press( code => KEY_TAB, mod => MOD_SHIFT ) }
            else                         { $k = _press( code => KEY_F3 ) }
            my ($id) = _param( $pa, 0, 1 );
            $id = 1 if $id == 0;
            my ($mod) = _param( $pa, 1, 1 );
            $mod = 1 if $mod == 0;
            $k->{mod} |= $mod - 1 if $plen > 1 && $id == 1 && $mod != -1;
            return ( $i, _kitty_ext( $pa, $k ) );
        }
        elsif ( $cmd == ord 'M' ) {
            if ( $i + 3 > length $b ) {
                return ( $i, _unknown( substr $b, 0, $i ) );
            }
            return ( $i + 3, _parse_x10_mouse( substr( $b, 0, $i + 3 ) ) );
        }
        elsif ( $cmd == _mk_cmd( undef, ord '$', ord 'y' ) ) {
            my ( $mode, undef, $ok ) = _param( $pa, 0, -1 );
            if ( !$ok || $mode == -1 ) { return $unk->() }
            my ( $value, undef, $ok2 ) = _param( $pa, 1, -1 );
            if ( !$ok2 || $value == -1 ) { return $unk->() }
            return ( $i, Cancer::Input::ModeReportEvent->new( mode => $mode, value => $value, dec => '' ) );
        }
        elsif ( $cmd == ord 'u' ) {
            return ( $i, _unknown( substr $b, 0, $i ) ) if $plen == 0;
            return ( $i, _parse_kitty_keyboard($pa) );
        }
        elsif ( $cmd == ord '_' ) {
            if ( $plen != 6 ) { return ( $i, _unknown( substr $b, 0, $i ) ) }
            my $rc = ( _param( $pa, 5, 0 ) )[0];
            $rc = 1 if $rc == 0;
            my $vk    = ( _param( $pa, 0, 0 ) )[0];
            my $sc    = ( _param( $pa, 1, 0 ) )[0];
            my $uc    = ( _param( $pa, 2, 0 ) )[0];
            my $kd    = ( _param( $pa, 3, 0 ) )[0];
            my $cs    = ( _param( $pa, 4, 0 ) )[0];
            my $event = $self->_win32_key_event( undef, $vk, $sc, $uc, $kd == 1 ? 1 : '', $cs, $rc );
            return ( $i, defined $event ? $event : _unknown($b) );
        }
        elsif ( $final == ord('@') || $final == ord('^') || $final == ord('~') ) {
            return ( $i, _unknown( substr $b, 0, $i ) ) if $plen == 0;
            my ($param) = _param( $pa, 0, 0 );
            if ( $final == ord '~' ) {
                if ( $param == 27 ) {
                    return ( $i, _unknown( substr $b, 0, $i ) ) if $plen != 3;
                    return ( $i, _parse_xterm_modify_other_keys($pa) );
                }
                return ( $i, Cancer::Input::PasteStartEvent->new ) if $param == 200;
                return ( $i, Cancer::Input::PasteEndEvent->new )   if $param == 201;
            }
            if ( _is_tilde_param($param) ) {
                my $k;
                if ( $param == 1 ) {
                    $k = $self->{flags} & FLAG_FIND ? _press( code => KEY_FIND ) : _press( code => KEY_HOME );
                }
                elsif ( $param == 2 ) { $k = _press( code => KEY_INSERT ) }
                elsif ( $param == 3 ) { $k = _press( code => KEY_DELETE ) }
                elsif ( $param == 4 ) {
                    $k = $self->{flags} & FLAG_SELECT ? _press( code => KEY_SELECT ) : _press( code => KEY_END );
                }
                elsif ( $param == 5 )  { $k = _press( code => KEY_PG_UP ) }
                elsif ( $param == 6 )  { $k = _press( code => KEY_PG_DOWN ) }
                elsif ( $param == 7 )  { $k = _press( code => KEY_HOME ) }
                elsif ( $param == 8 )  { $k = _press( code => KEY_END ) }
                elsif ( $param <= 15 ) { $k = _press( code => KEY_F1 + $param - 11 ) }
                elsif ( $param <= 21 ) { $k = _press( code => KEY_F6 + $param - 17 ) }
                elsif ( $param <= 26 ) { $k = _press( code => KEY_F11 + $param - 23 ) }
                elsif ( $param <= 29 ) { $k = _press( code => KEY_F15 + $param - 28 ) }
                else                   { $k = _press( code => KEY_F17 + $param - 31 ) }
                my ($mod) = _param( $pa, 1, -1 );
                $k->{mod} |= $mod - 1 if $plen > 1 && $mod != -1;
                if    ( $final == ord '^' ) { $k->{mod} |= MOD_CTRL; return ( $i, $k ) }
                elsif ( $final == ord '@' ) { $k->{mod} |= MOD_CTRL | MOD_SHIFT; return ( $i, $k ) }
                else                        { return ( $i, _kitty_ext( $pa, $k ) ) }
            }
        }
        elsif ( $cmd == ord 't' ) {
            my ( $op, undef, $ok ) = _param( $pa, 0, 0 );
            if ($ok) {
                my @args;
                push @args, ( _param( $pa, $_, 0 ) )[0] for 1 .. $plen - 1;
                return ( $i, Cancer::Input::WindowOpEvent->new( op => $op, args => \@args ) );
            }
        }
        return $unk->();
    }

    sub _is_tilde_param ($p) {
        return ( $p >= 1 && $p <= 8 )  ||
            ( $p >= 11   && $p <= 15 ) ||
            ( $p >= 17   && $p <= 21 ) ||
            ( $p >= 23   && $p <= 26 ) ||
            ( $p == 28 || $p == 29 ) ||
            ( $p >= 31 && $p <= 34 );
    }

    sub _parse_ss3 ( $self, $b ) {
        return ( 2, _press( code => _u8( $b, 1 ), mod => MOD_ALT ) ) if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        my $i  = 0;
        my $c0 = _u8( $b, 0 );
        $i++ if $c0 == 0x8F || $c0 == 0x1B;
        $i++ if $i >= 1 && $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord 'O';
        my $mod = 0;
        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c < 0x30 || $c > 0x39;
            $mod = $mod * 10 + $c - 0x30;
            $i++;
        }
        my $gl;
        if ( $i >= length $b || ( $gl = _u8( $b, $i ) ) < 0x21 || $gl > 0x7E ) {
            return ( $i, _unknown( substr $b, 0, $i ) );
        }
        $i++;
        my $k;
        if ( $gl >= ord('a') && $gl <= ord('d') ) {
            $k = _press( code => KEY_UP + $gl - ord('a'), mod => MOD_CTRL );
        }
        elsif ( $gl >= ord('A') && $gl <= ord('D') ) { $k = _press( code => KEY_UP + $gl - ord('A') ) }
        elsif ( $gl == ord('E') )                    { $k = _press( code => KEY_BEGIN ) }
        elsif ( $gl == ord('F') )                    { $k = _press( code => KEY_END ) }
        elsif ( $gl == ord('H') )                    { $k = _press( code => KEY_HOME ) }
        elsif ( $gl >= ord('P') && $gl <= ord('S') ) { $k = _press( code => KEY_F1 + $gl - ord('P') ) }
        elsif ( $gl == ord('M') )                    { $k = _press( code => KEY_KP_ENTER ) }
        elsif ( $gl == ord('X') )                    { $k = _press( code => KEY_KP_EQUAL ) }
        elsif ( $gl >= ord('j') && $gl <= ord('y') ) {
            $k = _press( code => KEY_KP_MULTIPLY + $gl - ord('j') );
        }
        else { return ( $i, _unknown( substr $b, 0, $i ) ) }
        $k->{mod} |= $mod - 1 if $mod > 0;
        return ( $i, $k );
    }

    sub _parse_osc ( $self, $b ) {
        my $default_key = sub { _press( code => _u8( $b, 1 ), mod => MOD_ALT ) };
        return ( 2, $default_key->() ) if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        my $i  = 0;
        my $c0 = _u8( $b, 0 );
        $i++ if $c0 == 0x9D || $c0 == 0x1B;
        $i++ if $i >= 1 && $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord ']';
        my ( $start, $end ) = ( 0, 0 );
        my $cmd = -1;

        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last     if $c < 0x30 || $c > 0x39;
            $cmd = 0 if $cmd == -1;
            $cmd *= 10 unless $cmd == 0;
            $cmd += $c - 0x30;
            $i++;
        }
        if ( $i < length $b && _u8( $b, $i ) == 0x3B ) {
            $i++;
            $start = $i;
        }
        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c == 0x07 || $c == 0x1B || $c == 0x9C || $c == 0x18 || $c == 0x1A;
            $i++;
        }
        return ( $i, _unknown( substr $b, 0, $i ) ) if $i >= length $b;
        $end = $i;
        $i++;
        my $t = _u8( $b, $i - 1 );
        if ( $t == 0x18 || $t == 0x1A ) { return ( $i, _unknown( substr $b, 0, $i ) ) }
        if ( $t == 0x1B ) {
            if ( $i >= length $b || _u8( $b, $i ) != ord '\\' ) {
                return ( 2,  $default_key->() ) if $cmd == -1 || ( $start == 0 && $end == 2 );
                return ( $i, _unknown( substr $b, 0, $i ) );
            }
            $i++;
        }
        return ( $i, _unknown( substr $b, 0, $i ) ) if $end <= $start;
        my $data = substr $b, $start, $end - $start;
        if ( $cmd == 10 || $cmd == 11 || $cmd == 12 ) {
            my $color = Cancer::Ansi::x_parse_color($data);
            my $cls
                = $cmd == 10 ? 'Cancer::Input::ForegroundColorEvent' :
                $cmd == 11   ? 'Cancer::Input::BackgroundColorEvent' :
                'Cancer::Input::CursorColorEvent';
            return ( $i, $cls->new( color => $color ) );
        }
        if ( $cmd == 52 ) {
            my @parts = split /;/, $data;
            return ( $i, Cancer::Input::ClipboardEvent->new ) if !@parts;
            if ( @parts != 2 || !length $parts[0] ) { return ( $i, _unknown( substr $b, 0, $i ) ) }
            my $content;
            if ( $parts[1] =~ /\A[A-Za-z0-9+\/]*={0,2}\z/ && length( $parts[1] ) % 4 == 0 ) {
                $content = decode_base64( $parts[1] );
            }
            return ( $i, _unknown( substr $b, 0, $i ) ) unless defined $content;
            return ( $i, Cancer::Input::ClipboardEvent->new( selection => ord( substr $parts[0], 0, 1 ), content => $content ) );
        }
        return ( $i, _unknown( substr $b, 0, $i ) );
    }

    sub _parse_st_terminated ( $self, $intro8, $intro7, $fn, $b ) {
        my $default_key = sub {
            if ( $intro8 == 0x98 ) { return ( 2, _press( code => ord 'x', mod => MOD_SHIFT | MOD_ALT ) ) }
            if ( $intro8 == 0x9E || $intro8 == 0x9F ) {
                return ( 2, _press( code => _u8( $b, 1 ), mod => MOD_ALT ) );
            }
            return ( 0, undef );
        };
        return $default_key->() if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        my $i  = 0;
        my $c0 = _u8( $b, 0 );
        $i++ if $c0 == $intro8 || $c0 == 0x1B;
        $i++ if $i >= 1 && $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord $intro7;
        my $start = $i;
        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c == 0x1B || $c == 0x9C || $c == 0x18 || $c == 0x1A;
            $i++;
        }
        return ( $i, _unknown( substr $b, 0, $i ) ) if $i >= length $b;
        my $end = $i;
        $i++;
        my $t = _u8( $b, $i - 1 );
        if ( $t == 0x18 || $t == 0x1A ) { return ( $i, _unknown( substr $b, 0, $i ) ) }
        if ( $t == 0x1B ) {
            if ( $i >= length $b || _u8( $b, $i ) != ord '\\' ) {
                return $default_key->() if $start == $end;
                return ( $i, _unknown( substr $b, 0, $i ) );
            }
            $i++;
        }
        if ( defined $fn ) {
            my $e = $fn->( substr $b, $start, $end - $start );
            return ( $i, $e ) if defined $e;
        }
        return ( $i, _unknown( substr $b, 0, $i ) );
    }

    sub _parse_dcs ( $self, $b ) {
        return ( 2, _press( code => ord 'p', mod => MOD_SHIFT | MOD_ALT ) ) if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        my $i  = 0;
        my $c0 = _u8( $b, 0 );
        $i++ if $c0 == 0x90 || $c0 == 0x1B;
        $i++ if $i >= 1 && $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord 'P';
        my $cmd = 0;
        if ( $i < length $b ) {
            my $c = _u8( $b, $i );
            $cmd |= $c << PREFIX_SHIFT if $c >= 0x3C && $c <= 0x3F;
        }
        my ( $plen, $pa ) = _scan_params( $b, \$i, MAX_DCS_PARAMS_SIZE );
        my $intermed = 0;
        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c < 0x20 || $c > 0x2F;
            $intermed = $c;
            $i++;
        }
        $cmd |= $intermed << INTERMED_SHIFT;
        return ( $i, _unknown( substr $b, 0, $i ) ) if $i >= length $b;
        my $final = _u8( $b, $i );
        return ( $i, _unknown( substr $b, 0, $i ) ) if $final < 0x40 || $final > 0x7E;
        $cmd |= $final;
        $i++;
        my $start = $i;

        while ( $i < length $b ) {
            my $c = _u8( $b, $i );
            last if $c == 0x9C || $c == 0x1B;
            $i++;
        }
        return ( $i, _unknown( substr $b, 0, $i ) ) if $i >= length $b;
        my $end = $i;
        $i++;
        $i++ if $i < length $b && _u8( $b, $i - 1 ) == 0x1B && _u8( $b, $i ) == ord '\\';
        if ( $cmd == _mk_cmd( undef, ord '+', ord 'r' ) ) {
            my ($param) = _param( $pa, 0, 0 );
            if ( $param == 1 ) {
                return ( $i, _parse_termcap( substr $b, $start, $end - $start ) );
            }
        }
        elsif ( $cmd == _mk_cmd( ord '>', undef, ord '|' ) ) {
            return ( $i, Cancer::Input::TerminalVersionEvent->new( version => substr $b, $start, $end - $start ) );
        }
        return ( $i, _unknown( substr $b, 0, $i ) );
    }

    sub _parse_apc ( $self, $b ) {
        return ( 2, _press( code => _u8( $b, 1 ), mod => MOD_ALT ) ) if length $b == 2 && _u8( $b, 0 ) == 0x1B;
        return $self->_parse_st_terminated(
            0x9F, '_',
            sub ($data) {
                return undef unless length $data;
                return undef unless _u8( $data, 0 ) == ord 'G';
                my @parts   = split /;/, substr $data, 1;
                my %opts    = map { split /=/, $_, 2 } split /,/, $parts[0];
                my $payload = @parts > 1 ? $parts[1] : '';
                Cancer::Input::KittyGraphicsEvent->new( options => \%opts, payload => $payload );
            },
            $b
        );
    }

    sub _parse_utf8 ( $self, $b ) {
        return ( 0, undef ) unless length $b;
        my $c = _u8( $b, 0 );
        if ( $c <= 0x1F || $c == 0x7F || $c == 0x20 ) {
            return ( 1, $self->_parse_control($c) );
        }
        if ( $c > 0x1F && $c < 0x7F ) {
            my $ch = chr $c;
            my $k  = _press( code => $c, text => $ch );
            if ( $ch =~ /\p{Lu}/ ) {
                $k->{code}         = ord lc $ch;
                $k->{shifted_code} = $c;
                $k->{mod} |= MOD_SHIFT;
            }
            return ( 1, $k );
        }
        my ( $rune, $w ) = _decode_rune($b);
        return ( 1, _unknown( substr $b, 0, 1 ) ) unless defined $rune;
        my $text = '';
        my $off  = 0;
        while ( $off < length $b ) {
            my ( $cp, $bw ) = _decode_rune( substr $b, $off );
            last unless defined $cp;
            $text .= chr $cp;
            $off += $bw;
        }
        my $cluster = $text =~ /^(\X)/ ? $1 : '';
        return ( 1, _unknown( substr $b, 0, 1 ) ) unless length $cluster;
        my $clen = length encode( 'UTF-8', $cluster );
        my $code = $rune;
        $code = KEY_EXTENDED if length $cluster > 1;
        return ( $clen, _press( code => $code, text => $cluster ) );
    }

    sub _parse_control ( $self, $b ) {
        if ( $b == 0x00 ) {
            return $self->{flags} & FLAG_CTRL_AT ? _press( code => ord '@', mod => MOD_CTRL ) : _press( code => KEY_SPACE, mod => MOD_CTRL );
        }
        if ( $b == 0x08 ) { return _press( code => ord 'h', mod => MOD_CTRL ) }
        if ( $b == 0x09 ) {
            return $self->{flags} & FLAG_CTRL_I ? _press( code => ord 'i', mod => MOD_CTRL ) : _press( code => KEY_TAB );
        }
        if ( $b == 0x0D ) {
            return $self->{flags} & FLAG_CTRL_M ? _press( code => ord 'm', mod => MOD_CTRL ) : _press( code => KEY_ENTER );
        }
        if ( $b == 0x1B ) {
            return $self->{flags} & FLAG_CTRL_OPEN_BRACKET ? _press( code => ord '[', mod => MOD_CTRL ) : _press( code => KEY_ESCAPE );
        }
        if ( $b == 0x7F ) {
            return $self->{flags} & FLAG_BACKSPACE ? _press( code => KEY_DELETE ) : _press( code => KEY_BACKSPACE );
        }
        if ( $b == 0x20 )               { return _press( code => KEY_SPACE, text => ' ' ) }
        if ( $b >= 0x01 && $b <= 0x1A ) { return _press( code => $b + 0x60, mod  => MOD_CTRL ) }
        if ( $b >= 0x1C && $b <= 0x1F ) { return _press( code => $b + 0x40, mod  => MOD_CTRL ) }
        return _unknown( chr $b );
    }

    sub _from_kitty_mod ($mod) {
        my $m = 0;
        $m |= MOD_SHIFT     if $mod & 0x01;
        $m |= MOD_ALT       if $mod & 0x02;
        $m |= MOD_CTRL      if $mod & 0x04;
        $m |= MOD_SUPER     if $mod & 0x08;
        $m |= MOD_HYPER     if $mod & 0x10;
        $m |= MOD_META      if $mod & 0x20;
        $m |= MOD_CAPS_LOCK if $mod & 0x40;
        $m |= MOD_NUM_LOCK  if $mod & 0x80;
        return $m;
    }

    sub _kitty_code ($code) {
        my $entry = $KITTY_KEY_MAP{$code};
        return @{$entry} if $entry;
        return ( $code, 0 );
    }

    sub _parse_kitty_keyboard ($pa) {
        my $key = {};
        my $is_release;
        my ( $param_idx, $sud_idx ) = ( 0, 0 );
        for my $p (@$pa) {
            if ( $param_idx == 0 ) {
                if ( $sud_idx == 0 ) {
                    my $code = ( _pparam( $p, 1 ) )[0];
                    my ( $kc, $km ) = _kitty_code($code);
                    $key->{code} = $kc;
                    if ( $km && !$key->{mod} ) { $key->{mod} = $km }
                }
                elsif ( $sud_idx == 1 ) {
                    my $s = ( _pparam( $p, 1 ) )[0];
                    $key->{shifted_code} = $s if _printable_cp($s);
                }
                elsif ( $sud_idx == 2 ) {
                    my $bp = ( _pparam( $p, 1 ) )[0];
                    my $sp = ( _pparam( $p, 1 ) )[0];
                    $key->{base_code}    = $bp if _printable_cp($bp);
                    $key->{shifted_code} = $sp if _printable_cp($sp);
                }
            }
            elsif ( $param_idx == 1 ) {
                if ( $sud_idx == 0 ) {
                    my $mod = ( _pparam( $p, 1 ) )[0];
                    if ( $mod > 1 ) {
                        $key->{mod}  = _from_kitty_mod( $mod - 1 );
                        $key->{text} = '' if $key->{mod} > MOD_SHIFT;
                    }
                }
                elsif ( $sud_idx == 1 ) {
                    my $t = ( _pparam( $p, 1 ) )[0];
                    if ( $t == 2 ) { $key->{is_repeat} = 1 }
                    elsif ( $t == 3 ) { $is_release = 1 }
                }
            }
            elsif ( $param_idx == 2 ) {
                my $code = ( _pparam( $p, 0 ) )[0];
                $key->{text} .= _cp_to_char($code) if $code != 0;
            }
            $sud_idx++;
            if ( !_phas_more($p) ) {
                $param_idx++;
                $sud_idx = 0;
            }
        }
        my $code = $key->{code} // 0;
        my $mod  = $key->{mod}  // 0;
        if ( !length( $key->{text} // '' ) &&
            _printable_cp($code) &&
            ( $mod <= MOD_SHIFT || $mod == MOD_CAPS_LOCK || $mod == ( MOD_SHIFT | MOD_CAPS_LOCK ) ) ) {
            if ( $mod == 0 ) {
                $key->{text} = _cp_to_char($code);
            }
            else {
                my $upper = ( $mod & ( MOD_SHIFT | MOD_CAPS_LOCK ) ) != 0;
                if ( $key->{shifted_code} ) {
                    $key->{text} = _cp_to_char( $key->{shifted_code} );
                }
                else {
                    my $ch = _cp_to_char($code);
                    $key->{text} = $upper ? uc $ch : lc $ch;
                }
            }
        }
        return $is_release ? _release(%$key) : _press(%$key);
    }

    sub _kitty_ext ( $pa, $k ) {
        if ( @$pa > 2 && ( _pparam( $pa->[0], 1 ) )[0] == 1 && _phas_more( $pa->[1] ) ) {
            my $t = ( _pparam( $pa->[2], 1 ) )[0];
            if    ( $t == 2 ) { $k->{is_repeat} = 1 }
            elsif ( $t == 3 ) { return _release(%$k) }
        }
        return $k;
    }
    sub _is_wheel ($btn) { $btn >= MOUSE_WHEEL_UP && $btn <= MOUSE_WHEEL_RIGHT }

    sub _parse_mouse_button ($b) {
        my ( $mod, $btn, $release, $motion ) = ( 0, 0, '', '' );
        $mod |= MOD_ALT   if $b & 0x08;
        $mod |= MOD_CTRL  if $b & 0x10;
        $mod |= MOD_SHIFT if $b & 0x04;
        if    ( $b & 0x80 ) { $btn = MOUSE_BACKWARD + ( $b & 0x03 ) }
        elsif ( $b & 0x40 ) { $btn = MOUSE_WHEEL_UP + ( $b & 0x03 ) }
        else {
            $btn = MOUSE_LEFT + ( $b & 0x03 );
            if ( ( $b & 0x03 ) == 0x03 ) { $btn = MOUSE_NONE; $release = 1 }
        }
        $motion = 1 if ( $b & 0x20 ) && !_is_wheel($btn);
        return ( $mod, $btn, $release, $motion );
    }
    my %MOUSE_BUTTON_NAMES;

    BEGIN {
        %MOUSE_BUTTON_NAMES = (
            MOUSE_NONE()        => 'none',
            MOUSE_LEFT()        => 'left',
            MOUSE_MIDDLE()      => 'middle',
            MOUSE_RIGHT()       => 'right',
            MOUSE_WHEEL_UP()    => 'wheelup',
            MOUSE_WHEEL_DOWN()  => 'wheeldown',
            MOUSE_WHEEL_LEFT()  => 'wheelleft',
            MOUSE_WHEEL_RIGHT() => 'wheelright',
            MOUSE_BACKWARD()    => 'backward',
            MOUSE_FORWARD()     => 'forward',
            MOUSE_BUTTON10()    => 'button10',
            MOUSE_BUTTON11()    => 'button11'
        );
    }

    sub _mouse_string ($m) {
        my $mod = $m->{mod} || 0;
        my $s   = '';
        $s .= 'ctrl+'  if $mod & MOD_CTRL;
        $s .= 'alt+'   if $mod & MOD_ALT;
        $s .= 'shift+' if $mod & MOD_SHIFT;
        my $str = $MOUSE_BUTTON_NAMES{ $m->{button} // 0 } // '';
        $s .= 'unknown' if !$str;
        $s .= $str      if $str && $str ne 'none';
        return $s;
    }

    sub _mouse_event ( $x, $y, $btn, $mod, $release, $motion, $sgr ) {
        my %m = ( x => $x, y => $y, button => $btn, mod => $mod );
        return Cancer::Input::MouseWheelEvent->new(%m) if _is_wheel($btn);
        if ($sgr) {
            return Cancer::Input::MouseReleaseEvent->new(%m) if !$motion && $release;
            return Cancer::Input::MouseMotionEvent->new(%m)  if $motion;
        }
        else {
            return Cancer::Input::MouseMotionEvent->new(%m)  if $motion;
            return Cancer::Input::MouseReleaseEvent->new(%m) if $release;
        }
        return Cancer::Input::MouseClickEvent->new(%m);
    }

    sub _parse_sgr_mouse ( $final, $pa ) {
        my ( $x, undef, $ok ) = _param( $pa, 1, 1 );
        $x = 1 if !$ok;
        my ( $y, undef, $oky ) = _param( $pa, 2, 1 );
        $y = 1 if !$oky;
        my ( $b, undef ) = _pparam( $pa->[0], 0 );
        my ( $mod, $btn, $release, $motion ) = _parse_mouse_button($b);
        $release = 1 if $final == ord 'm';
        return _mouse_event( $x - 1, $y - 1, $btn, $mod, $release, $motion, 1 );
    }

    sub _parse_x10_mouse ($buf) {
        my $b = _u8( $buf, 3 );
        $b -= 32 if $b >= 32;
        my ( $mod, $btn, $release, $motion ) = _parse_mouse_button($b);
        return _mouse_event( _u8( $buf, 4 ) - 33, _u8( $buf, 5 ) - 33, $btn, $mod, $release, $motion, '' );
    }

    sub _parse_xterm_modify_other_keys ($pa) {
        my $xmod  = ( _param( $pa, 1, 1 ) )[0];
        my $xrune = ( _param( $pa, 2, 1 ) )[0];
        my $mod   = $xmod - 1;
        my $r     = $xrune;
        if    ( $r == 0x08 ) { return _press( mod => $mod, code => KEY_BACKSPACE ) }
        elsif ( $r == 0x09 ) { return _press( mod => $mod, code => KEY_TAB ) }
        elsif ( $r == 0x0D ) { return _press( mod => $mod, code => KEY_ENTER ) }
        elsif ( $r == 0x1B ) { return _press( mod => $mod, code => KEY_ESCAPE ) }
        elsif ( $r == 0x7F ) { return _press( mod => $mod, code => KEY_BACKSPACE ) }
        my $k = _press( code => $r, mod => $mod );
        $k->{text} = _cp_to_char($r) if $mod <= MOD_SHIFT;
        return $k;
    }

    sub _primary_dev_attrs ($pa) {
        my @attrs;
        for my $p (@$pa) {
            push @attrs, _phas_more($p) ? 0 : ( _pparam( $p, 0 ) )[0];
        }
        return Cancer::Input::PrimaryDeviceAttributesEvent->new( attrs => \@attrs );
    }

    sub _hex_decode ($hex) {
        return undef unless defined $hex;
        return undef unless $hex =~ /\A[0-9A-Fa-f]+\z/;
        return undef unless length($hex) % 2 == 0;
        return pack 'H*', lc $hex;
    }

    sub _parse_termcap ($data) {
        return Cancer::Input::CapabilityEvent->new( value => '' ) unless length $data;
        my @out;
        for my $part ( split /;/, $data, -1 ) {
            my ( $name, $value ) = split /=/, $part, 2;
            my $n = _hex_decode($name);
            next unless defined $n && length $n;
            if ( defined $value ) {
                my $v = _hex_decode($value);
                next unless defined $v;
                push @out, $n . ( length($v) ? "=$v" : '' );
            }
            else {
                push @out, $n;
            }
        }
        return Cancer::Input::CapabilityEvent->new( value => join ';', @out );
    }

    sub _translate_control_key_state ($cks) {
        my $m = 0;
        $m |= MOD_CTRL        if $cks & ( CKS_LEFT_CTRL | CKS_RIGHT_CTRL );
        $m |= MOD_ALT         if $cks & ( CKS_LEFT_ALT | CKS_RIGHT_ALT );
        $m |= MOD_SHIFT       if $cks & CKS_SHIFT;
        $m |= MOD_CAPS_LOCK   if $cks & CKS_CAPSLOCK;
        $m |= MOD_NUM_LOCK    if $cks & CKS_NUMLOCK;
        $m |= MOD_SCROLL_LOCK if $cks & CKS_SCROLLLOCK;
        return $m;
    }

    sub _ensure_key_case ( $key, $cks ) {
        return $key unless length( $key->{text} // '' );
        my $has_shift = ( $cks & CKS_SHIFT ) != 0;
        my $has_caps  = ( $cks & CKS_CAPSLOCK ) != 0;
        my $ch        = $key->{text};
        if ( $has_shift || $has_caps ) {
            if ( $ch =~ /\p{Ll}/ ) {
                $key->{shifted_code} = ord uc $ch;
                $key->{text}         = uc $ch;
            }
        }
        elsif ( $ch =~ /\p{Lu}/ ) {
            $key->{shifted_code} = ord lc $ch;
            $key->{text}         = lc $ch;
        }
        return $key;
    }

    sub _win32_base_code ( $vkc, $cks, $last_cks = 0, $sc = 0 ) {
        return 0             if $vkc == 0;
        return KEY_BACKSPACE if $vkc == $VK{BACK};
        return KEY_TAB       if $vkc == $VK{TAB};
        return KEY_ENTER     if $vkc == $VK{RETURN};
        if ( $vkc == $VK{SHIFT} ) {

            # The reference implementation relies on ENHANCED_KEY to tell the
            # Shift sides apart, but consoles don't set it for right Shift.
            # The virtual scan code (0x2A left, 0x36 right) is authoritative.
            return KEY_RIGHT_SHIFT if $sc == 0x36;
            return KEY_LEFT_SHIFT  if $sc == 0x2A;
            if ( $cks & CKS_SHIFT ) {
                return KEY_RIGHT_SHIFT if $cks & CKS_ENHANCED;
                return KEY_LEFT_SHIFT;
            }
            elsif ( $last_cks & CKS_SHIFT ) {
                return KEY_RIGHT_SHIFT if $last_cks & CKS_ENHANCED;
                return KEY_LEFT_SHIFT;
            }
            return 0;
        }
        if ( $vkc == $VK{CONTROL} ) {
            return KEY_LEFT_CTRL  if $cks & CKS_LEFT_CTRL;
            return KEY_RIGHT_CTRL if $cks & CKS_RIGHT_CTRL;
            return KEY_LEFT_CTRL  if $last_cks & CKS_LEFT_CTRL;
            return KEY_RIGHT_CTRL if $last_cks & CKS_RIGHT_CTRL;
            return 0;
        }
        if ( $vkc == $VK{MENU} ) {
            return KEY_LEFT_ALT  if $cks & CKS_LEFT_ALT;
            return KEY_RIGHT_ALT if $cks & CKS_RIGHT_ALT;
            return KEY_LEFT_ALT  if $last_cks & CKS_LEFT_ALT;
            return KEY_RIGHT_ALT if $last_cks & CKS_RIGHT_ALT;
            return 0;
        }
        return KEY_PAUSE                          if $vkc == $VK{PAUSE};
        return KEY_CAPS_LOCK                      if $vkc == $VK{CAPITAL};
        return KEY_ESCAPE                         if $vkc == $VK{ESCAPE};
        return KEY_SPACE                          if $vkc == $VK{SPACE};
        return KEY_PG_UP                          if $vkc == $VK{PRIOR};
        return KEY_PG_DOWN                        if $vkc == $VK{NEXT};
        return KEY_END                            if $vkc == $VK{END};
        return KEY_HOME                           if $vkc == $VK{HOME};
        return KEY_LEFT                           if $vkc == $VK{LEFT};
        return KEY_UP                             if $vkc == $VK{UP};
        return KEY_RIGHT                          if $vkc == $VK{RIGHT};
        return KEY_DOWN                           if $vkc == $VK{DOWN};
        return KEY_SELECT                         if $vkc == $VK{SELECT};
        return KEY_PRINT_SCREEN                   if $vkc == $VK{SNAPSHOT};
        return KEY_INSERT                         if $vkc == $VK{INSERT};
        return KEY_DELETE                         if $vkc == $VK{DELETE};
        return $vkc                               if $vkc >= 0x30 && $vkc <= 0x39;
        return $vkc + 32                          if $vkc >= 0x41 && $vkc <= 0x5A;
        return KEY_LEFT_SUPER                     if $vkc == $VK{LWIN};
        return KEY_RIGHT_SUPER                    if $vkc == $VK{RWIN};
        return KEY_MENU                           if $vkc == $VK{APPS};
        return KEY_KP_0 + ( $vkc - $VK{NUMPAD0} ) if $vkc >= $VK{NUMPAD0} && $vkc <= $VK{NUMPAD9};
        return KEY_KP_MULTIPLY                    if $vkc == $VK{MULTIPLY};
        return KEY_KP_PLUS                        if $vkc == $VK{ADD};
        return KEY_KP_COMMA                       if $vkc == $VK{SEPARATOR};
        return KEY_KP_MINUS                       if $vkc == $VK{SUBTRACT};
        return KEY_KP_DECIMAL                     if $vkc == $VK{DECIMAL};
        return KEY_KP_DIVIDE                      if $vkc == $VK{DIVIDE};
        return KEY_F1 + ( $vkc - $VK{F1} )        if $vkc >= $VK{F1} && $vkc <= $VK{F24};
        return KEY_NUM_LOCK                       if $vkc == $VK{NUMLOCK};
        return KEY_SCROLL_LOCK                    if $vkc == $VK{SCROLL};
        return KEY_LEFT_SHIFT                     if $vkc == $VK{LSHIFT};
        return KEY_RIGHT_SHIFT                    if $vkc == $VK{RSHIFT};
        return KEY_LEFT_CTRL                      if $vkc == $VK{LCONTROL};
        return KEY_RIGHT_CTRL                     if $vkc == $VK{RCONTROL};
        return KEY_LEFT_ALT                       if $vkc == $VK{LMENU};
        return KEY_RIGHT_ALT                      if $vkc == $VK{RMENU};
        return KEY_MUTE                           if $vkc == $VK{VOLUME_MUTE};
        return KEY_LOWER_VOL                      if $vkc == $VK{VOLUME_DOWN};
        return KEY_RAISE_VOL                      if $vkc == $VK{VOLUME_UP};
        return KEY_MEDIA_NEXT                     if $vkc == $VK{MEDIA_NEXT_TRACK};
        return KEY_MEDIA_PREV                     if $vkc == $VK{MEDIA_PREV_TRACK};
        return KEY_MEDIA_STOP                     if $vkc == $VK{MEDIA_STOP};
        return KEY_MEDIA_PLAY_PAUSE               if $vkc == $VK{MEDIA_PLAY_PAUSE};
        return ord ';'                            if $vkc == $VK{OEM_1};
        return ord '+'                            if $vkc == $VK{OEM_PLUS};
        return ord ','                            if $vkc == $VK{OEM_COMMA};
        return ord '-'                            if $vkc == $VK{OEM_MINUS};
        return ord '.'                            if $vkc == $VK{OEM_PERIOD};
        return ord '/'                            if $vkc == $VK{OEM_2};
        return ord '`'                            if $vkc == $VK{OEM_3};
        return ord '['                            if $vkc == $VK{OEM_4};
        return ord '\\'                           if $vkc == $VK{OEM_5};
        return ord ']'                            if $vkc == $VK{OEM_6};
        return ord "'"                            if $vkc == $VK{OEM_7};
        return 0;
    }

    # Mirrors Go's win32InputState (driver.go): zero-value via new_win32_state().
    sub new_win32_state () {
        return {
            ansi_buf        => '',
            ansi_idx        => 0,
            utf16_buf       => [ 0, 0 ],
            utf16_half      => 0,
            last_cks        => 0,
            last_mouse_btns => 0,
            last_winsize_x  => 0,
            last_winsize_y  => 0
        };
    }

    sub _win32_key_event ( $self, $state, $vkc, $sc, $r, $key_down, $cks, $repeat ) {
        my $event = _win32_key_event_raw( $self, $state, $vkc, $sc, $r, $key_down, $cks );

        # Go: deferred state.lastCks = cks
        $state->{last_cks} = $cks if defined $state;

        # Go: deferred repeat-count wrapping (wraps even nil events).
        return Cancer::Input::MultiEvent->new( events => [ ($event) x $repeat ] ) if $repeat > 1;
        return $event;
    }

    sub _win32_key_event_raw ( $self, $state, $vkc, $sc, $r, $key_down, $cks ) {
        my $has_state = defined $state;

        # A UTF-16 high surrogate is pending: combine it with this low half.
        if ( $has_state && $state->{utf16_half} ) {
            $state->{utf16_half} = 0;
            my $r1 = $state->{utf16_buf}[0];
            my $cp = ( $r1 >= 0xD800 && $r1 <= 0xDBFF && $r >= 0xDC00 && $r <= 0xDFFF ) ? 0x10000 + ( ( $r1 - 0xD800 ) << 10 ) + ( $r - 0xDC00 ) :
                0xFFFD;
            my $key = { code => $cp, text => _cp_to_char($cp), mod => _translate_control_key_state($cks) };
            _ensure_key_case( $key, $cks );
            return $key_down ? Cancer::Input::KeyPressEvent->new(%$key) : Cancer::Input::KeyReleaseEvent->new(%$key);
        }
        my $base_code;
        if ( $vkc == 0 ) {

            # Zero vkc means this event is either an escape sequence byte or a
            # unicode codepoint.
            if ( !$has_state ) {
                $base_code = 0;
            }
            elsif ( $state->{ansi_idx} == 0 && $r != 0x1B ) {
                $base_code = $r;
            }
            else {
                substr( $state->{ansi_buf}, $state->{ansi_idx}, 0 ) = chr( $r & 0xFF );
                $state->{ansi_idx}++;
                return undef if $state->{ansi_idx} <= 2;
                return undef if $r == 0x1B;                # expecting the closing ST
                my ( $n, $ev ) = $self->parse_sequence( substr( $state->{ansi_buf}, 0, $state->{ansi_idx} ) );
                return undef if !$n;
                return undef if ref($ev) eq 'Cancer::Input::UnknownEvent';
                $state->{ansi_buf} = '';
                $state->{ansi_idx} = 0;
                return $ev;
            }
        }
        else {
            $base_code = _win32_base_code( $vkc, $cks, $has_state ? $state->{last_cks} : 0, $sc );
        }
        if ( defined $r && $r >= 0xD800 && $r <= 0xDFFF ) {
            if ($has_state) {
                $state->{utf16_buf}[0] = $r;
                $state->{utf16_half} = 1;
            }
            return undef;
        }
        my $altgr = ( $cks & ( CKS_LEFT_CTRL | CKS_RIGHT_ALT ) ) == ( CKS_LEFT_CTRL | CKS_RIGHT_ALT );

        # Lock-state and enhanced-key bits ride along in cks but don't change
        # which character the key produces; ignore them or NumLock alone
        # strips text from shifted keys (Shift+8 must still yield '*').
        my $keys    = $cks & ~( CKS_NUMLOCK | CKS_SCROLLLOCK | CKS_ENHANCED );
        my $text    = '';
        my $keycode = $base_code;
        if ( defined $r && !_is_control_cp($r) ) {
            $keycode = $r;
            if ( _printable_cp($keycode) &&
                ( $keys == 0 || $keys == CKS_SHIFT || $keys == CKS_CAPSLOCK || $keys == ( CKS_SHIFT | CKS_CAPSLOCK ) || $altgr ) ) {
                $text = _cp_to_char($keycode);
            }
        }
        my $key = { text => $text, code => $keycode, mod => _translate_control_key_state($cks), base_code => $base_code };
        _ensure_key_case( $key, $cks );
        return $key_down ? Cancer::Input::KeyPressEvent->new(%$key) : Cancer::Input::KeyReleaseEvent->new(%$key);
    }
    sub _win32_signed16 ($w) { $w >= 0x8000 ? $w - 0x10000 : $w }

    sub _win32_mouse_button ( $prev_btns, $btns ) {
        my $is_release = 0;
        my $button     = MOUSE_NONE;
        my $btn        = $prev_btns ^ $btns;
        $is_release = 1 if ( $btn & $btns ) == 0;
        if ( $btn == 0 ) {
            if    ( $btns & BTN_FROM_LEFT_1ST ) { $button = MOUSE_LEFT }
            elsif ( $btns & BTN_FROM_LEFT_2ND ) { $button = MOUSE_MIDDLE }
            elsif ( $btns & BTN_RIGHTMOST )     { $button = MOUSE_RIGHT }
            elsif ( $btns & BTN_FROM_LEFT_3RD ) { $button = MOUSE_BACKWARD }
            elsif ( $btns & BTN_FROM_LEFT_4TH ) { $button = MOUSE_FORWARD }
            return ( $button, $is_release );
        }
        if    ( $btn == BTN_FROM_LEFT_1ST ) { $button = MOUSE_LEFT }
        elsif ( $btn == BTN_RIGHTMOST )     { $button = MOUSE_RIGHT }
        elsif ( $btn == BTN_FROM_LEFT_2ND ) { $button = MOUSE_MIDDLE }
        elsif ( $btn == BTN_FROM_LEFT_3RD ) { $button = MOUSE_BACKWARD }
        elsif ( $btn == BTN_FROM_LEFT_4TH ) { $button = MOUSE_FORWARD }
        return ( $button, $is_release );
    }

    sub _win32_mouse_event ( $prev_btns, $e ) {
        my $mod = 0;
        my $cks = $e->{cks} // 0;
        $mod |= MOD_ALT   if $cks & ( CKS_LEFT_ALT | CKS_RIGHT_ALT );
        $mod |= MOD_CTRL  if $cks & ( CKS_LEFT_CTRL | CKS_RIGHT_CTRL );
        $mod |= MOD_SHIFT if $cks & CKS_SHIFT;
        my $m         = { x => $e->{x} // 0, y => $e->{y} // 0, mod => $mod };
        my $wheel_dir = _win32_signed16( ( $e->{button_state} >> 16 ) & 0xFFFF );
        my $flags     = $e->{flags} // 0;
        my ( $button, $is_release ) = ( MOUSE_NONE, 0 );

        if ( $flags == 0 || $flags == EVF_DOUBLE_CLICK ) {
            ( $button, $is_release ) = _win32_mouse_button( $prev_btns, $e->{button_state} );
        }
        elsif ( $flags == EVF_WHEELED ) {
            $button = $wheel_dir > 0 ? MOUSE_WHEEL_UP : MOUSE_WHEEL_DOWN;
        }
        elsif ( $flags == EVF_HWHEELED ) {
            $button = $wheel_dir > 0 ? MOUSE_WHEEL_RIGHT : MOUSE_WHEEL_LEFT;
        }
        elsif ( $flags == EVF_MOUSE_MOVED ) {
            ($button) = _win32_mouse_button( $prev_btns, $e->{button_state} );
            return Cancer::Input::MouseMotionEvent->new( %$m, button => $button );
        }
        if ( $button >= MOUSE_WHEEL_UP && $button <= MOUSE_WHEEL_RIGHT ) {
            return Cancer::Input::MouseWheelEvent->new( %$m, button => $button );
        }
        elsif ($is_release) {
            return Cancer::Input::MouseReleaseEvent->new( %$m, button => $button );
        }
        return Cancer::Input::MouseClickEvent->new( %$m, button => $button );
    }

    # Mirrors Go's Parser.parseConInputEvent: dispatches a Windows Console API
    # InputRecord. Records are plain hashrefs:
    #   { type=>'key', vkc=>, scan=>, char=>, down=>bool, cks=>, repeat=> }
    #   { type=>'mouse', x=>, y=>, button_state=>, cks=>, flags=> }
    #   { type=>'focus', set=>bool }
    #   { type=>'window_size', w=>, h=> }
    #   { type=>'menu' }  (ignored)
    sub parse_con_input_event ( $self, $event, $state ) {
        my $type = ref($event) eq 'HASH' ? ( $event->{type} // '' ) : '';
        if ( $type eq 'key' ) {
            return scalar $self->_win32_key_event(
                $state,
                $event->{vkc}  // 0,
                $event->{scan} // 0,
                $event->{char},
                ( $event->{down} ? 1 : '' ),
                $event->{cks}    // 0,
                $event->{repeat} // 1
            );
        }
        if ( $type eq 'window_size' ) {
            my ( $w, $h ) = @{$event}{qw[w h]};
            if ( $w != $state->{last_winsize_x} || $h != $state->{last_winsize_y} ) {
                @$state{qw[last_winsize_x last_winsize_y]} = ( $w, $h );
                return Cancer::Input::WindowSizeEvent->new( width => $w, height => $h );
            }
            return undef;
        }
        if ( $type eq 'mouse' ) {
            my $ev = _win32_mouse_event( $state->{last_mouse_btns}, $event );
            $state->{last_mouse_btns} = $event->{button_state};
            return $ev;
        }
        if ( $type eq 'focus' ) {
            return $event->{set} ? Cancer::Input::FocusEvent->new : Cancer::Input::BlurEvent->new;
        }
        return undef;    # menu events are ignored
    }
    my %QUOTE_ESC;

    BEGIN {
        %QUOTE_ESC = ( 0x07 => '\\a', 0x08 => '\\b', 0x09 => '\\t', 0x0A => '\\n', 0x0B => '\\v', 0x0C => '\\f', 0x0D => '\\r' );
    }

    sub _quote_bytes ($s) {
        my $out = '"';
        for my $i ( 0 .. length($s) - 1 ) {
            my $o = ord substr( $s, $i, 1 );
            if    ( exists $QUOTE_ESC{$o} )    { $out .= $QUOTE_ESC{$o} }
            elsif ( $o == 0x22 || $o == 0x5C ) { $out .= '\\' . chr $o }
            elsif ( $o < 0x20 || $o == 0x7F )  { $out .= sprintf '\x%02X', $o }
            else                               { $out .= chr $o }
        }
        return "$out\"";
    }

    sub _keystroke ($k) {
        my ( $mod, $code ) = ( $k->{mod} // 0, $k->{code} // 0 );
        my $s = '';
        $s .= 'ctrl+'  if ( $mod & MOD_CTRL )  && $code != KEY_LEFT_CTRL  && $code != KEY_RIGHT_CTRL;
        $s .= 'alt+'   if ( $mod & MOD_ALT )   && $code != KEY_LEFT_ALT   && $code != KEY_RIGHT_ALT;
        $s .= 'shift+' if ( $mod & MOD_SHIFT ) && $code != KEY_LEFT_SHIFT && $code != KEY_RIGHT_SHIFT;
        $s .= 'meta+'  if ( $mod & MOD_META )  && $code != KEY_LEFT_META  && $code != KEY_RIGHT_META;
        $s .= 'hyper+' if ( $mod & MOD_HYPER ) && $code != KEY_LEFT_HYPER && $code != KEY_RIGHT_HYPER;
        $s .= 'super+' if ( $mod & MOD_SUPER ) && $code != KEY_LEFT_SUPER && $code != KEY_RIGHT_SUPER;

        if ( defined( my $kt = $KEY_TYPE_STRING{$code} ) ) {
            $s .= $kt;
        }
        else {
            my $c  = $code;
            my $bc = $k->{base_code} // 0;
            $c = $bc if $bc != 0;
            if    ( $c == KEY_SPACE )    { $s .= 'space' }
            elsif ( $c == KEY_EXTENDED ) { $s .= $k->{text} // '' }
            else                         { $s .= chr $c }
        }
        return $s;
    }

    sub _key_string ($k) {
        my $text = $k->{text} // '';
        return $text if length $text && $text ne ' ';
        return _keystroke($k);
    }

    sub _color_hex ($color) {
        return '' unless defined $color;
        return sprintf '#%02x%02x%02x', $color->[0] & 0xFF, $color->[1] & 0xFF, $color->[2] & 0xFF;
    }

    sub _rgb_to_hsl ( $r, $g, $b ) {
        my ( $rn, $gn, $bn ) = ( $r / 255, $g / 255, $b / 255 );
        my ( $ma, $mi ) = $rn > $gn ? ( $rn, $gn ) : ( $gn, $rn );
        if    ( $bn > $ma ) { $ma = $bn }
        elsif ( $bn < $mi ) { $mi = $bn }
        my $d = $ma - $mi;
        my $l = ( $ma + $mi ) / 2;
        my ( $h, $s ) = ( 0, 0 );
        if ( $d != 0 ) {
            if ( $ma == $rn ) {
                my $q = ( $gn - $bn ) / $d;
                $q -= 6 * int( $q / 6 );
                $h = 60 * $q;
            }
            elsif ( $ma == $gn ) { $h = 60 * ( ( $bn - $rn ) / $d + 2 ) }
            else                 { $h = 60 * ( ( $rn - $gn ) / $d + 4 ) }
            $h += 360 if $h < 0;
            $s = $d / ( 1 - abs( 2 * $l - 1 ) );
        }
        return ( $h, sprintf( '%.3f', $s ) + 0, sprintf( '%.3f', $l ) + 0 );
    }

    sub _is_dark_color ($color) {
        return 1 unless defined $color;
        my ( undef, undef, $l ) = _rgb_to_hsl( $color->[0] & 0xFF, $color->[1] & 0xFF, $color->[2] & 0xFF );
        return $l < 0.5 ? 1 : '';
    }

    sub build_keys_table ( $flags, $term = undef ) {
        $term //= '';
        my $nul = { code => KEY_SPACE, mod => MOD_CTRL };
        $nul = { code => ord '@', mod => MOD_CTRL } if $flags & FLAG_CTRL_AT;
        my $tab = { code => KEY_TAB };
        $tab = { code => ord 'i', mod => MOD_CTRL } if $flags & FLAG_CTRL_I;
        my $enter = { code => KEY_ENTER };
        $enter = { code => ord 'm', mod => MOD_CTRL } if $flags & FLAG_CTRL_M;
        my $esc = { code => KEY_ESCAPE };
        $esc = { code => ord '[', mod => MOD_CTRL } if $flags & FLAG_CTRL_OPEN_BRACKET;
        my $del = { code => KEY_BACKSPACE };
        $del = { code => KEY_DELETE } if $flags & FLAG_BACKSPACE;
        my $find = { code => KEY_HOME };
        $find = { code => KEY_FIND } if $flags & FLAG_FIND;
        my $sel = { code => KEY_END };
        $sel = { code => KEY_SELECT } if $flags & FLAG_SELECT;
        my %table = (
            "\x00"   => $nul,
            "\x01"   => { code => ord 'a', mod => MOD_CTRL },
            "\x02"   => { code => ord 'b', mod => MOD_CTRL },
            "\x03"   => { code => ord 'c', mod => MOD_CTRL },
            "\x04"   => { code => ord 'd', mod => MOD_CTRL },
            "\x05"   => { code => ord 'e', mod => MOD_CTRL },
            "\x06"   => { code => ord 'f', mod => MOD_CTRL },
            "\x07"   => { code => ord 'g', mod => MOD_CTRL },
            "\x08"   => { code => ord 'h', mod => MOD_CTRL },
            "\x09"   => $tab,
            "\x0a"   => { code => ord 'j', mod => MOD_CTRL },
            "\x0b"   => { code => ord 'k', mod => MOD_CTRL },
            "\x0c"   => { code => ord 'l', mod => MOD_CTRL },
            "\x0d"   => $enter,
            "\x0e"   => { code => ord 'n', mod => MOD_CTRL },
            "\x0f"   => { code => ord 'o', mod => MOD_CTRL },
            "\x10"   => { code => ord 'p', mod => MOD_CTRL },
            "\x11"   => { code => ord 'q', mod => MOD_CTRL },
            "\x12"   => { code => ord 'r', mod => MOD_CTRL },
            "\x13"   => { code => ord 's', mod => MOD_CTRL },
            "\x14"   => { code => ord 't', mod => MOD_CTRL },
            "\x15"   => { code => ord 'u', mod => MOD_CTRL },
            "\x16"   => { code => ord 'v', mod => MOD_CTRL },
            "\x17"   => { code => ord 'w', mod => MOD_CTRL },
            "\x18"   => { code => ord 'x', mod => MOD_CTRL },
            "\x19"   => { code => ord 'y', mod => MOD_CTRL },
            "\x1a"   => { code => ord 'z', mod => MOD_CTRL },
            "\x1b"   => $esc,
            "\x1c"   => { code => ord '\\',  mod  => MOD_CTRL },
            "\x1d"   => { code => ord ']',   mod  => MOD_CTRL },
            "\x1e"   => { code => ord '^',   mod  => MOD_CTRL },
            "\x1f"   => { code => ord '_',   mod  => MOD_CTRL },
            "\x20"   => { code => KEY_SPACE, text => ' ' },
            "\x7f"   => $del,
            "\e[Z"   => { code => KEY_TAB, mod => MOD_SHIFT },
            "\e[1~"  => $find,
            "\e[2~"  => { code => KEY_INSERT },
            "\e[3~"  => { code => KEY_DELETE },
            "\e[4~"  => $sel,
            "\e[5~"  => { code => KEY_PG_UP },
            "\e[6~"  => { code => KEY_PG_DOWN },
            "\e[7~"  => { code => KEY_HOME },
            "\e[8~"  => { code => KEY_END },
            "\e[A"   => { code => KEY_UP },
            "\e[B"   => { code => KEY_DOWN },
            "\e[C"   => { code => KEY_RIGHT },
            "\e[D"   => { code => KEY_LEFT },
            "\e[E"   => { code => KEY_BEGIN },
            "\e[F"   => { code => KEY_END },
            "\e[H"   => { code => KEY_HOME },
            "\e[P"   => { code => KEY_F1 },
            "\e[Q"   => { code => KEY_F2 },
            "\e[R"   => { code => KEY_F3 },
            "\e[S"   => { code => KEY_F4 },
            "\eOA"   => { code => KEY_UP },
            "\eOB"   => { code => KEY_DOWN },
            "\eOC"   => { code => KEY_RIGHT },
            "\eOD"   => { code => KEY_LEFT },
            "\eOE"   => { code => KEY_BEGIN },
            "\eOF"   => { code => KEY_END },
            "\eOH"   => { code => KEY_HOME },
            "\eOP"   => { code => KEY_F1 },
            "\eOQ"   => { code => KEY_F2 },
            "\eOR"   => { code => KEY_F3 },
            "\eOS"   => { code => KEY_F4 },
            "\eOM"   => { code => KEY_KP_ENTER },
            "\eOX"   => { code => KEY_KP_EQUAL },
            "\eOj"   => { code => KEY_KP_MULTIPLY },
            "\eOk"   => { code => KEY_KP_PLUS },
            "\eOl"   => { code => KEY_KP_COMMA },
            "\eOm"   => { code => KEY_KP_MINUS },
            "\eOn"   => { code => KEY_KP_DECIMAL },
            "\eOo"   => { code => KEY_KP_DIVIDE },
            "\eOp"   => { code => KEY_KP_0 },
            "\eOq"   => { code => KEY_KP_1 },
            "\eOr"   => { code => KEY_KP_2 },
            "\eOs"   => { code => KEY_KP_3 },
            "\eOt"   => { code => KEY_KP_4 },
            "\eOu"   => { code => KEY_KP_5 },
            "\eOv"   => { code => KEY_KP_6 },
            "\eOw"   => { code => KEY_KP_7 },
            "\eOx"   => { code => KEY_KP_8 },
            "\eOy"   => { code => KEY_KP_9 },
            "\e[11~" => { code => KEY_F1 },
            "\e[12~" => { code => KEY_F2 },
            "\e[13~" => { code => KEY_F3 },
            "\e[14~" => { code => KEY_F4 },
            "\e[15~" => { code => KEY_F5 },
            "\e[17~" => { code => KEY_F6 },
            "\e[18~" => { code => KEY_F7 },
            "\e[19~" => { code => KEY_F8 },
            "\e[20~" => { code => KEY_F9 },
            "\e[21~" => { code => KEY_F10 },
            "\e[23~" => { code => KEY_F11 },
            "\e[24~" => { code => KEY_F12 },
            "\e[25~" => { code => KEY_F13 },
            "\e[26~" => { code => KEY_F14 },
            "\e[28~" => { code => KEY_F15 },
            "\e[29~" => { code => KEY_F16 },
            "\e[31~" => { code => KEY_F17 },
            "\e[32~" => { code => KEY_F18 },
            "\e[33~" => { code => KEY_F19 },
            "\e[34~" => { code => KEY_F20 }
        );
        my %csi_tilde_keys = (
            1  => $find,
            2  => { code => KEY_INSERT },
            3  => { code => KEY_DELETE },
            4  => $sel,
            5  => { code => KEY_PG_UP },
            6  => { code => KEY_PG_DOWN },
            7  => { code => KEY_HOME },
            8  => { code => KEY_END },
            11 => { code => KEY_F1 },
            12 => { code => KEY_F2 },
            13 => { code => KEY_F3 },
            14 => { code => KEY_F4 },
            15 => { code => KEY_F5 },
            17 => { code => KEY_F6 },
            18 => { code => KEY_F7 },
            19 => { code => KEY_F8 },
            20 => { code => KEY_F9 },
            21 => { code => KEY_F10 },
            23 => { code => KEY_F11 },
            24 => { code => KEY_F12 },
            25 => { code => KEY_F13 },
            26 => { code => KEY_F14 },
            28 => { code => KEY_F15 },
            29 => { code => KEY_F16 },
            31 => { code => KEY_F17 },
            32 => { code => KEY_F18 },
            33 => { code => KEY_F19 },
            34 => { code => KEY_F20 }
        );
        $table{"\e[a"} = { code => KEY_UP,    mod => MOD_SHIFT };
        $table{"\e[b"} = { code => KEY_DOWN,  mod => MOD_SHIFT };
        $table{"\e[c"} = { code => KEY_RIGHT, mod => MOD_SHIFT };
        $table{"\e[d"} = { code => KEY_LEFT,  mod => MOD_SHIFT };
        $table{"\eOa"} = { code => KEY_UP,    mod => MOD_CTRL };
        $table{"\eOb"} = { code => KEY_DOWN,  mod => MOD_CTRL };
        $table{"\eOc"} = { code => KEY_RIGHT, mod => MOD_CTRL };
        $table{"\eOd"} = { code => KEY_LEFT,  mod => MOD_CTRL };

        for my $num ( sort { $a <=> $b } keys %csi_tilde_keys ) {
            my $key = $csi_tilde_keys{$num};
            $table{"\e[${num}\$"} = { %$key, mod => MOD_SHIFT };
            $table{"\e[${num}^"}  = { %$key, mod => MOD_CTRL };
            $table{"\e[${num}\@"} = { %$key, mod => MOD_SHIFT | MOD_CTRL };
        }
        $table{"\e[23\$"} = { code => KEY_F11, mod => MOD_SHIFT };
        $table{"\e[24\$"} = { code => KEY_F12, mod => MOD_SHIFT };
        $table{"\e[25\$"} = { code => KEY_F13, mod => MOD_SHIFT };
        $table{"\e[26\$"} = { code => KEY_F14, mod => MOD_SHIFT };
        $table{"\e[28\$"} = { code => KEY_F15, mod => MOD_SHIFT };
        $table{"\e[29\$"} = { code => KEY_F16, mod => MOD_SHIFT };
        $table{"\e[31\$"} = { code => KEY_F17, mod => MOD_SHIFT };
        $table{"\e[32\$"} = { code => KEY_F18, mod => MOD_SHIFT };
        $table{"\e[33\$"} = { code => KEY_F19, mod => MOD_SHIFT };
        $table{"\e[34\$"} = { code => KEY_F20, mod => MOD_SHIFT };
        $table{"\e[11^"}  = { code => KEY_F1,  mod => MOD_CTRL };
        $table{"\e[12^"}  = { code => KEY_F2,  mod => MOD_CTRL };
        $table{"\e[13^"}  = { code => KEY_F3,  mod => MOD_CTRL };
        $table{"\e[14^"}  = { code => KEY_F4,  mod => MOD_CTRL };
        $table{"\e[15^"}  = { code => KEY_F5,  mod => MOD_CTRL };
        $table{"\e[17^"}  = { code => KEY_F6,  mod => MOD_CTRL };
        $table{"\e[18^"}  = { code => KEY_F7,  mod => MOD_CTRL };
        $table{"\e[19^"}  = { code => KEY_F8,  mod => MOD_CTRL };
        $table{"\e[20^"}  = { code => KEY_F9,  mod => MOD_CTRL };
        $table{"\e[21^"}  = { code => KEY_F10, mod => MOD_CTRL };
        $table{"\e[23^"}  = { code => KEY_F11, mod => MOD_CTRL };
        $table{"\e[24^"}  = { code => KEY_F12, mod => MOD_CTRL };
        $table{"\e[25^"}  = { code => KEY_F13, mod => MOD_CTRL };
        $table{"\e[26^"}  = { code => KEY_F14, mod => MOD_CTRL };
        $table{"\e[28^"}  = { code => KEY_F15, mod => MOD_CTRL };
        $table{"\e[29^"}  = { code => KEY_F16, mod => MOD_CTRL };
        $table{"\e[31^"}  = { code => KEY_F17, mod => MOD_CTRL };
        $table{"\e[32^"}  = { code => KEY_F18, mod => MOD_CTRL };
        $table{"\e[33^"}  = { code => KEY_F19, mod => MOD_CTRL };
        $table{"\e[34^"}  = { code => KEY_F20, mod => MOD_CTRL };
        $table{"\e[23\@"} = { code => KEY_F11, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[24\@"} = { code => KEY_F12, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[25\@"} = { code => KEY_F13, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[26\@"} = { code => KEY_F14, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[28\@"} = { code => KEY_F15, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[29\@"} = { code => KEY_F16, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[31\@"} = { code => KEY_F17, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[32\@"} = { code => KEY_F18, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[33\@"} = { code => KEY_F19, mod => MOD_SHIFT | MOD_CTRL };
        $table{"\e[34\@"} = { code => KEY_F20, mod => MOD_SHIFT | MOD_CTRL };
        my %tmap;

        for my $seq ( sort keys %table ) {
            my $key = { %{ $table{$seq} } };
            $key->{mod} = ( $key->{mod} // 0 ) | MOD_ALT;
            delete $key->{text};
            $tmap{"\e$seq"} = $key;
        }
        $table{$_} = delete $tmap{$_} for keys %tmap;
        my @modifiers = (
            MOD_SHIFT,
            MOD_SHIFT | MOD_ALT,
            MOD_ALT,
            MOD_ALT | MOD_SHIFT,
            MOD_CTRL,
            MOD_CTRL | MOD_SHIFT,
            MOD_CTRL | MOD_ALT,
            MOD_CTRL | MOD_ALT | MOD_SHIFT,
            MOD_META,
            MOD_META | MOD_SHIFT,
            MOD_META | MOD_ALT,
            MOD_META | MOD_SHIFT | MOD_ALT,
            MOD_META | MOD_CTRL,
            MOD_META | MOD_SHIFT | MOD_CTRL,
            MOD_META | MOD_ALT | MOD_CTRL,
            MOD_META | MOD_SHIFT | MOD_ALT | MOD_CTRL
        );
        pop @modifiers;
        my %ss3_func_keys = (
            'M' => KEY_KP_ENTER,
            'X' => KEY_KP_EQUAL,
            'j' => KEY_KP_MULTIPLY,
            'k' => KEY_KP_PLUS,
            'l' => KEY_KP_COMMA,
            'm' => KEY_KP_MINUS,
            'n' => KEY_KP_DECIMAL,
            'o' => KEY_KP_DIVIDE,
            'p' => KEY_KP_0,
            'q' => KEY_KP_1,
            'r' => KEY_KP_2,
            's' => KEY_KP_3,
            't' => KEY_KP_4,
            'u' => KEY_KP_5,
            'v' => KEY_KP_6,
            'w' => KEY_KP_7,
            'x' => KEY_KP_8,
            'y' => KEY_KP_9
        );
        my %csi_func_keys = (
            'A' => KEY_UP,
            'B' => KEY_DOWN,
            'C' => KEY_RIGHT,
            'D' => KEY_LEFT,
            'E' => KEY_BEGIN,
            'F' => KEY_END,
            'H' => KEY_HOME,
            'P' => KEY_F1,
            'Q' => KEY_F2,
            'R' => KEY_F3,
            'S' => KEY_F4
        );
        my %modify_other_keys = ( 0x08 => KEY_BACKSPACE, 0x09 => KEY_TAB, 0x0D => KEY_ENTER, 0x1B => KEY_ESCAPE, 0x7F => KEY_BACKSPACE );
        for my $m (@modifiers) {
            my $xm = $m + 1;
            for my $ch ( sort keys %csi_func_keys ) {
                $table{"\e[1;$xm$ch"} = { code => $csi_func_keys{$ch}, mod => $m };
            }
            for my $ch ( sort keys %ss3_func_keys ) {
                $table{"\eO$xm$ch"} = { code => $ss3_func_keys{$ch}, mod => $m };
            }
            for my $num ( sort { $a <=> $b } keys %csi_tilde_keys ) {
                $table{"\e[$num;$xm~"} = { %{ $csi_tilde_keys{$num} }, mod => $m };
            }
            for my $code ( sort { $a <=> $b } keys %modify_other_keys ) {
                $table{"\e[27;$xm;$code~"} = { code => $modify_other_keys{$code}, mod => $m };
            }
        }
        return \%table;
    }
}

package Cancer::Input::Event {
    sub new    ( $class, %fields ) { bless \%fields, $class }
    sub string ($self)             { ref $self }
}

sub Cancer::Input::_mkclass ( $name, $fields ) {
    my $pkg = "Cancer::Input::$name";
    no strict 'refs';
    @{"${pkg}::ISA"} = ('Cancer::Input::Event');

    # Numeric fields mirror Go's zero values so arithmetic like
    # "$e->mod & MOD_CTRL" never sees undef.
    my %numeric = map { $_ => 1 } qw[mod code shifted_code base_code is_repeat x y button width height];
    for my $field (@$fields) {
        *{"${pkg}::$field"} = $numeric{$field} ? sub { $_[0]->{$field} // 0 } : sub { $_[0]->{$field} };
    }
}
Cancer::Input::_mkclass( 'UnknownEvent',                 ['bytes'] );
Cancer::Input::_mkclass( 'MultiEvent',                   ['events'] );
Cancer::Input::_mkclass( 'KeyPressEvent',                [qw[text mod code shifted_code base_code is_repeat]] );
Cancer::Input::_mkclass( 'KeyReleaseEvent',              [qw[text mod code shifted_code base_code is_repeat]] );
Cancer::Input::_mkclass( 'FocusEvent',                   [] );
Cancer::Input::_mkclass( 'BlurEvent',                    [] );
Cancer::Input::_mkclass( 'PasteStartEvent',              [] );
Cancer::Input::_mkclass( 'PasteEndEvent',                [] );
Cancer::Input::_mkclass( 'PasteEvent',                   ['content'] );
Cancer::Input::_mkclass( 'CursorPositionEvent',          [qw[x y]] );
Cancer::Input::_mkclass( 'WindowOpEvent',                [qw[op args]] );
Cancer::Input::_mkclass( 'ModeReportEvent',              [qw[mode value dec]] );
Cancer::Input::_mkclass( 'PrimaryDeviceAttributesEvent', ['attrs'] );
Cancer::Input::_mkclass( 'KittyEnhancementsEvent',       ['flags'] );
Cancer::Input::_mkclass( 'ModifyOtherKeysEvent',         ['value'] );
Cancer::Input::_mkclass( 'TerminalVersionEvent',         ['version'] );
Cancer::Input::_mkclass( 'ClipboardEvent',               [qw[selection content]] );
Cancer::Input::_mkclass( 'ForegroundColorEvent',         ['color'] );
Cancer::Input::_mkclass( 'BackgroundColorEvent',         ['color'] );
Cancer::Input::_mkclass( 'CursorColorEvent',             ['color'] );
Cancer::Input::_mkclass( 'CapabilityEvent',              ['value'] );
Cancer::Input::_mkclass( 'KittyGraphicsEvent',           [qw[options payload]] );
Cancer::Input::_mkclass( 'MouseClickEvent',              [qw[x y button mod]] );
Cancer::Input::_mkclass( 'MouseReleaseEvent',            [qw[x y button mod]] );
Cancer::Input::_mkclass( 'MouseWheelEvent',              [qw[x y button mod]] );
Cancer::Input::_mkclass( 'MouseMotionEvent',             [qw[x y button mod]] );
Cancer::Input::_mkclass( 'WindowSizeEvent',              [qw[width height]] );
sub Cancer::Input::KeyPressEvent::string      ($self) { Cancer::Input::_key_string($self) }
sub Cancer::Input::KeyPressEvent::keystroke   ($self) { Cancer::Input::_keystroke($self) }
sub Cancer::Input::KeyReleaseEvent::string    ($self) { Cancer::Input::_key_string($self) }
sub Cancer::Input::KeyReleaseEvent::keystroke ($self) { Cancer::Input::_keystroke($self) }
sub Cancer::Input::MouseClickEvent::string    ($self) { Cancer::Input::_mouse_string($self) }
sub Cancer::Input::MouseReleaseEvent::string  ($self) { Cancer::Input::_mouse_string($self) }
sub Cancer::Input::MouseWheelEvent::string    ($self) { Cancer::Input::_mouse_string($self) }

sub Cancer::Input::MouseMotionEvent::string ($self) {
    my $s = Cancer::Input::_mouse_string($self);
    return ( $self->{button} // 0 ) ? "${s}+motion" : "${s}motion";
}
for my $cls (qw[ForegroundColorEvent BackgroundColorEvent CursorColorEvent]) {
    no strict 'refs';
    *{"Cancer::Input::$cls\::string"}  = sub ($self) { Cancer::Input::_color_hex( $self->{color} ) };
    *{"Cancer::Input::$cls\::is_dark"} = sub ($self) { Cancer::Input::_is_dark_color( $self->{color} ) ? 1 : '' };
}
sub Cancer::Input::ClipboardEvent::string ($self) { $self->{content} // '' }
sub Cancer::Input::UnknownEvent::string   ($self) { Cancer::Input::_quote_bytes( $self->{bytes} // '' ) }

sub Cancer::Input::MultiEvent::string ($self) {
    join '', map { $_->string . "\n" } @{ $self->{events} // [] };
}
