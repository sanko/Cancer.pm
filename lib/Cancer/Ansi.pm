use v5.42;

package Cancer::Ansi v0.0.1 {
    use Exporter qw[import];
    use MIME::Base64;
    our @EXPORT_OK = qw[
        ScreenPassthrough TmuxPassthrough
        URxvtExt
        ITerm2
        set_foreground_color set_background_color set_cursor_color
        request_foreground_color request_background_color request_cursor_color
        reset_foreground_color reset_background_color reset_cursor_color
        SYSTEM_CLIPBOARD PRIMARY_CLIPBOARD
        set_clipboard set_system_clipboard set_primary_clipboard
        reset_clipboard
        RESET_SYSTEM_CLIPBOARD RESET_PRIMARY_CLIPBOARD
        request_clipboard
        REQUEST_SYSTEM_CLIPBOARD REQUEST_PRIMARY_CLIPBOARD
        set_hyperlink reset_hyperlink
        set_icon_name_window_title set_icon_name set_window_title
        decswt decsin
        notify_working_directory
        kitty_graphics
        ModeNotRecognized ModeSet ModeReset ModePermanentlySet ModePermanentlyReset
        mode_is_not_recognized mode_is_set mode_is_reset
        mode_is_permanently_set mode_is_permanently_reset
        mode_is_dec mode_num
        set_mode reset_mode request_mode report_mode
        ModeKeyboardAction KAM ModeInsertReplace IRM
        ModeBiDirectionalSupport BDSM
        ModeSendReceive ModeLocalEcho SRM
        ModeLineFeedNewLine LNM
        ModeCursorKeys DECCKM ModeOrigin DECOM
        ModeAutoWrap DECAWM ModeMouseX10
        ModeTextCursorEnable DECTCEM ShowCursor HideCursor
        ModeNumericKeypad DECNKM ModeBackarrowKey DECBKM
        ModeLeftRightMargin DECLRMM
        ModeMouseNormal ModeMouseHighlight ModeMouseButtonEvent ModeMouseAnyEvent
        ModeFocusEvent ModeMouseExtSgr ModeMouseExtUtf8 ModeMouseExtUrxvt ModeMouseExtSgrPixel
        ModeAltScreen ModeSaveCursor ModeAltScreenSaveCursor
        ModeBracketedPaste ModeSynchronizedOutput ModeUnicodeCore
        ModeLightDark ModeInBandResize ModeWin32Input
        MouseNone MouseLeft MouseMiddle MouseRight
        MouseWheelUp MouseWheelDown MouseWheelLeft MouseWheelRight
        MouseBackward MouseForward
        MouseButton1 MouseButton2 MouseButton3 MouseButton4 MouseButton5
        MouseButton6 MouseButton7 MouseButton8 MouseButton9 MouseButton10 MouseButton11
        MouseRelease
        encode_mouse_button mouse_sgr
        notify desktop_notification
        SelectGraphicRendition SGR
        AttrReset AttrBold AttrFaint AttrItalic AttrUnderline
        AttrBlink AttrRapidBlink AttrReverse AttrConceal AttrStrikethrough
        AttrNormalIntensity AttrNoItalic AttrNoUnderline AttrNoBlink
        AttrNoReverse AttrNoConceal AttrNoStrikethrough
        AttrBlackForegroundColor AttrRedForegroundColor AttrGreenForegroundColor
        AttrYellowForegroundColor AttrBlueForegroundColor AttrMagentaForegroundColor
        AttrCyanForegroundColor AttrWhiteForegroundColor
        AttrExtendedForegroundColor AttrDefaultForegroundColor
        AttrBlackBackgroundColor AttrRedBackgroundColor AttrGreenBackgroundColor
        AttrYellowBackgroundColor AttrBlueBackgroundColor AttrMagentaBackgroundColor
        AttrCyanBackgroundColor AttrWhiteBackgroundColor
        AttrExtendedBackgroundColor AttrDefaultBackgroundColor
        AttrExtendedUnderlineColor AttrDefaultUnderlineColor
        AttrBrightBlackForegroundColor AttrBrightRedForegroundColor
        AttrBrightGreenForegroundColor AttrBrightYellowForegroundColor
        AttrBrightBlueForegroundColor AttrBrightMagentaForegroundColor
        AttrBrightCyanForegroundColor AttrBrightWhiteForegroundColor
        AttrBrightBlackBackgroundColor AttrBrightRedBackgroundColor
        AttrBrightGreenBackgroundColor AttrBrightYellowBackgroundColor
        AttrBrightBlueBackgroundColor AttrBrightMagentaBackgroundColor
        AttrBrightCyanBackgroundColor AttrBrightWhiteBackgroundColor
        ResetAttr BoldAttr FaintAttr ItalicAttr UnderlineAttr
        SlowBlinkAttr RapidBlinkAttr ReverseAttr ConcealAttr StrikethroughAttr
        NormalIntensityAttr NoItalicAttr NoUnderlineAttr NoBlinkAttr
        NoReverseAttr NoConcealAttr NoStrikethroughAttr
        BlackForegroundColorAttr RedForegroundColorAttr GreenForegroundColorAttr
        YellowForegroundColorAttr BlueForegroundColorAttr MagentaForegroundColorAttr
        CyanForegroundColorAttr WhiteForegroundColorAttr
        ExtendedForegroundColorAttr DefaultForegroundColorAttr
        BlackBackgroundColorAttr RedBackgroundColorAttr GreenBackgroundColorAttr
        YellowBackgroundColorAttr BlueBackgroundColorAttr MagentaBackgroundColorAttr
        CyanBackgroundColorAttr WhiteBackgroundColorAttr
        ExtendedBackgroundColorAttr DefaultBackgroundColorAttr
        ExtendedUnderlineColorAttr DefaultUnderlineColorAttr
        BrightBlackForegroundColorAttr BrightRedForegroundColorAttr
        BrightGreenForegroundColorAttr BrightYellowForegroundColorAttr
        BrightBlueForegroundColorAttr BrightMagentaForegroundColorAttr
        BrightCyanForegroundColorAttr BrightWhiteForegroundColorAttr
        BrightBlackBackgroundColorAttr BrightRedBackgroundColorAttr
        BrightGreenBackgroundColorAttr BrightYellowBackgroundColorAttr
        BrightBlueBackgroundColorAttr BrightMagentaBackgroundColorAttr
        BrightCyanBackgroundColorAttr BrightWhiteBackgroundColorAttr
        RGBColorIntroducerAttr ExtendedColorIntroducerAttr
        AttrRGBColorIntroducer AttrExtendedColorIntroducer
        color_to_hex_string
        hex_to_rgb ansi_to_rgb
        convert_256
        set_palette ResetPalette
        ResetProgressBar set_progress_bar
        set_error_progress_bar SetIndeterminateProgressBar
        set_warning_progress_bar
    ];

    # Fore and Background
    sub set_foreground_color ($s) {"\e]10;$s\a"}
    sub set_background_color ($s) {"\e]11;$s\a"}
    sub set_cursor_color     ($s) {"\e]12;$s\a"}
    sub request_foreground_color () {"\e]10;?\a"}
    sub request_background_color () {"\e]11;?\a"}
    sub request_cursor_color ()     {"\e]12;?\a"}
    sub reset_foreground_color ()   {"\e]110\a"}
    sub reset_background_color ()   {"\e]111\a"}
    sub reset_cursor_color ()       {"\e]112\a"}

    # Clipboard
    use constant SYSTEM_CLIPBOARD  => 'c';
    use constant PRIMARY_CLIPBOARD => 'p';

    sub set_clipboard ( $c, $d ) {
        $d = MIME::Base64::encode_base64( $d, '' ) if length $d;
        "\e]52;$c;$d\a";
    }
    sub set_system_clipboard  ($d) { set_clipboard( SYSTEM_CLIPBOARD,  $d ) }
    sub set_primary_clipboard ($d) { set_clipboard( PRIMARY_CLIPBOARD, $d ) }
    sub reset_clipboard       ($c) { set_clipboard( $c,                '' ) }
    use constant RESET_SYSTEM_CLIPBOARD  => "\e]52;c;\a";
    use constant RESET_PRIMARY_CLIPBOARD => "\e]52;p;\a";
    sub request_clipboard ($c) {"\e]52;$c;?\a"}
    use constant REQUEST_SYSTEM_CLIPBOARD  => "\e]52;c;?\a";
    use constant REQUEST_PRIMARY_CLIPBOARD => "\e]52;p;?\a";

    # Hyperlink
    sub set_hyperlink ( $uri, @params ) {
        my $p = @params ? join( ':', @params ) : '';
        "\e]8;$p;$uri\a";
    }
    sub reset_hyperlink (@params) { set_hyperlink( '', @params ) }

    # Title
    sub set_icon_name_window_title ($s)    {"\e]0;$s\a"}
    sub set_icon_name              ($s)    {"\e]1;$s\a"}
    sub set_window_title           ($s)    {"\e]2;$s\a"}
    sub decswt                     ($name) { set_window_title("1;$name") }
    sub decsin                     ($name) { set_window_title("L;$name") }

    # CWD
    sub notify_working_directory ( $host, @paths ) { "\e]7;file://$host/" . join( '/', @paths ) . "\a" }

    # Graphics
    sub kitty_graphics ( $payload, @opts ) {
        my $p = @opts ? join( ',', @opts ) : '';
        $p .= ";$payload" if length $payload;
        "\e_G${p}\e\\";
    }

    # Mode
    use constant ModeNotRecognized    => 0;
    use constant ModeSet              => 1;
    use constant ModeReset            => 2;
    use constant ModePermanentlySet   => 3;
    use constant ModePermanentlyReset => 4;
    sub mode_is_not_recognized ($m) { 0 + ( $m == ModeNotRecognized ) }
    sub mode_is_set               ($m) { 0 + ( $m == ModeSet   || $m == ModePermanentlySet ) }
    sub mode_is_reset             ($m) { 0 + ( $m == ModeReset || $m == ModePermanentlyReset ) }
    sub mode_is_permanently_set   ($m) { 0 + ( $m == ModePermanentlySet ) }
    sub mode_is_permanently_reset ($m) { 0 + ( $m == ModePermanentlyReset ) }

    # Mode representation: [$number, $is_dec]
    sub mode_is_dec ($m)     { $m->[1] }
    sub mode_num    ($m)     { $m->[0] }
    sub set_mode    (@modes) { _mode_seq( 0, @modes ) }
    sub reset_mode  (@modes) { _mode_seq( 1, @modes ) }

    sub _mode_seq ( $reset, @modes ) {
        return '' if !@modes;
        my $op   = $reset ? 'l' : 'h';
        my @ansi = map { $_->[0] } grep { !$_->[1] } @modes;
        my @dec  = map { $_->[0] } grep { $_->[1] } @modes;
        my $s    = '';
        $s .= "\e[" . join( ';', @ansi ) . $op if @ansi;
        $s .= "\e[?" . join( ';', @dec ) . $op if @dec;
        return $s;
    }

    sub request_mode ($m) {
        my $pre = mode_is_dec($m) ? '?' : '';
        "\e[${pre}" . mode_num($m) . '$p';
    }

    sub report_mode ( $m, $val ) {
        $val = ModeNotRecognized if $val > 4 || $val < 0;
        my $pre = mode_is_dec($m) ? '?' : '';
        "\e[${pre}" . mode_num($m) . ";$val" . '$y';
    }

    # ANSI Mode Constants ( [number, 0] )
    use constant ModeKeyboardAction       => [ 2,  0 ];
    use constant KAM                      => [ 2,  0 ];
    use constant ModeInsertReplace        => [ 4,  0 ];
    use constant IRM                      => [ 4,  0 ];
    use constant ModeBiDirectionalSupport => [ 8,  0 ];
    use constant BDSM                     => [ 8,  0 ];
    use constant ModeSendReceive          => [ 12, 0 ];
    use constant ModeLocalEcho            => [ 12, 0 ];
    use constant SRM                      => [ 12, 0 ];
    use constant ModeLineFeedNewLine      => [ 20, 0 ];
    use constant LNM                      => [ 20, 0 ];

    # DEC Mode Constants ( [number, 1] )
    use constant ModeCursorKeys          => [ 1,  1 ];
    use constant DECCKM                  => [ 1,  1 ];
    use constant ModeOrigin              => [ 6,  1 ];
    use constant DECOM                   => [ 6,  1 ];
    use constant ModeAutoWrap            => [ 7,  1 ];
    use constant DECAWM                  => [ 7,  1 ];
    use constant ModeMouseX10            => [ 9,  1 ];
    use constant ModeTextCursorEnable    => [ 25, 1 ];
    use constant DECTCEM                 => [ 25, 1 ];
    use constant ShowCursor              => "\e[?25h";
    use constant HideCursor              => "\e[?25l";
    use constant ModeNumericKeypad       => [ 66,   1 ];
    use constant DECNKM                  => [ 66,   1 ];
    use constant ModeBackarrowKey        => [ 67,   1 ];
    use constant DECBKM                  => [ 67,   1 ];
    use constant ModeLeftRightMargin     => [ 69,   1 ];
    use constant DECLRMM                 => [ 69,   1 ];
    use constant ModeMouseNormal         => [ 1000, 1 ];
    use constant ModeMouseHighlight      => [ 1001, 1 ];
    use constant ModeMouseButtonEvent    => [ 1002, 1 ];
    use constant ModeMouseAnyEvent       => [ 1003, 1 ];
    use constant ModeFocusEvent          => [ 1004, 1 ];
    use constant ModeMouseExtUtf8        => [ 1005, 1 ];
    use constant ModeMouseExtSgr         => [ 1006, 1 ];
    use constant ModeMouseExtUrxvt       => [ 1015, 1 ];
    use constant ModeMouseExtSgrPixel    => [ 1016, 1 ];
    use constant ModeAltScreen           => [ 1047, 1 ];
    use constant ModeSaveCursor          => [ 1048, 1 ];
    use constant ModeAltScreenSaveCursor => [ 1049, 1 ];
    use constant ModeBracketedPaste      => [ 2004, 1 ];
    use constant ModeSynchronizedOutput  => [ 2026, 1 ];
    use constant ModeUnicodeCore         => [ 2027, 1 ];
    use constant ModeLightDark           => [ 2031, 1 ];
    use constant ModeInBandResize        => [ 2048, 1 ];
    use constant ModeWin32Input          => [ 9001, 1 ];

    # Mouse
    use constant MouseNone       => 0;
    use constant MouseLeft       => 1;
    use constant MouseMiddle     => 2;
    use constant MouseRight      => 3;
    use constant MouseWheelUp    => 4;
    use constant MouseWheelDown  => 5;
    use constant MouseWheelLeft  => 6;
    use constant MouseWheelRight => 7;
    use constant MouseBackward   => 8;
    use constant MouseForward    => 9;
    use constant MouseButton1    => 1;
    use constant MouseButton2    => 2;
    use constant MouseButton3    => 3;
    use constant MouseButton4    => 4;
    use constant MouseButton5    => 5;
    use constant MouseButton6    => 6;
    use constant MouseButton7    => 7;
    use constant MouseButton8    => 8;
    use constant MouseButton9    => 9;
    use constant MouseButton10   => 10;
    use constant MouseButton11   => 11;
    use constant MouseRelease    => 0;
    use constant B_SHIFT         => 0b0000_0100;
    use constant B_ALT           => 0b0000_1000;
    use constant B_CTRL          => 0b0001_0000;
    use constant B_MOTION        => 0b0010_0000;
    use constant B_WHEEL         => 0b0100_0000;
    use constant B_ADD           => 0b1000_0000;
    use constant B_MASK          => 0b0000_0011;

    sub encode_mouse_button ( $btn, $motion, $shift, $alt, $ctrl ) {
        my $m;
        if    ( $btn == MouseNone ) { $m = B_MASK }
        elsif ( $btn >= MouseLeft && $btn <= MouseRight ) {
            $m = $btn - MouseLeft;
        }
        elsif ( $btn >= MouseWheelUp && $btn <= MouseWheelRight ) {
            $m = $btn - MouseWheelUp;
            $m |= B_WHEEL;
        }
        elsif ( $btn >= MouseBackward && $btn <= MouseButton11 ) {
            $m = $btn - MouseBackward;
            $m |= B_ADD;
        }
        else { $m = 0xFF }
        $m |= B_SHIFT  if $shift;
        $m |= B_ALT    if $alt;
        $m |= B_CTRL   if $ctrl;
        $m |= B_MOTION if $motion;
        return $m;
    }

    sub mouse_sgr ( $b, $x, $y, $release ) {
        $x = -$x if $x < 0;
        $y = -$y if $y < 0;
        my $s = $release ? 'm' : 'M';
        "\e[<$b;" . ( $x + 1 ) . ';' . ( $y + 1 ) . $s;
    }

    # Notification
    sub notify               ($s)                    {"\e]9;$s\a"}
    sub desktop_notification ( $payload, @metadata ) { "\e]99;" . join( ':', @metadata ) . ";$payload\a" }

    # SGR
    use constant AttrReset                        => 0;
    use constant AttrBold                         => 1;
    use constant AttrFaint                        => 2;
    use constant AttrItalic                       => 3;
    use constant AttrUnderline                    => 4;
    use constant AttrBlink                        => 5;
    use constant AttrRapidBlink                   => 6;
    use constant AttrReverse                      => 7;
    use constant AttrConceal                      => 8;
    use constant AttrStrikethrough                => 9;
    use constant AttrNormalIntensity              => 22;
    use constant AttrNoItalic                     => 23;
    use constant AttrNoUnderline                  => 24;
    use constant AttrNoBlink                      => 25;
    use constant AttrNoReverse                    => 27;
    use constant AttrNoConceal                    => 28;
    use constant AttrNoStrikethrough              => 29;
    use constant AttrBlackForegroundColor         => 30;
    use constant AttrRedForegroundColor           => 31;
    use constant AttrGreenForegroundColor         => 32;
    use constant AttrYellowForegroundColor        => 33;
    use constant AttrBlueForegroundColor          => 34;
    use constant AttrMagentaForegroundColor       => 35;
    use constant AttrCyanForegroundColor          => 36;
    use constant AttrWhiteForegroundColor         => 37;
    use constant AttrExtendedForegroundColor      => 38;
    use constant AttrDefaultForegroundColor       => 39;
    use constant AttrBlackBackgroundColor         => 40;
    use constant AttrRedBackgroundColor           => 41;
    use constant AttrGreenBackgroundColor         => 42;
    use constant AttrYellowBackgroundColor        => 43;
    use constant AttrBlueBackgroundColor          => 44;
    use constant AttrMagentaBackgroundColor       => 45;
    use constant AttrCyanBackgroundColor          => 46;
    use constant AttrWhiteBackgroundColor         => 47;
    use constant AttrExtendedBackgroundColor      => 48;
    use constant AttrDefaultBackgroundColor       => 49;
    use constant AttrExtendedUnderlineColor       => 58;
    use constant AttrDefaultUnderlineColor        => 59;
    use constant AttrBrightBlackForegroundColor   => 90;
    use constant AttrBrightRedForegroundColor     => 91;
    use constant AttrBrightGreenForegroundColor   => 92;
    use constant AttrBrightYellowForegroundColor  => 93;
    use constant AttrBrightBlueForegroundColor    => 94;
    use constant AttrBrightMagentaForegroundColor => 95;
    use constant AttrBrightCyanForegroundColor    => 96;
    use constant AttrBrightWhiteForegroundColor   => 97;
    use constant AttrBrightBlackBackgroundColor   => 100;
    use constant AttrBrightRedBackgroundColor     => 101;
    use constant AttrBrightGreenBackgroundColor   => 102;
    use constant AttrBrightYellowBackgroundColor  => 103;
    use constant AttrBrightBlueBackgroundColor    => 104;
    use constant AttrBrightMagentaBackgroundColor => 105;
    use constant AttrBrightCyanBackgroundColor    => 106;
    use constant AttrBrightWhiteBackgroundColor   => 107;
    use constant AttrRGBColorIntroducer           => 2;
    use constant AttrExtendedColorIntroducer      => 5;

    sub SelectGraphicRendition {
        return "\e[m" if !@_;
        my @parts;
        for my $a (@_) {
            $a = 0 if $a < 0;
            push @parts, 0 + $a;
        }
        return "\e[" . join( ';', @parts ) . "m";
    }
    sub SGR { SelectGraphicRendition(@_) }

    # Passthrough
    sub ScreenPassthrough ( $seq, $limit = 0 ) {
        my $b = "\x1bP";
        if ( $limit > 0 ) {
            for ( my $i = 0; $i < length $seq; $i += $limit ) {
                my $end = $i + $limit;
                $end = length $seq if $end > length $seq;
                $b .= substr( $seq, $i, $end - $i );
                $b .= "\x1b\\\x1bP" if $end < length $seq;
            }
        }
        else {
            $b .= $seq;
        }
        $b .= "\x1b\\";
        return $b;
    }

    sub TmuxPassthrough ($seq) {
        my $b = "\x1bPtmux;";
        for my $ch ( split //, $seq ) {
            $b .= "\x1b" if $ch eq "\x1b";
            $b .= $ch;
        }
        $b .= "\x1b\\";
        return $b;
    }

    # URxvt
    sub URxvtExt ( $extension, @params ) { return "\x1b]777;$extension;" . join( ';', @params ) . "\x07" }

    # iTerm2
    sub ITerm2 ($data) {
        return "\x1b]1337;$data\x07";
    }

    # Color
    sub color_to_hex_string ($hex) {
        sprintf "#%06x", $hex;
    }

    sub hex_to_rgb ($hex) {
        ( $hex >> 16 & 0xff, $hex >> 8 & 0xff, $hex & 0xff )
    }
    my @ANSI_HEX;

    BEGIN {
        @ANSI_HEX = (
            { r => 0x00, g => 0x00, b => 0x00 },    #   0 black
            { r => 0x80, g => 0x00, b => 0x00 },    #   1 red
            { r => 0x00, g => 0x80, b => 0x00 },    #   2 green
            { r => 0x80, g => 0x80, b => 0x00 },    #   3 yellow
            { r => 0x00, g => 0x00, b => 0x80 },    #   4 blue
            { r => 0x80, g => 0x00, b => 0x80 },    #   5 magenta
            { r => 0x00, g => 0x80, b => 0x80 },    #   6 cyan
            { r => 0xc0, g => 0xc0, b => 0xc0 },    #   7 white
            { r => 0x80, g => 0x80, b => 0x80 },    #   8 bright black
            { r => 0xff, g => 0x00, b => 0x00 },    #   9 bright red
            { r => 0x00, g => 0xff, b => 0x00 },    #  10 bright green
            { r => 0xff, g => 0xff, b => 0x00 },    #  11 bright yellow
            { r => 0x00, g => 0x00, b => 0xff },    #  12 bright blue
            { r => 0xff, g => 0x00, b => 0xff },    #  13 bright magenta
            { r => 0x00, g => 0xff, b => 0xff },    #  14 bright cyan
            { r => 0xff, g => 0xff, b => 0xff },    #  15 bright white
            { r => 0x00, g => 0x00, b => 0x00 },    #  16
            { r => 0x00, g => 0x00, b => 0x5f },    #  17
            { r => 0x00, g => 0x00, b => 0x87 },    #  18
            { r => 0x00, g => 0x00, b => 0xaf },    #  19
            { r => 0x00, g => 0x00, b => 0xd7 },    #  20
            { r => 0x00, g => 0x00, b => 0xff },    #  21
            { r => 0x00, g => 0x5f, b => 0x00 },    #  22
            { r => 0x00, g => 0x5f, b => 0x5f },    #  23
            { r => 0x00, g => 0x5f, b => 0x87 },    #  24
            { r => 0x00, g => 0x5f, b => 0xaf },    #  25
            { r => 0x00, g => 0x5f, b => 0xd7 },    #  26
            { r => 0x00, g => 0x5f, b => 0xff },    #  27
            { r => 0x00, g => 0x87, b => 0x00 },    #  28
            { r => 0x00, g => 0x87, b => 0x5f },    #  29
            { r => 0x00, g => 0x87, b => 0x87 },    #  30
            { r => 0x00, g => 0x87, b => 0xaf },    #  31
            { r => 0x00, g => 0x87, b => 0xd7 },    #  32
            { r => 0x00, g => 0x87, b => 0xff },    #  33
            { r => 0x00, g => 0xaf, b => 0x00 },    #  34
            { r => 0x00, g => 0xaf, b => 0x5f },    #  35
            { r => 0x00, g => 0xaf, b => 0x87 },    #  36
            { r => 0x00, g => 0xaf, b => 0xaf },    #  37
            { r => 0x00, g => 0xaf, b => 0xd7 },    #  38
            { r => 0x00, g => 0xaf, b => 0xff },    #  39
            { r => 0x00, g => 0xd7, b => 0x00 },    #  40
            { r => 0x00, g => 0xd7, b => 0x5f },    #  41
            { r => 0x00, g => 0xd7, b => 0x87 },    #  42
            { r => 0x00, g => 0xd7, b => 0xaf },    #  43
            { r => 0x00, g => 0xd7, b => 0xd7 },    #  44
            { r => 0x00, g => 0xd7, b => 0xff },    #  45
            { r => 0x00, g => 0xff, b => 0x00 },    #  46
            { r => 0x00, g => 0xff, b => 0x5f },    #  47
            { r => 0x00, g => 0xff, b => 0x87 },    #  48
            { r => 0x00, g => 0xff, b => 0xaf },    #  49
            { r => 0x00, g => 0xff, b => 0xd7 },    #  50
            { r => 0x00, g => 0xff, b => 0xff },    #  51
            { r => 0x5f, g => 0x00, b => 0x00 },    #  52
            { r => 0x5f, g => 0x00, b => 0x5f },    #  53
            { r => 0x5f, g => 0x00, b => 0x87 },    #  54
            { r => 0x5f, g => 0x00, b => 0xaf },    #  55
            { r => 0x5f, g => 0x00, b => 0xd7 },    #  56
            { r => 0x5f, g => 0x00, b => 0xff },    #  57
            { r => 0x5f, g => 0x5f, b => 0x00 },    #  58
            { r => 0x5f, g => 0x5f, b => 0x5f },    #  59
            { r => 0x5f, g => 0x5f, b => 0x87 },    #  60
            { r => 0x5f, g => 0x5f, b => 0xaf },    #  61
            { r => 0x5f, g => 0x5f, b => 0xd7 },    #  62
            { r => 0x5f, g => 0x5f, b => 0xff },    #  63
            { r => 0x5f, g => 0x87, b => 0x00 },    #  64
            { r => 0x5f, g => 0x87, b => 0x5f },    #  65
            { r => 0x5f, g => 0x87, b => 0x87 },    #  66
            { r => 0x5f, g => 0x87, b => 0xaf },    #  67
            { r => 0x5f, g => 0x87, b => 0xd7 },    #  68
            { r => 0x5f, g => 0x87, b => 0xff },    #  69
            { r => 0x5f, g => 0xaf, b => 0x00 },    #  70
            { r => 0x5f, g => 0xaf, b => 0x5f },    #  71
            { r => 0x5f, g => 0xaf, b => 0x87 },    #  72
            { r => 0x5f, g => 0xaf, b => 0xaf },    #  73
            { r => 0x5f, g => 0xaf, b => 0xd7 },    #  74
            { r => 0x5f, g => 0xaf, b => 0xff },    #  75
            { r => 0x5f, g => 0xd7, b => 0x00 },    #  76
            { r => 0x5f, g => 0xd7, b => 0x5f },    #  77
            { r => 0x5f, g => 0xd7, b => 0x87 },    #  78
            { r => 0x5f, g => 0xd7, b => 0xaf },    #  79
            { r => 0x5f, g => 0xd7, b => 0xd7 },    #  80
            { r => 0x5f, g => 0xd7, b => 0xff },    #  81
            { r => 0x5f, g => 0xff, b => 0x00 },    #  82
            { r => 0x5f, g => 0xff, b => 0x5f },    #  83
            { r => 0x5f, g => 0xff, b => 0x87 },    #  84
            { r => 0x5f, g => 0xff, b => 0xaf },    #  85
            { r => 0x5f, g => 0xff, b => 0xd7 },    #  86
            { r => 0x5f, g => 0xff, b => 0xff },    #  87
            { r => 0x87, g => 0x00, b => 0x00 },    #  88
            { r => 0x87, g => 0x00, b => 0x5f },    #  89
            { r => 0x87, g => 0x00, b => 0x87 },    #  90
            { r => 0x87, g => 0x00, b => 0xaf },    #  91
            { r => 0x87, g => 0x00, b => 0xd7 },    #  92
            { r => 0x87, g => 0x00, b => 0xff },    #  93
            { r => 0x87, g => 0x5f, b => 0x00 },    #  94
            { r => 0x87, g => 0x5f, b => 0x5f },    #  95
            { r => 0x87, g => 0x5f, b => 0x87 },    #  96
            { r => 0x87, g => 0x5f, b => 0xaf },    #  97
            { r => 0x87, g => 0x5f, b => 0xd7 },    #  98
            { r => 0x87, g => 0x5f, b => 0xff },    #  99
            { r => 0x87, g => 0x87, b => 0x00 },    # 100
            { r => 0x87, g => 0x87, b => 0x5f },    # 101
            { r => 0x87, g => 0x87, b => 0x87 },    # 102
            { r => 0x87, g => 0x87, b => 0xaf },    # 103
            { r => 0x87, g => 0x87, b => 0xd7 },    # 104
            { r => 0x87, g => 0x87, b => 0xff },    # 105
            { r => 0x87, g => 0xaf, b => 0x00 },    # 106
            { r => 0x87, g => 0xaf, b => 0x5f },    # 107
            { r => 0x87, g => 0xaf, b => 0x87 },    # 108
            { r => 0x87, g => 0xaf, b => 0xaf },    # 109
            { r => 0x87, g => 0xaf, b => 0xd7 },    # 110
            { r => 0x87, g => 0xaf, b => 0xff },    # 111
            { r => 0x87, g => 0xd7, b => 0x00 },    # 112
            { r => 0x87, g => 0xd7, b => 0x5f },    # 113
            { r => 0x87, g => 0xd7, b => 0x87 },    # 114
            { r => 0x87, g => 0xd7, b => 0xaf },    # 115
            { r => 0x87, g => 0xd7, b => 0xd7 },    # 116
            { r => 0x87, g => 0xd7, b => 0xff },    # 117
            { r => 0x87, g => 0xff, b => 0x00 },    # 118
            { r => 0x87, g => 0xff, b => 0x5f },    # 119
            { r => 0x87, g => 0xff, b => 0x87 },    # 120
            { r => 0x87, g => 0xff, b => 0xaf },    # 121
            { r => 0x87, g => 0xff, b => 0xd7 },    # 122
            { r => 0x87, g => 0xff, b => 0xff },    # 123
            { r => 0xaf, g => 0x00, b => 0x00 },    # 124
            { r => 0xaf, g => 0x00, b => 0x5f },    # 125
            { r => 0xaf, g => 0x00, b => 0x87 },    # 126
            { r => 0xaf, g => 0x00, b => 0xaf },    # 127
            { r => 0xaf, g => 0x00, b => 0xd7 },    # 128
            { r => 0xaf, g => 0x00, b => 0xff },    # 129
            { r => 0xaf, g => 0x5f, b => 0x00 },    # 130
            { r => 0xaf, g => 0x5f, b => 0x5f },    # 131
            { r => 0xaf, g => 0x5f, b => 0x87 },    # 132
            { r => 0xaf, g => 0x5f, b => 0xaf },    # 133
            { r => 0xaf, g => 0x5f, b => 0xd7 },    # 134
            { r => 0xaf, g => 0x5f, b => 0xff },    # 135
            { r => 0xaf, g => 0x87, b => 0x00 },    # 136
            { r => 0xaf, g => 0x87, b => 0x5f },    # 137
            { r => 0xaf, g => 0x87, b => 0x87 },    # 138
            { r => 0xaf, g => 0x87, b => 0xaf },    # 139
            { r => 0xaf, g => 0x87, b => 0xd7 },    # 140
            { r => 0xaf, g => 0x87, b => 0xff },    # 141
            { r => 0xaf, g => 0xaf, b => 0x00 },    # 142
            { r => 0xaf, g => 0xaf, b => 0x5f },    # 143
            { r => 0xaf, g => 0xaf, b => 0x87 },    # 144
            { r => 0xaf, g => 0xaf, b => 0xaf },    # 145
            { r => 0xaf, g => 0xaf, b => 0xd7 },    # 146
            { r => 0xaf, g => 0xaf, b => 0xff },    # 147
            { r => 0xaf, g => 0xd7, b => 0x00 },    # 148
            { r => 0xaf, g => 0xd7, b => 0x5f },    # 149
            { r => 0xaf, g => 0xd7, b => 0x87 },    # 150
            { r => 0xaf, g => 0xd7, b => 0xaf },    # 151
            { r => 0xaf, g => 0xd7, b => 0xd7 },    # 152
            { r => 0xaf, g => 0xd7, b => 0xff },    # 153
            { r => 0xaf, g => 0xff, b => 0x00 },    # 154
            { r => 0xaf, g => 0xff, b => 0x5f },    # 155
            { r => 0xaf, g => 0xff, b => 0x87 },    # 156
            { r => 0xaf, g => 0xff, b => 0xaf },    # 157
            { r => 0xaf, g => 0xff, b => 0xd7 },    # 158
            { r => 0xaf, g => 0xff, b => 0xff },    # 159
            { r => 0xd7, g => 0x00, b => 0x00 },    # 160
            { r => 0xd7, g => 0x00, b => 0x5f },    # 161
            { r => 0xd7, g => 0x00, b => 0x87 },    # 162
            { r => 0xd7, g => 0x00, b => 0xaf },    # 163
            { r => 0xd7, g => 0x00, b => 0xd7 },    # 164
            { r => 0xd7, g => 0x00, b => 0xff },    # 165
            { r => 0xd7, g => 0x5f, b => 0x00 },    # 166
            { r => 0xd7, g => 0x5f, b => 0x5f },    # 167
            { r => 0xd7, g => 0x5f, b => 0x87 },    # 168
            { r => 0xd7, g => 0x5f, b => 0xaf },    # 169
            { r => 0xd7, g => 0x5f, b => 0xd7 },    # 170
            { r => 0xd7, g => 0x5f, b => 0xff },    # 171
            { r => 0xd7, g => 0x87, b => 0x00 },    # 172
            { r => 0xd7, g => 0x87, b => 0x5f },    # 173
            { r => 0xd7, g => 0x87, b => 0x87 },    # 174
            { r => 0xd7, g => 0x87, b => 0xaf },    # 175
            { r => 0xd7, g => 0x87, b => 0xd7 },    # 176
            { r => 0xd7, g => 0x87, b => 0xff },    # 177
            { r => 0xd7, g => 0xaf, b => 0x00 },    # 178
            { r => 0xd7, g => 0xaf, b => 0x5f },    # 179
            { r => 0xd7, g => 0xaf, b => 0x87 },    # 180
            { r => 0xd7, g => 0xaf, b => 0xaf },    # 181
            { r => 0xd7, g => 0xaf, b => 0xd7 },    # 182
            { r => 0xd7, g => 0xaf, b => 0xff },    # 183
            { r => 0xd7, g => 0xd7, b => 0x00 },    # 184
            { r => 0xd7, g => 0xd7, b => 0x5f },    # 185
            { r => 0xd7, g => 0xd7, b => 0x87 },    # 186
            { r => 0xd7, g => 0xd7, b => 0xaf },    # 187
            { r => 0xd7, g => 0xd7, b => 0xd7 },    # 188
            { r => 0xd7, g => 0xd7, b => 0xff },    # 189
            { r => 0xd7, g => 0xff, b => 0x00 },    # 190
            { r => 0xd7, g => 0xff, b => 0x5f },    # 191
            { r => 0xd7, g => 0xff, b => 0x87 },    # 192
            { r => 0xd7, g => 0xff, b => 0xaf },    # 193
            { r => 0xd7, g => 0xff, b => 0xd7 },    # 194
            { r => 0xd7, g => 0xff, b => 0xff },    # 195
            { r => 0xff, g => 0x00, b => 0x00 },    # 196
            { r => 0xff, g => 0x00, b => 0x5f },    # 197
            { r => 0xff, g => 0x00, b => 0x87 },    # 198
            { r => 0xff, g => 0x00, b => 0xaf },    # 199
            { r => 0xff, g => 0x00, b => 0xd7 },    # 200
            { r => 0xff, g => 0x00, b => 0xff },    # 201
            { r => 0xff, g => 0x5f, b => 0x00 },    # 202
            { r => 0xff, g => 0x5f, b => 0x5f },    # 203
            { r => 0xff, g => 0x5f, b => 0x87 },    # 204
            { r => 0xff, g => 0x5f, b => 0xaf },    # 205
            { r => 0xff, g => 0x5f, b => 0xd7 },    # 206
            { r => 0xff, g => 0x5f, b => 0xff },    # 207
            { r => 0xff, g => 0x87, b => 0x00 },    # 208
            { r => 0xff, g => 0x87, b => 0x5f },    # 209
            { r => 0xff, g => 0x87, b => 0x87 },    # 210
            { r => 0xff, g => 0x87, b => 0xaf },    # 211
            { r => 0xff, g => 0x87, b => 0xd7 },    # 212
            { r => 0xff, g => 0x87, b => 0xff },    # 213
            { r => 0xff, g => 0xaf, b => 0x00 },    # 214
            { r => 0xff, g => 0xaf, b => 0x5f },    # 215
            { r => 0xff, g => 0xaf, b => 0x87 },    # 216
            { r => 0xff, g => 0xaf, b => 0xaf },    # 217
            { r => 0xff, g => 0xaf, b => 0xd7 },    # 218
            { r => 0xff, g => 0xaf, b => 0xff },    # 219
            { r => 0xff, g => 0xd7, b => 0x00 },    # 220
            { r => 0xff, g => 0xd7, b => 0x5f },    # 221
            { r => 0xff, g => 0xd7, b => 0x87 },    # 222
            { r => 0xff, g => 0xd7, b => 0xaf },    # 223
            { r => 0xff, g => 0xd7, b => 0xd7 },    # 224
            { r => 0xff, g => 0xd7, b => 0xff },    # 225
            { r => 0xff, g => 0xff, b => 0x00 },    # 226
            { r => 0xff, g => 0xff, b => 0x5f },    # 227
            { r => 0xff, g => 0xff, b => 0x87 },    # 228
            { r => 0xff, g => 0xff, b => 0xaf },    # 229
            { r => 0xff, g => 0xff, b => 0xd7 },    # 230
            { r => 0xff, g => 0xff, b => 0xff },    # 231
            { r => 0x08, g => 0x08, b => 0x08 },    # 232
            { r => 0x12, g => 0x12, b => 0x12 },    # 233
            { r => 0x1c, g => 0x1c, b => 0x1c },    # 234
            { r => 0x26, g => 0x26, b => 0x26 },    # 235
            { r => 0x30, g => 0x30, b => 0x30 },    # 236
            { r => 0x3a, g => 0x3a, b => 0x3a },    # 237
            { r => 0x44, g => 0x44, b => 0x44 },    # 238
            { r => 0x4e, g => 0x4e, b => 0x4e },    # 239
            { r => 0x58, g => 0x58, b => 0x58 },    # 240
            { r => 0x62, g => 0x62, b => 0x62 },    # 241
            { r => 0x6c, g => 0x6c, b => 0x6c },    # 242
            { r => 0x76, g => 0x76, b => 0x76 },    # 243
            { r => 0x80, g => 0x80, b => 0x80 },    # 244
            { r => 0x8a, g => 0x8a, b => 0x8a },    # 245
            { r => 0x94, g => 0x94, b => 0x94 },    # 246
            { r => 0x9e, g => 0x9e, b => 0x9e },    # 247
            { r => 0xa8, g => 0xa8, b => 0xa8 },    # 248
            { r => 0xb2, g => 0xb2, b => 0xb2 },    # 249
            { r => 0xbc, g => 0xbc, b => 0xbc },    # 250
            { r => 0xc6, g => 0xc6, b => 0xc6 },    # 251
            { r => 0xd0, g => 0xd0, b => 0xd0 },    # 252
            { r => 0xda, g => 0xda, b => 0xda },    # 253
            { r => 0xe4, g => 0xe4, b => 0xe4 },    # 254
            { r => 0xee, g => 0xee, b => 0xee }     # 255
        );
    }

    sub ansi_to_rgb ($idx) {
        my $e = $ANSI_HEX[$idx] // { r => 0, g => 0, b => 0 };
        ( $e->{r}, $e->{g}, $e->{b} );
    }

    sub _to6cube ($v) {
        return 0 if $v < 48;
        return 1 if $v < 115;
        return int( ( $v - 35 ) / 40 );
    }
    sub _dist_sq ( $r1, $g1, $b1, $r2, $g2, $b2 ) { ( $r1 - $r2 )**2 + ( $g1 - $g2 )**2 + ( $b1 - $b2 )**2 }

    sub convert_256 ($hex) {
        my ( $r, $g, $b ) = hex_to_rgb($hex);
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

    # Palette
    sub set_palette ( $idx, $r, $g, $b ) {
        return '' if $idx < 0 || $idx > 15;
        return '' if !defined $r || !defined $g || !defined $b;
        my $hi = sprintf '%x', $idx;
        sprintf "\e]P${hi}%02x%02x%02x\a", $r, $g, $b;
    }
    use constant ResetPalette => "\e]R\a";

    # Progress Bar
    use constant ResetProgressBar            => "\e]9;4;0\a";
    use constant SetIndeterminateProgressBar => "\e]9;4;3\a";

    sub set_progress_bar ($pct) {
        $pct = 0   if $pct < 0;
        $pct = 100 if $pct > 100;
        "\e]9;4;1;$pct\a";
    }

    sub set_error_progress_bar ($pct) {
        $pct = 0   if $pct < 0;
        $pct = 100 if $pct > 100;
        "\e]9;4;2;$pct\a";
    }

    sub set_warning_progress_bar ($pct) {
        $pct = 0   if $pct < 0;
        $pct = 100 if $pct > 100;
        "\e]9;4;4;$pct\a";
    }
}
1;
