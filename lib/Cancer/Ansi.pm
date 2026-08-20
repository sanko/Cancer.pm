use v5.42;

package Cancer::Ansi v0.0.1 {
    use Exporter qw[import];
    use MIME::Base64;
    use Cancer::Util qw[_to6cube _dist_sq];
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                ScreenPassthrough TmuxPassthrough
                URxvtExt
                ITerm2
                FinalTerm FinalTermPrompt FinalTermCmdStart FinalTermCmdExecuted FinalTermCmdFinished
                XTGETTCAP RequestTermcap RequestTerminfo
                Focus Blur
                KeypadApplicationMode DECKPAM KeypadNumericMode DECKPNM
                PrimaryDeviceAttributes DA1 SecondaryDeviceAttributes DA2 TertiaryDeviceAttributes DA3
                RequestPrimaryDeviceAttributes RequestSecondaryDeviceAttributes RequestTertiaryDeviceAttributes
                RequestNameVersion XTVERSION
                SetModeKeyboardAction ResetModeKeyboardAction RequestModeKeyboardAction
                SetModeInsertReplace ResetModeInsertReplace RequestModeInsertReplace
                SetModeBiDirectionalSupport ResetModeBiDirectionalSupport RequestModeBiDirectionalSupport
                SetModeSendReceive ResetModeSendReceive RequestModeSendReceive
                SetModeLocalEcho ResetModeLocalEcho RequestModeLocalEcho
                SetModeLineFeedNewLine ResetModeLineFeedNewLine RequestModeLineFeedNewLine
                SetModeCursorKeys ResetModeCursorKeys RequestModeCursorKeys
                SetModeOrigin ResetModeOrigin RequestModeOrigin
                SetModeAutoWrap ResetModeAutoWrap RequestModeAutoWrap
                SetModeMouseX10 ResetModeMouseX10 RequestModeMouseX10
                SetModeTextCursorEnable ResetModeTextCursorEnable RequestModeTextCursorEnable
                SetModeNumericKeypad ResetModeNumericKeypad RequestModeNumericKeypad
                SetModeBackarrowKey ResetModeBackarrowKey RequestModeBackarrowKey
                SetModeLeftRightMargin ResetModeLeftRightMargin RequestModeLeftRightMargin
                SetModeMouseNormal ResetModeMouseNormal RequestModeMouseNormal
                SetModeMouseHighlight ResetModeMouseHighlight RequestModeMouseHighlight
                SetModeMouseButtonEvent ResetModeMouseButtonEvent RequestModeMouseButtonEvent
                SetModeMouseAnyEvent ResetModeMouseAnyEvent RequestModeMouseAnyEvent
                SetModeFocusEvent ResetModeFocusEvent RequestModeFocusEvent
                SetModeMouseExtSgr ResetModeMouseExtSgr RequestModeMouseExtSgr
                SetModeMouseExtUtf8 ResetModeMouseExtUtf8 RequestModeMouseExtUtf8
                SetModeMouseExtUrxvt ResetModeMouseExtUrxvt RequestModeMouseExtUrxvt
                SetModeMouseExtSgrPixel ResetModeMouseExtSgrPixel RequestModeMouseExtSgrPixel
                SetModeAltScreen ResetModeAltScreen RequestModeAltScreen
                SetModeSaveCursor ResetModeSaveCursor RequestModeSaveCursor
                SetModeAltScreenSaveCursor ResetModeAltScreenSaveCursor RequestModeAltScreenSaveCursor
                SetModeBracketedPaste ResetModeBracketedPaste RequestModeBracketedPaste
                SetModeSynchronizedOutput ResetModeSynchronizedOutput RequestModeSynchronizedOutput
                SetModeUnicodeCore ResetModeUnicodeCore RequestModeUnicodeCore
                SetModeLightDark ResetModeLightDark RequestModeLightDark
                SetModeInBandResize ResetModeInBandResize RequestModeInBandResize
                SetModeWin32Input ResetModeWin32Input RequestModeWin32Input
                SM RM DECSET DECRST DECRQM DECRPM
                InBandResize
                DisableModifyOtherKeys EnableModifyOtherKeys1 EnableModifyOtherKeys2 RequestModifyOtherKeys
                DECST8C
                MouseX10
                SixelGraphics Convert16
                Strip StringWidth Hardwrap Wordwrap Wrap Truncate TruncateLeft Cut
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
                SGR NewStyle Style
                ResetStyle
                AttrReset AttrBold AttrFaint AttrItalic AttrUnderline
                AttrNoBlink AttrBlink AttrRapidBlink
                AttrReverse AttrConceal AttrStrikethrough
                AttrNormalIntensity AttrNoItalic AttrNoUnderline
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
                AttrRGBColorIntroducer AttrExtendedColorIntroducer
                UnderlineNone UnderlineSingle UnderlineDouble
                UnderlineCurly UnderlineDotted UnderlineDashed
                color_to_hex_string
                hex_to_rgb ansi_to_rgb
                convert_256
                set_palette ResetPalette
                ResetProgressBar set_progress_bar
                set_error_progress_bar SetIndeterminateProgressBar
                set_warning_progress_bar
                CursorUp CUU CursorDown CUD CursorForward CUF CursorBackward CUB
                CursorNextLine CNL CursorPreviousLine CPL
                CursorHorizontalAbsolute CHA CursorPosition CUP
                CursorHorizontalForwardTab CHT EraseCharacter ECH
                CursorBackwardTab CBT VerticalPositionAbsolute VPA
                VerticalPositionRelative VPR HorizontalVerticalPosition HVP
                SetCursorStyle DECSCUSR SetPointerShape
                HorizontalPositionAbsolute HPA HorizontalPositionRelative HPR
                CUU1 CUD1 CUF1 CUB1 CursorHomePosition HorizontalVerticalHomePosition
                SaveCursor DECSC RestoreCursor DECRC
                SaveCurrentCursorPosition SCOSC RestoreCurrentCursorPosition SCORC
                ReverseIndex Index
                RequestCursorPosition RequestExtendedCursorPosition
                EraseDisplay ED EraseLine EL
                ScrollUp SU ScrollDown SD
                InsertLine IL DeleteLine DL
                SetTopBottomMargins DECSTBM SetLeftRightMargins DECSLRM
                InsertCharacter ICH DeleteCharacter DCH
                TabClear TBC HorizontalTabSet SetTabEvery8Columns
                RequestPresentationStateReport DECRQPSR
                TabStopReport DECTABSR CursorInformationReport DECCIR
                RepeatPreviousCharacter REP
                EraseScreenBelow EraseScreenAbove EraseEntireScreen EraseEntireDisplay
                EraseLineRight EraseLineLeft EraseEntireLine
                KeyModifierOptions XTMODKEYS
                SetKeyModifierOptions ResetKeyModifierOptions
                QueryKeyModifierOptions XTQMODKEYS
                ModifyOtherKeys
                ResizeWindowWinOp RequestWindowSizeWinOp RequestCellSizeWinOp
                SetModifyOtherKeys1 SetModifyOtherKeys2
                ResetModifyOtherKeys QueryModifyOtherKeys
                WindowOp XTWINOPS
                DeviceStatusReport DSR
                CursorPositionReport CPR ExtendedCursorPositionReport DECXCPR
                LightDarkReport
                RequestCursorPositionReport RequestExtendedCursorPositionReport
                RequestLightDarkReport
                SelectCharacterSet SCS
                LS1R LS2 LS2R LS3 LS3R
                ]
        ]
    );

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
    use constant { SYSTEM_CLIPBOARD => 'c', PRIMARY_CLIPBOARD => 'p' };

    sub set_clipboard ( $c, $d ) {
        $d = MIME::Base64::encode_base64( $d, '' ) if length $d;
        "\e]52;$c;$d\a";
    }
    sub set_system_clipboard  ($d) { set_clipboard( SYSTEM_CLIPBOARD,  $d ) }
    sub set_primary_clipboard ($d) { set_clipboard( PRIMARY_CLIPBOARD, $d ) }
    sub reset_clipboard       ($c) { set_clipboard( $c,                '' ) }
    use constant { RESET_SYSTEM_CLIPBOARD => "\e]52;c;\a", RESET_PRIMARY_CLIPBOARD => "\e]52;p;\a" };
    sub request_clipboard ($c) {"\e]52;$c;?\a"}
    use constant { REQUEST_SYSTEM_CLIPBOARD => "\e]52;c;?\a", REQUEST_PRIMARY_CLIPBOARD => "\e]52;p;?\a" };

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

    sub SixelGraphics ( $p1, $p2, $p3, $payload ) {
        my $s = "\eP";
        $s .= "$p1"  if $p1 >= 0;
        $s .= ";$p2" if $p2 >= 0;
        $s .= ";$p3" if $p3 > 0;
        $s .= "q$payload\e\\";
        return $s;
    }

    # In-band resize
    sub InBandResize ( $height_cells, $width_cells, $height_pixels, $width_pixels ) {
        $height_cells  = 0 if $height_cells < 0;
        $width_cells   = 0 if $width_cells < 0;
        $height_pixels = 0 if $height_pixels < 0;
        $width_pixels  = 0 if $width_pixels < 0;
        "\e[48;${height_cells};${width_cells};${height_pixels};${width_pixels}t";
    }

    # Convert16 - find the nearest 16-color ANSI index for an RGB triplet
    sub Convert16 ( $r, $g, $b ) {
        my @ansi16 = (
            [ 0,   0,   0 ],
            [ 128, 0,   0 ],
            [ 0,   128, 0 ],
            [ 128, 128, 0 ],
            [ 0,   0,   128 ],
            [ 128, 0,   128 ],
            [ 0,   128, 128 ],
            [ 192, 192, 192 ],
            [ 128, 128, 128 ],
            [ 255, 0,   0 ],
            [ 0,   255, 0 ],
            [ 255, 255, 0 ],
            [ 0,   0,   255 ],
            [ 255, 0,   255 ],
            [ 0,   255, 255 ],
            [ 255, 255, 255 ]
        );
        my $best      = 0;
        my $best_dist = ~0;
        for my $i ( 0 .. $#ansi16 ) {
            my ( $ar, $ag, $ab ) = @{ $ansi16[$i] };
            my $dist = ( $r - $ar )**2 + ( $g - $ag )**2 + ( $b - $ab )**2;
            if ( $dist < $best_dist ) {
                $best_dist = $dist;
                $best      = $i;
            }
        }
        return $best;
    }

    # String width helpers
    # _char_width($codepoint) returns the width of a single Unicode codepoint
    sub _char_width ($cp) {
        if ( $cp < 0x20 )                                { return 0 }
        if ( $cp == 0x7F )                               { return 0 }
        if ( $cp >= 0x80 && $cp <= 0x9F )                { return 0 }
        if ( $cp == 0x0A || $cp == 0x0D || $cp == 0x09 ) { return 0 }
        if ( $cp >= 0x1100 && $cp <= 0x115F )            { return 2 }
        if ( $cp == 0x2329 || $cp == 0x232A )            { return 2 }
        if ( $cp >= 0x2E80 && $cp <= 0x303E )            { return 2 }
        if ( $cp >= 0x3040 && $cp <= 0x33BF )            { return 2 }
        if ( $cp >= 0x3400 && $cp <= 0x4DBF )            { return 2 }
        if ( $cp >= 0x4E00 && $cp <= 0x9FFF )            { return 2 }
        if ( $cp >= 0xA000 && $cp <= 0xA4CF )            { return 2 }
        if ( $cp >= 0xAC00 && $cp <= 0xD7AF )            { return 2 }
        if ( $cp >= 0xF900 && $cp <= 0xFAFF )            { return 2 }
        if ( $cp >= 0xFE10 && $cp <= 0xFE6F )            { return 2 }
        if ( $cp >= 0xFF01 && $cp <= 0xFF60 )            { return 2 }
        if ( $cp >= 0xFFE0 && $cp <= 0xFFE6 )            { return 2 }
        if ( $cp >= 0x20000 && $cp <= 0x2FFFD )          { return 2 }
        if ( $cp >= 0x30000 && $cp <= 0x3FFFD )          { return 2 }
        return 1;
    }

    # _decode_utf8($str, $pos) decodes one UTF-8 character starting at $pos
    # Returns ($codepoint, $bytes_consumed)
    sub _decode_utf8 ( $str, $pos ) {
        my $b = ord( substr( $str, $pos, 1 ) );
        if ( $b < 0x80 ) { return ( $b, 1 ) }
        my $bytes = ( $b & 0xE0 ) == 0xC0 ? 2 : ( $b & 0xF0 ) == 0xE0 ? 3 : ( $b & 0xF8 ) == 0xF0 ? 4 : 1;
        $bytes = 1 if $bytes > length($str) - $pos;
        my $cp = $b & ( 0x7F >> ( $bytes - 1 ) );
        for my $i ( 1 .. $bytes - 1 ) {
            $cp = ( $cp << 6 ) | ( ord( substr( $str, $pos + $i, 1 ) ) & 0x3F );
        }
        return ( $cp, $bytes );
    }

    # Strip removes ANSI escape codes from a string
    sub Strip ($s) {
        $s =~ s/\e\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]//g;    # CSI sequences
        $s =~ s/\e\][^\a\x1b]*(?:\a|\x1b\\)//g;                # OSC sequences
        $s =~ s/\e\[[^\x40-\x7e\x1b]*//g;                      # Incomplete CSI
        $s =~ s/\x1b[=>78DEHMNOPZ\[\]\\^_`|~]//g;              # ESC + single char
        $s =~ s/\x1b[()][AB012]//g;                            # ESC ( B etc
        $s =~ s/\x1b[+*%#][^\x40-\x7e\x1b]*//g;                # ESC intermediate
        return $s;
    }

    # _utf8_byte_len($first_byte) returns the number of bytes for a UTF-8 sequence
    sub _utf8_byte_len ($b) {
        return 1 if $b < 0x80;
        return 2 if ( $b & 0xE0 ) == 0xC0;
        return 3 if ( $b & 0xF0 ) == 0xE0;
        return 4 if ( $b & 0xF8 ) == 0xF0;
        return 1;
    }

    # _skip_ansi($str, $pos) returns the new position after skipping an ANSI sequence
    # starting at $pos. Returns the position after the sequence.
    sub _skip_ansi ( $s, $i ) {
        my $len = length($s);
        my $esi = $i + 1;
        my $est = 8;            # EscapeState - we just consumed the ESC byte
        while ( $esi < $len ) {
            my $ec = ord( substr( $s, $esi, 1 ) );
            my $ea = _transition_action( $est, $ec );
            my $en = _transition_state( $est, $ec );
            $esi++;
            last if $ea == 4;
            $est = $en;
        }
        return $esi;
    }

    # _skip_c1_csi($str, $pos) returns position after skipping C1 CSI (0x9B)
    sub _skip_c1_csi ( $s, $i ) {
        my $len = length($s);
        my $csi = $i + 1;
        while ( $csi < $len ) {
            my $cc = ord( substr( $s, $csi, 1 ) );
            $csi++;
            last if $cc >= 0x40 && $cc <= 0x7E;
        }
        return $csi;
    }

    # _grapheme_cluster_width($str, $pos) returns (width, bytes_consumed) for the
    # first grapheme cluster starting at $pos
    sub _grapheme_cluster_width ( $str, $pos ) {
        my $len           = length($str);
        my $total_w       = 0;
        my $cluster_bytes = 0;
        my $first         = 1;
        while ( $pos + $cluster_bytes < $len ) {
            my $b = ord( substr( $str, $pos + $cluster_bytes, 1 ) );

            # Check for ANSI escape sequences - they have zero width
            if ( $b == 0x1B ) {
                $cluster_bytes = _skip_ansi( $str, $pos + $cluster_bytes );
                next;
            }

            # Check for C1 control codes (0x80-0x9F) that start sequences
            if ( $b >= 0x80 && $b <= 0x9F ) {
                if ( $b == 0x9B ) {    # CSI (C1)
                    $cluster_bytes = _skip_c1_csi( $str, $pos + $cluster_bytes ) - $pos;
                    next;
                }
                $cluster_bytes++;
                next;
            }

            # Regular character
            my ( $cp, $bytes ) = _decode_utf8( $str, $pos + $cluster_bytes );
            $cluster_bytes += $bytes;
            if ($first) {
                $total_w = _char_width($cp);
                $first   = 0;

                # Check for combining marks (zero-width)
                if ( $cp >= 0x0300 && $cp <= 0x036F ) {next}
                if ( $cp >= 0x1DC0 && $cp <= 0x1DFF ) {next}
                if ( $cp >= 0x20D0 && $cp <= 0x20FF ) {next}
                if ( $cp >= 0xFE20 && $cp <= 0xFE2F ) {next}

                # CJK width override: treat wide chars as 2
                $total_w = 2 if _char_width($cp) == 2;
            }
            else {
                # Combining marks and zero-width joiners don't add width
                last if _char_width($cp) > 0;
            }
        }
        return ( $total_w || 1, $cluster_bytes || 1 );
    }

    # _transition_state and _transition_action using simple heuristics
    # These are simplified versions - for a full implementation use Cancer::Ansi::Parser
    sub _transition_action ( $state, $byte ) {

        # Simplified: PrintAction=9, ExecuteAction=5, CollectAction=2, DispatchAction=4
        return 9 if $state == 0 && $byte >= 0x20 && $byte <= 0x7E;                         # Ground + printable
        return 5 if $state == 0 && ( $byte == 0x0A || $byte == 0x0D || $byte == 0x09 );    # Ground + \n\r\t

        # In EscapeState, '[' enters CSI, 'P' enters DCS, ']' enters OSC - not dispatch
        return 0
            if $state == 8 &&
            ( $byte == ord('[') || $byte == ord('P') || $byte == ord(']') || $byte == ord('X') || $byte == ord('^') || $byte == ord('_') );
        return 4 if $state == 8 && $byte >= 0x30 && $byte <= 0x7E;                         # Escape + dispatch byte
        return 4 if $state == 1 && $byte >= 0x40 && $byte <= 0x7E;                         # CSI + final byte
        return 4 if $state == 3 && $byte >= 0x40 && $byte <= 0x7E;                         # CSI param + final byte
        return 4 if $state == 2 && $byte >= 0x40 && $byte <= 0x7E;                         # CSI intermediate + final byte
        return 4 if $state == 5 && $byte >= 0x40 && $byte <= 0x7E;                         # DCS + final byte
        return 4 if $state == 6 && $byte >= 0x40 && $byte <= 0x7E;                         # DCS param + final byte
        return 2 if ( $state == 0 || $state == 8 ) && ( $byte & 0xE0 ) == 0xC0;            # Start UTF-8
        return 2 if ( $state == 0 || $state == 8 ) && ( $byte & 0xF0 ) == 0xE0;
        return 2 if ( $state == 0 || $state == 8 ) && ( $byte & 0xF8 ) == 0xF0;
        return 2 if $state == 3 && $byte >= 0x20 && $byte <= 0x2F;                         # CSI intermediate
        return 0 if $state == 0 && $byte == 0x1B;                                          # ESC
        return 0                                                                           # default
    }

    sub _transition_state ( $state, $byte ) {
        return 14 if $state == 0 && ( $byte & 0xE0 ) == 0xC0;                              # -> Utf8
        return 14 if $state == 0 && ( $byte & 0xF0 ) == 0xE0;
        return 14 if $state == 0 && ( $byte & 0xF8 ) == 0xF0;
        return 14 if $state == 8 && ( $byte & 0xE0 ) == 0xC0;
        return 14 if $state == 8 && ( $byte & 0xF0 ) == 0xE0;
        return 14 if $state == 8 && ( $byte & 0xF8 ) == 0xF0;
        return 0  if $byte == 0x1B;                                                        # -> Escape
        return 1  if $state == 0 && $byte == 0x9B;                                         # -> CsiEntry (C1)
        return 1  if $state == 8 && $byte == ord('[');                                     # -> CsiEntry
        return 0  if $state == 1 && $byte >= 0x40 && $byte <= 0x7E;                        # CSI dispatch -> Ground
        return 0  if $state == 3 && $byte >= 0x40 && $byte <= 0x7E;                        # CSI param dispatch -> Ground
        return 0  if $state == 2 && $byte >= 0x40 && $byte <= 0x7E;                        # CSI intermediate dispatch -> Ground
        return 0  if $state == 5 && $byte >= 0x40 && $byte <= 0x7E;                        # DCS dispatch -> Ground
        return 0  if $state == 6 && $byte >= 0x40 && $byte <= 0x7E;                        # DCS param dispatch -> Ground
        return 0  if $state == 8 && $byte >= 0x30 && $byte <= 0x4F;                        # ESC dispatch
        return 0  if $state == 8 && $byte >= 0x60 && $byte <= 0x7E;
        return 3  if $state == 1 && $byte >= 0x30 && $byte <= 0x3F;                        # CSI -> param
        return 3  if $state == 1 && $byte >= 0x20 && $byte <= 0x2F;                        # CSI -> intermediate
        return 3  if $state == 3 && $byte >= 0x30 && $byte <= 0x3B;                        # CSI param continues
        return 2  if $state == 3 && $byte >= 0x20 && $byte <= 0x2F;                        # CSI param -> intermediate
        return $state                                                                      # stay
    }

    # StringWidth returns the display width of a string, ignoring ANSI codes
    sub StringWidth ($s) {
        return 0 if !defined($s) || !length($s);
        my $len   = length($s);
        my $width = 0;
        my $i     = 0;
        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );

            # Skip ANSI escape sequences
            if ( $b == 0x1B ) {
                $i = _skip_ansi( $s, $i );
                next;
            }

            # Skip C1 control sequences
            if ( $b == 0x9B ) {    # CSI
                $i = _skip_c1_csi( $s, $i );
                next;
            }

            # C1 controls (0x80-0x9F) are zero width
            if ( $b >= 0x80 && $b <= 0x9F ) {
                $i++;
                next;
            }

            # ASCII printable
            if ( $b < 0x80 ) {
                $width++ if $b >= 0x20;
                $i++;
                next;
            }

            # UTF-8 character
            my ( $cp, $bytes ) = _decode_utf8( $s, $i );
            $width += _char_width($cp);
            $i     += $bytes;
        }
        return $width;
    }

    # Hardwrap wraps text to a given width, breaking at any position
    sub Hardwrap ( $s, $limit, $preserve_space = 0 ) {
        return $s if $limit < 1;
        my $out           = '';
        my $width         = 0;
        my $len           = length($s);
        my $i             = 0;
        my $force_newline = 0;
        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );

            # Handle newlines
            if ( $b == 0x0A ) {
                $out .= "\n";
                $width         = 0;
                $force_newline = 0;
                $i++;
                next;
            }

            # Skip ANSI sequences
            if ( $b == 0x1B ) {
                my $end = _skip_ansi( $s, $i );
                $out .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }

            # Skip C1 controls
            if ( $b == 0x9B ) {
                my $end = _skip_c1_csi( $s, $i );
                $out .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }
            if ( $b >= 0x80 && $b <= 0x9F ) {
                $out .= chr($b);
                $i++;
                next;
            }

            # Regular character
            my ( $cw, $bytes );
            if ( $b < 0x80 ) {
                $cw    = 1;
                $bytes = 1;
            }
            else {
                ( $cw, $bytes ) = _grapheme_cluster_width( $s, $i );
            }
            if ( $width + $cw > $limit ) {
                $out .= "\n";
                $width         = 0;
                $force_newline = 1;
            }
            if ( !$preserve_space && $width == 0 && $force_newline && $b == 0x20 ) {
                $i += $bytes;
                next;
            }
            $force_newline = 0 if $width > 0;
            $out .= substr( $s, $i, $bytes );
            $width += $cw if $b >= 0x20;
            $i     += $bytes;
        }
        return $out;
    }

    # Wordwrap wraps text to a given width, breaking at word boundaries
    sub Wordwrap ( $s, $limit, $breakpoints = '' ) {
        return $s if $limit < 1;
        my $out       = '';
        my $word      = '';
        my $space     = '';
        my $cur_width = 0;
        my $word_len  = 0;
        my $len       = length($s);
        my $i         = 0;
        my %bp        = map { $_ => 1 } split( //, $breakpoints );
        my $add_space = sub {
            $cur_width += _strip_ansi_width($space);
            $out .= $space;
            $space = '';
        };
        my $add_word = sub {
            return if !length($word);
            $add_space->();
            $cur_width += $word_len;
            $out .= $word;
            $word     = '';
            $word_len = 0;
        };
        my $add_newline = sub {
            $out .= "\n";
            $cur_width = 0;
            $space     = '';
        };
        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );
            if ( $b == 0x0A ) {
                $add_word->();
                $add_newline->();
                $i++;
                next;
            }

            # Skip ANSI
            if ( $b == 0x1B ) {
                my $end = _skip_ansi( $s, $i );
                $word .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }
            if ( $b == 0x9B ) {
                my $end = _skip_c1_csi( $s, $i );
                $word .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }
            my $bytes = 1;
            my $cw    = 1;
            if ( $b >= 0x80 ) {
                ( $cw, $bytes ) = _grapheme_cluster_width( $s, $i );
            }

            # Space
            if ( $b == 0x20 || $b == 0x09 ) {
                $add_word->();
                $space .= substr( $s, $i, $bytes );
                $i += $bytes;
                next;
            }

            # Breakpoint
            if ( $bp{$b} ) {
                $add_space->();
                $add_word->();
                $out .= substr( $s, $i, $bytes );
                $cur_width += $cw;
                $i         += $bytes;
                next;
            }

            # Regular char
            $word .= substr( $s, $i, $bytes );
            $word_len += $cw;
            if ( $cur_width + _strip_ansi_width($space) + $word_len > $limit && $word_len < $limit ) {
                $add_newline->();
            }
            $i += $bytes;
        }
        $add_word->();
        return $out;
    }

    sub _strip_ansi_width ($s) {
        return 0 if !defined($s) || !length($s);
        my $w   = 0;
        my $len = length($s);
        my $i   = 0;
        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );
            if ( $b == 0x1B ) {
                my $esi = $i + 1;
                my $est = 0;
                while ( $esi < $len ) {
                    my $ec = ord( substr( $s, $esi, 1 ) );
                    my $ea = _transition_action( $est, $ec );
                    my $en = _transition_state( $est, $ec );
                    $esi++;
                    if ( $ea == 4 ) { $i = $esi; last }
                    $est = $en;
                }
                next if $esi >= $len;
                next;
            }
            $i++;
        }
        return $w;
    }

    # Wrap wraps text to a given width, breaking words only if necessary
    sub Wrap ( $s, $limit, $breakpoints = '' ) {
        return $s if $limit < 1;
        my $out       = '';
        my $word      = '';
        my $space     = '';
        my $word_len  = 0;
        my $cur_width = 0;
        my $space_w   = 0;
        my $len       = length($s);
        my $i         = 0;
        my %bp        = map { $_ => 1 } split( //, $breakpoints );
        my $add_space = sub {
            $cur_width += $space_w;
            $out .= $space;
            $space   = '';
            $space_w = 0;
        };
        my $add_word = sub {
            return if !length($word);
            $add_space->();
            $cur_width += $word_len;
            $out .= $word;
            $word     = '';
            $word_len = 0;
        };
        my $add_newline = sub {
            $out .= "\n";
            $cur_width = 0;
            $space     = '';
            $space_w   = 0;
        };
        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );
            if ( $b == 0x0A ) {
                $add_word->();
                $add_newline->();
                $i++;
                next;
            }

            # Skip ANSI
            if ( $b == 0x1B ) {
                my $end = _skip_ansi( $s, $i );
                $word .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }
            if ( $b == 0x9B ) {
                my $end = _skip_c1_csi( $s, $i );
                $word .= substr( $s, $i, $end - $i );
                $i = $end;
                next;
            }
            my $bytes = 1;
            my $cw    = 1;
            if ( $b >= 0x80 ) {
                ( $cw, $bytes ) = _grapheme_cluster_width( $s, $i );
            }
            if ( $b == 0x20 || $b == 0x09 ) {
                $add_word->();
                $space .= substr( $s, $i, $bytes );
                $space_w += $cw;
                $i       += $bytes;
                next;
            }
            if ( $bp{$b} || $b == ord('-') ) {
                $add_space->();
                if ( $cur_width + $word_len >= $limit ) {
                    $word .= substr( $s, $i, $bytes );
                    $word_len += $cw;
                }
                else {
                    $add_word->();
                    $out .= substr( $s, $i, $bytes );
                    $cur_width += $cw;
                }
                $i += $bytes;
                next;
            }
            if ( $word_len + $cw > $limit ) {
                $add_word->();
            }
            $word .= substr( $s, $i, $bytes );
            $word_len += $cw;
            if ( $cur_width + $word_len + $space_w > $limit ) {
                $add_newline->();
            }
            if ( $word_len == $limit ) {
                $add_word->();
            }
            $i += $bytes;
        }
        $add_word->();
        return $out;
    }

    # Truncate truncates a string to a given width, adding a tail
    sub Truncate ( $s, $length, $tail = '' ) {
        my $sw = StringWidth($s);
        return $s if $sw <= $length;
        my $tw = StringWidth($tail);
        $length -= $tw;
        return $tail if $length < 0;
        my $out      = '';
        my $width    = 0;
        my $len      = length($s);
        my $i        = 0;
        my $ignoring = 0;

        while ( $i < $len ) {
            my $b = ord( substr( $s, $i, 1 ) );

            # ANSI sequence - always copy when not ignoring
            if ( $b == 0x1B ) {
                my $end = _skip_ansi( $s, $i );
                $out .= substr( $s, $i, $end - $i ) if !$ignoring;
                $i = $end;
                next;
            }
            if ( $b == 0x9B ) {
                my $end = _skip_c1_csi( $s, $i );
                $out .= substr( $s, $i, $end - $i ) if !$ignoring;
                $i = $end;
                next;
            }
            my $bytes = 1;
            my $cw    = 0;
            if ( $b < 0x80 ) {
                $cw = 1 if $b >= 0x20;
            }
            else {
                ( $cw, $bytes ) = _grapheme_cluster_width( $s, $i );
            }
            $width += $cw;
            if ( $width > $length && !$ignoring ) {
                $ignoring = 1;
                $out .= $tail;
            }
            if ( !$ignoring ) {
                $out .= substr( $s, $i, $bytes );
            }
            $i += $bytes;
        }
        return $out;
    }

    # TruncateLeft truncates from the left, adding a prefix
    sub TruncateLeft ( $s, $n, $prefix = '' ) {
        return $s if $n <= 0;
        my $out      = '';
        my $width    = 0;
        my $len      = length($s);
        my $i        = 0;
        my $ignoring = 1;
        while ( $i < $len ) {
            if ( !$ignoring ) {
                $out .= substr( $s, $i );
                last;
            }
            my $b = ord( substr( $s, $i, 1 ) );

            # ANSI sequence - skip when ignoring
            if ( $b == 0x1B ) {
                my $end = _skip_ansi( $s, $i );
                $i = $end;
                next;
            }
            if ( $b == 0x9B ) {
                my $end = _skip_c1_csi( $s, $i );
                $i = $end;
                next;
            }
            my $bytes = 1;
            my $cw    = 0;
            if ( $b < 0x80 ) {
                $cw = 1 if $b >= 0x20;
            }
            else {
                ( $cw, $bytes ) = _grapheme_cluster_width( $s, $i );
            }
            $width += $cw;
            if ( $width > $n && $ignoring ) {
                $ignoring = 0;
                $out .= $prefix;
            }
            if ( !$ignoring ) {
                $out .= substr( $s, $i, $bytes );
            }
            $i += $bytes;
        }
        return $out;
    }

    # Cut extracts a substring by width range [left, right)
    sub Cut ( $s, $left, $right ) {
        return ''                         if $right <= $left;
        return Truncate( $s, $right, '' ) if $left == 0;
        return TruncateLeft( Truncate( $s, $right, '' ), $left, '' );
    }

    # Mode
    use constant { ModeNotRecognized => 0, ModeSet => 1, ModeReset => 2, ModePermanentlySet => 3, ModePermanentlyReset => 4 };
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

    # Aliases for set_mode/reset_mode/request_mode/report_mode
    sub SM     (@modes)     { set_mode(@modes) }
    sub RM     (@modes)     { reset_mode(@modes) }
    sub DECSET (@modes)     { set_mode(@modes) }
    sub DECRST (@modes)     { reset_mode(@modes) }
    sub DECRQM ($m)         { request_mode($m) }
    sub DECRPM ( $m, $val ) { report_mode( $m, $val ) }
    use constant {

        # ANSI Mode Constants ( [number, 0] )
        ModeKeyboardAction       => [ 2,  0 ],
        KAM                      => [ 2,  0 ],
        ModeInsertReplace        => [ 4,  0 ],
        IRM                      => [ 4,  0 ],
        ModeBiDirectionalSupport => [ 8,  0 ],
        BDSM                     => [ 8,  0 ],
        ModeSendReceive          => [ 12, 0 ],
        ModeLocalEcho            => [ 12, 0 ],
        SRM                      => [ 12, 0 ],
        ModeLineFeedNewLine      => [ 20, 0 ],
        LNM                      => [ 20, 0 ],

        # DEC Mode Constants ( [number, 1] )
        ModeCursorKeys          => [ 1,  1 ],
        DECCKM                  => [ 1,  1 ],
        ModeOrigin              => [ 6,  1 ],
        DECOM                   => [ 6,  1 ],
        ModeAutoWrap            => [ 7,  1 ],
        DECAWM                  => [ 7,  1 ],
        ModeMouseX10            => [ 9,  1 ],
        ModeTextCursorEnable    => [ 25, 1 ],
        DECTCEM                 => [ 25, 1 ],
        ShowCursor              => "\e[?25h",
        HideCursor              => "\e[?25l",
        ModeNumericKeypad       => [ 66,   1 ],
        DECNKM                  => [ 66,   1 ],
        ModeBackarrowKey        => [ 67,   1 ],
        DECBKM                  => [ 67,   1 ],
        ModeLeftRightMargin     => [ 69,   1 ],
        DECLRMM                 => [ 69,   1 ],
        ModeMouseNormal         => [ 1000, 1 ],
        ModeMouseHighlight      => [ 1001, 1 ],
        ModeMouseButtonEvent    => [ 1002, 1 ],
        ModeMouseAnyEvent       => [ 1003, 1 ],
        ModeFocusEvent          => [ 1004, 1 ],
        ModeMouseExtUtf8        => [ 1005, 1 ],
        ModeMouseExtSgr         => [ 1006, 1 ],
        ModeMouseExtUrxvt       => [ 1015, 1 ],
        ModeMouseExtSgrPixel    => [ 1016, 1 ],
        ModeAltScreen           => [ 1047, 1 ],
        ModeSaveCursor          => [ 1048, 1 ],
        ModeAltScreenSaveCursor => [ 1049, 1 ],
        ModeBracketedPaste      => [ 2004, 1 ],
        ModeSynchronizedOutput  => [ 2026, 1 ],
        ModeUnicodeCore         => [ 2027, 1 ],
        ModeLightDark           => [ 2031, 1 ],
        ModeInBandResize        => [ 2048, 1 ],
        ModeWin32Input          => [ 9001, 1 ],

        # Pre-built mode strings (Set/Reset/Request for each mode)
        SetModeKeyboardAction           => "\e[2h",
        ResetModeKeyboardAction         => "\e[2l",
        RequestModeKeyboardAction       => "\e[2\$p",
        SetModeInsertReplace            => "\e[4h",
        ResetModeInsertReplace          => "\e[4l",
        RequestModeInsertReplace        => "\e[4\$p",
        SetModeBiDirectionalSupport     => "\e[8h",
        ResetModeBiDirectionalSupport   => "\e[8l",
        RequestModeBiDirectionalSupport => "\e[8\$p",
        SetModeSendReceive              => "\e[12h",
        ResetModeSendReceive            => "\e[12l",
        RequestModeSendReceive          => "\e[12\$p",
        SetModeLocalEcho                => "\e[12h",
        ResetModeLocalEcho              => "\e[12l",
        RequestModeLocalEcho            => "\e[12\$p",
        SetModeLineFeedNewLine          => "\e[20h",
        ResetModeLineFeedNewLine        => "\e[20l",
        RequestModeLineFeedNewLine      => "\e[20\$p",
        SetModeCursorKeys               => "\e[?1h",
        ResetModeCursorKeys             => "\e[?1l",
        RequestModeCursorKeys           => "\e[?1\$p",
        SetModeOrigin                   => "\e[?6h",
        ResetModeOrigin                 => "\e[?6l",
        RequestModeOrigin               => "\e[?6\$p",
        SetModeAutoWrap                 => "\e[?7h",
        ResetModeAutoWrap               => "\e[?7l",
        RequestModeAutoWrap             => "\e[?7\$p",
        SetModeMouseX10                 => "\e[?9h",
        ResetModeMouseX10               => "\e[?9l",
        RequestModeMouseX10             => "\e[?9\$p",
        SetModeTextCursorEnable         => "\e[?25h",
        ResetModeTextCursorEnable       => "\e[?25l",
        RequestModeTextCursorEnable     => "\e[?25\$p",
        SetModeNumericKeypad            => "\e[?66h",
        ResetModeNumericKeypad          => "\e[?66l",
        RequestModeNumericKeypad        => "\e[?66\$p",
        SetModeBackarrowKey             => "\e[?67h",
        ResetModeBackarrowKey           => "\e[?67l",
        RequestModeBackarrowKey         => "\e[?67\$p",
        SetModeLeftRightMargin          => "\e[?69h",
        ResetModeLeftRightMargin        => "\e[?69l",
        RequestModeLeftRightMargin      => "\e[?69\$p",
        SetModeMouseNormal              => "\e[?1000h",
        ResetModeMouseNormal            => "\e[?1000l",
        RequestModeMouseNormal          => "\e[?1000\$p",
        SetModeMouseHighlight           => "\e[?1001h",
        ResetModeMouseHighlight         => "\e[?1001l",
        RequestModeMouseHighlight       => "\e[?1001\$p",
        SetModeMouseButtonEvent         => "\e[?1002h",
        ResetModeMouseButtonEvent       => "\e[?1002l",
        RequestModeMouseButtonEvent     => "\e[?1002\$p",
        SetModeMouseAnyEvent            => "\e[?1003h",
        ResetModeMouseAnyEvent          => "\e[?1003l",
        RequestModeMouseAnyEvent        => "\e[?1003\$p",
        SetModeFocusEvent               => "\e[?1004h",
        ResetModeFocusEvent             => "\e[?1004l",
        RequestModeFocusEvent           => "\e[?1004\$p",
        SetModeMouseExtUtf8             => "\e[?1005h",
        ResetModeMouseExtUtf8           => "\e[?1005l",
        RequestModeMouseExtUtf8         => "\e[?1005\$p",
        SetModeMouseExtSgr              => "\e[?1006h",
        ResetModeMouseExtSgr            => "\e[?1006l",
        RequestModeMouseExtSgr          => "\e[?1006\$p",
        SetModeMouseExtUrxvt            => "\e[?1015h",
        ResetModeMouseExtUrxvt          => "\e[?1015l",
        RequestModeMouseExtUrxvt        => "\e[?1015\$p",
        SetModeMouseExtSgrPixel         => "\e[?1016h",
        ResetModeMouseExtSgrPixel       => "\e[?1016l",
        RequestModeMouseExtSgrPixel     => "\e[?1016\$p",
        SetModeAltScreen                => "\e[?1047h",
        ResetModeAltScreen              => "\e[?1047l",
        RequestModeAltScreen            => "\e[?1047\$p",
        SetModeSaveCursor               => "\e[?1048h",
        ResetModeSaveCursor             => "\e[?1048l",
        RequestModeSaveCursor           => "\e[?1048\$p",
        SetModeAltScreenSaveCursor      => "\e[?1049h",
        ResetModeAltScreenSaveCursor    => "\e[?1049l",
        RequestModeAltScreenSaveCursor  => "\e[?1049\$p",
        SetModeBracketedPaste           => "\e[?2004h",
        ResetModeBracketedPaste         => "\e[?2004l",
        RequestModeBracketedPaste       => "\e[?2004\$p",
        SetModeSynchronizedOutput       => "\e[?2026h",
        ResetModeSynchronizedOutput     => "\e[?2026l",
        RequestModeSynchronizedOutput   => "\e[?2026\$p",
        SetModeUnicodeCore              => "\e[?2027h",
        ResetModeUnicodeCore            => "\e[?2027l",
        RequestModeUnicodeCore          => "\e[?2027\$p",
        SetModeLightDark                => "\e[?2031h",
        ResetModeLightDark              => "\e[?2031l",
        RequestModeLightDark            => "\e[?2031\$p",
        SetModeInBandResize             => "\e[?2048h",
        ResetModeInBandResize           => "\e[?2048l",
        RequestModeInBandResize         => "\e[?2048\$p",
        SetModeWin32Input               => "\e[?9001h",
        ResetModeWin32Input             => "\e[?9001l",
        RequestModeWin32Input           => "\e[?9001\$p",

        # DECST8C alias
        DECST8C => "\e[?5W",

        # Mouse
        MouseNone       => 0,
        MouseLeft       => 1,
        MouseMiddle     => 2,
        MouseRight      => 3,
        MouseWheelUp    => 4,
        MouseWheelDown  => 5,
        MouseWheelLeft  => 6,
        MouseWheelRight => 7,
        MouseBackward   => 8,
        MouseForward    => 9,
        MouseButton1    => 1,
        MouseButton2    => 2,
        MouseButton3    => 3,
        MouseButton4    => 4,
        MouseButton5    => 5,
        MouseButton6    => 6,
        MouseButton7    => 7,
        MouseButton8    => 8,
        MouseButton9    => 9,
        MouseButton10   => 10,
        MouseButton11   => 11,
        MouseRelease    => 0,
        B_SHIFT         => 0b0000_0100,
        B_ALT           => 0b0000_1000,
        B_CTRL          => 0b0001_0000,
        B_MOTION        => 0b0010_0000,
        B_WHEEL         => 0b0100_0000,
        B_ADD           => 0b1000_0000,
        B_MASK          => 0b0000_0011
    };

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

    sub MouseX10 ( $b, $x, $y ) {
        my $offset = 32;
        "\e[M" . chr( $b + $offset ) . chr( $x + $offset + 1 ) . chr( $y + $offset + 1 );
    }

    # Notification
    sub notify               ($s)                    {"\e]9;$s\a"}
    sub desktop_notification ( $payload, @metadata ) { "\e]99;" . join( ':', @metadata ) . ";$payload\a" }

    # SGR
    use constant {
        AttrReset                        => 0,
        AttrBold                         => 1,
        AttrFaint                        => 2,
        AttrItalic                       => 3,
        AttrUnderline                    => 4,
        AttrBlink                        => 5,
        AttrRapidBlink                   => 6,
        AttrReverse                      => 7,
        AttrConceal                      => 8,
        AttrStrikethrough                => 9,
        AttrNormalIntensity              => 22,
        AttrNoItalic                     => 23,
        AttrNoUnderline                  => 24,
        AttrNoBlink                      => 25,
        AttrNoReverse                    => 27,
        AttrNoConceal                    => 28,
        AttrNoStrikethrough              => 29,
        AttrBlackForegroundColor         => 30,
        AttrRedForegroundColor           => 31,
        AttrGreenForegroundColor         => 32,
        AttrYellowForegroundColor        => 33,
        AttrBlueForegroundColor          => 34,
        AttrMagentaForegroundColor       => 35,
        AttrCyanForegroundColor          => 36,
        AttrWhiteForegroundColor         => 37,
        AttrExtendedForegroundColor      => 38,
        AttrDefaultForegroundColor       => 39,
        AttrBlackBackgroundColor         => 40,
        AttrRedBackgroundColor           => 41,
        AttrGreenBackgroundColor         => 42,
        AttrYellowBackgroundColor        => 43,
        AttrBlueBackgroundColor          => 44,
        AttrMagentaBackgroundColor       => 45,
        AttrCyanBackgroundColor          => 46,
        AttrWhiteBackgroundColor         => 47,
        AttrExtendedBackgroundColor      => 48,
        AttrDefaultBackgroundColor       => 49,
        AttrExtendedUnderlineColor       => 58,
        AttrDefaultUnderlineColor        => 59,
        AttrBrightBlackForegroundColor   => 90,
        AttrBrightRedForegroundColor     => 91,
        AttrBrightGreenForegroundColor   => 92,
        AttrBrightYellowForegroundColor  => 93,
        AttrBrightBlueForegroundColor    => 94,
        AttrBrightMagentaForegroundColor => 95,
        AttrBrightCyanForegroundColor    => 96,
        AttrBrightWhiteForegroundColor   => 97,
        AttrBrightBlackBackgroundColor   => 100,
        AttrBrightRedBackgroundColor     => 101,
        AttrBrightGreenBackgroundColor   => 102,
        AttrBrightYellowBackgroundColor  => 103,
        AttrBrightBlueBackgroundColor    => 104,
        AttrBrightMagentaBackgroundColor => 105,
        AttrBrightCyanBackgroundColor    => 106,
        AttrBrightWhiteBackgroundColor   => 107,
        AttrRGBColorIntroducer           => 2,
        AttrExtendedColorIntroducer      => 5
    };

    sub SGR {
        return "\e[m" if !@_;
        my @parts;
        for my $a (@_) {
            my $p = $a;
            if ( $p =~ /^-?\d+$/ ) {
                $p = 0 if $p < 0;
                $p = 0 + $p;
            }
            push @parts, $p;
        }
        return "\e[" . join( ';', @parts ) . "m";
    }

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

    # FinalTerm shell integration
    sub FinalTerm            (@params) { "\e]133;" . join( ';', @params ) . "\a" }
    sub FinalTermPrompt      (@params) { FinalTerm( 'A', @params ) }
    sub FinalTermCmdStart    (@params) { FinalTerm( 'B', @params ) }
    sub FinalTermCmdExecuted (@params) { FinalTerm( 'C', @params ) }
    sub FinalTermCmdFinished (@params) { FinalTerm( 'D', @params ) }

    # Termcap/Terminfo
    sub XTGETTCAP (@caps) {
        return '' if !@caps;
        my $s = "\eP+q";
        for my $i ( 0 .. $#caps ) {
            $s .= ';' if $i > 0;
            $s .= uc( unpack( 'H*', $caps[$i] ) );
        }
        return $s . "\e\\";
    }
    sub RequestTermcap  (@caps) { XTGETTCAP(@caps) }
    sub RequestTerminfo (@caps) { XTGETTCAP(@caps) }

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
    use constant { ResetProgressBar => "\e]9;4;0\a", SetIndeterminateProgressBar => "\e]9;4;3\a" };

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

    # Cursor
    use constant {
        SaveCursor                     => "\e7",
        DECSC                          => "\e7",
        RestoreCursor                  => "\e8",
        DECRC                          => "\e8",
        CUU1                           => "\e[A",
        CUD1                           => "\e[B",
        CUF1                           => "\e[C",
        CUB1                           => "\e[D",
        CursorHomePosition             => "\e[H",
        HorizontalVerticalHomePosition => "\e[f",
        SaveCurrentCursorPosition      => "\e[s",
        SCOSC                          => "\e[s",
        RestoreCurrentCursorPosition   => "\e[u",
        SCORC                          => "\e[u",
        ReverseIndex                   => "\eM",
        Index                          => "\eD",
        RequestCursorPosition          => "\e[6n",
        RequestExtendedCursorPosition  => "\e[?6n"
    };
    sub CursorUp           ( $n //= 1 ) { $n > 1 ? "\e[${n}A" : "\e[A" }
    sub CUU                ( $n //= 1 ) { CursorUp($n) }
    sub CursorDown         ( $n //= 1 ) { $n > 1 ? "\e[${n}B" : "\e[B" }
    sub CUD                ( $n //= 1 ) { CursorDown($n) }
    sub CursorForward      ( $n //= 1 ) { $n > 1 ? "\e[${n}C" : "\e[C" }
    sub CUF                ( $n //= 1 ) { CursorForward($n) }
    sub CursorBackward     ( $n //= 1 ) { $n > 1 ? "\e[${n}D" : "\e[D" }
    sub CUB                ( $n //= 1 ) { CursorBackward($n) }
    sub CursorNextLine     ( $n //= 1 ) { $n > 1 ? "\e[${n}E" : "\e[E" }
    sub CNL                ( $n //= 1 ) { CursorNextLine($n) }
    sub CursorPreviousLine ( $n //= 1 ) { $n > 1 ? "\e[${n}F" : "\e[F" }
    sub CPL                ( $n //= 1 ) { CursorPreviousLine($n) }

    sub CursorHorizontalAbsolute ( $col = 1 ) {
        $col > 0 ? "\e[${col}G" : "\e[G";
    }
    sub CHA ( $col = 1 ) { CursorHorizontalAbsolute($col) }

    sub CursorPosition ( $col = 1, $row = 1 ) {
        return CursorHomePosition if $row <= 1 && $col <= 1;
        my $r = $row > 0 ? $row : '';
        my $c = $col > 0 ? $col : '';
        "\e[$r;${c}H";
    }
    sub CUP                        ( $col = 1, $row = 1 ) { CursorPosition( $col, $row ) }
    sub CursorHorizontalForwardTab ( $n //= 1 ) { $n > 1 ? "\e[${n}I" : "\e[I" }
    sub CHT                        ( $n //= 1 ) { CursorHorizontalForwardTab($n) }
    sub EraseCharacter             ( $n //= 1 ) { $n > 1 ? "\e[${n}X" : "\e[X" }
    sub ECH                        ( $n //= 1 ) { EraseCharacter($n) }
    sub CursorBackwardTab          ( $n //= 1 ) { $n > 1 ? "\e[${n}Z" : "\e[Z" }
    sub CBT                        ( $n //= 1 ) { CursorBackwardTab($n) }

    sub VerticalPositionAbsolute ( $row //= 1 ) {
        $row > 0 ? "\e[${row}d" : "\e[d";
    }
    sub VPA                      ( $row //= 1 ) { VerticalPositionAbsolute($row) }
    sub VerticalPositionRelative ( $n   //= 1 ) { $n > 1 ? "\e[${n}e" : "\e[e" }
    sub VPR                      ( $n   //= 1 ) { VerticalPositionRelative($n) }

    sub HorizontalVerticalPosition ( $col //= 1, $row //= 1 ) {
        my $r = $row > 0 ? $row : '';
        my $c = $col > 0 ? $col : '';
        "\e[$r;${c}f";
    }
    sub HVP ( $col //= 1, $row //= 1 ) { HorizontalVerticalPosition( $col, $row ) }

    sub SetCursorStyle ( $style //= 1 ) {
        $style = 0 if $style < 0;
        "\e[${style} q";
    }
    sub DECSCUSR        ( $style //= 1 ) { SetCursorStyle($style) }
    sub SetPointerShape ($shape)         {"\e]22;$shape\a"}

    sub HorizontalPositionAbsolute ( $col //= 1 ) {
        $col > 0 ? "\e[${col}`" : "\e[`";
    }
    sub HPA ( $col = 1 ) { HorizontalPositionAbsolute($col) }

    sub HorizontalPositionRelative ( $n //= 1 ) {
        $n > 0 ? "\e[${n}a" : "\e[a";
    }
    sub HPR ( $n //= 1 ) { HorizontalPositionRelative($n) }

    # Screen
    use constant {
        EraseScreenBelow    => "\e[J",
        EraseScreenAbove    => "\e[1J",
        EraseEntireScreen   => "\e[2J",
        EraseEntireDisplay  => "\e[3J",
        EraseLineRight      => "\e[K",
        EraseLineLeft       => "\e[1K",
        EraseEntireLine     => "\e[2K",
        HorizontalTabSet    => "\eH",
        SetTabEvery8Columns => "\e[?5W"
    };
    sub EraseDisplay ( $n //= 0 ) { $n > 0 ? "\e[${n}J" : "\e[J" }
    sub ED           ( $n //= 0 ) { EraseDisplay($n) }
    sub EraseLine    ( $n //= 0 ) { $n > 0 ? "\e[${n}K" : "\e[K" }
    sub EL           ( $n //= 0 ) { EraseLine($n) }
    sub ScrollUp     ( $n //= 1 ) { $n > 1 ? "\e[${n}S" : "\e[S" }
    sub SU           ( $n //= 1 ) { ScrollUp($n) }
    sub ScrollDown   ( $n //= 1 ) { $n > 1 ? "\e[${n}T" : "\e[T" }
    sub SD           ( $n //= 1 ) { ScrollDown($n) }
    sub InsertLine   ( $n //= 1 ) { $n > 1 ? "\e[${n}L" : "\e[L" }
    sub IL           ( $n //= 1 ) { InsertLine($n) }
    sub DeleteLine   ( $n //= 1 ) { $n > 1 ? "\e[${n}M" : "\e[M" }
    sub DL           ( $n //= 1 ) { DeleteLine($n) }

    sub SetTopBottomMargins ( $top //= 0, $bot //= 0 ) {
        my $t = $top > 0 ? $top : '';
        my $b = $bot > 0 ? $bot : '';
        "\e[$t;${b}r";
    }
    sub DECSTBM ( $top //= 0, $bot //= 0 ) { SetTopBottomMargins( $top, $bot ) }

    sub SetLeftRightMargins ( $left = 0, $right = 0 ) {
        my $l = $left > 0  ? $left  : '';
        my $r = $right > 0 ? $right : '';
        "\e[$l;${r}s";
    }
    sub DECSLRM         ( $left = 0, $right = 0 ) { SetLeftRightMargins( $left, $right ) }
    sub InsertCharacter ( $n //= 1 ) { $n > 1 ? "\e[${n}\@" : "\e[\@" }
    sub ICH             ( $n //= 1 ) { InsertCharacter($n) }
    sub DeleteCharacter ( $n //= 1 ) { $n > 1 ? "\e[${n}P" : "\e[P" }
    sub DCH             ( $n //= 1 ) { DeleteCharacter($n) }
    sub TabClear        ( $n //= 0 ) { $n > 0 ? "\e[$n" . 'g' : "\e[g" }
    sub TBC             ( $n //= 0 ) { TabClear($n) }

    sub RequestPresentationStateReport ( $n //= 0 ) {
        $n > 0 ? "\e[$n\$w" : "\e[\$w";
    }
    sub DECRQPSR ( $n //= 0 ) { RequestPresentationStateReport($n) }

    sub TabStopReport (@stops) {
        my @s = map {"$_"} @stops;
        "\eP2\$u" . join( '/', @s ) . "\e\\";
    }
    sub DECTABSR (@stops) { TabStopReport(@stops) }

    sub CursorInformationReport (@values) {
        my @s = map {"$_"} @values;
        "\eP1\$u" . join( ';', @s ) . "\e\\";
    }
    sub DECCIR                  (@values) { CursorInformationReport(@values) }
    sub RepeatPreviousCharacter ( $n //= 1 ) { $n > 1 ? "\e[${n}b" : "\e[b" }
    sub REP                     ( $n //= 1 ) { RepeatPreviousCharacter($n) }

    # Focus events
    use constant { Focus => "\e[I", Blur => "\e[O" };

    # Keypad modes
    use constant { KeypadApplicationMode => "\e=", DECKPAM => "\e=", KeypadNumericMode => "\e>", DECKPNM => "\e>" };

    # Device Attributes
    sub PrimaryDeviceAttributes (@attrs) {
        return "\e[c"  if !@attrs;
        return "\e[0c" if @attrs == 1 && $attrs[0] == 0;
        return "\e[?" . join( ';', @attrs ) . "c";
    }
    sub DA1 (@attrs) { PrimaryDeviceAttributes(@attrs) }
    use constant { RequestPrimaryDeviceAttributes => "\e[c" };

    sub SecondaryDeviceAttributes (@attrs) {
        return "\e[>c" if !@attrs;
        return "\e[>" . join( ';', @attrs ) . "c";
    }
    sub DA2 (@attrs) { SecondaryDeviceAttributes(@attrs) }
    use constant { RequestSecondaryDeviceAttributes => "\e[>c" };

    sub TertiaryDeviceAttributes ( $unit_id = '' ) {
        return "\e[=c"  if $unit_id eq '';
        return "\e[=0c" if $unit_id eq '0';
        return "\eP!|$unit_id\e\\";
    }
    sub DA3 ( $unit_id = '' ) { TertiaryDeviceAttributes($unit_id) }
    use constant { RequestTertiaryDeviceAttributes => "\e[=c" };

    # Version
    use constant { RequestNameVersion => "\e[>q", XTVERSION => "\e[>q" };

    # Kitty Keyboard Protocol
    # (constants are in Cancer::Ansi::Kitty)
    # Xterm Key Modifier Options
    use constant {
        SetModifyOtherKeys1    => "\e[>4;1m",
        SetModifyOtherKeys2    => "\e[>4;2m",
        ResetModifyOtherKeys   => "\e[>4m",
        QueryModifyOtherKeys   => "\e[?4m",
        DisableModifyOtherKeys => "\e[>4;0m",
        EnableModifyOtherKeys1 => "\e[>4;1m",
        EnableModifyOtherKeys2 => "\e[>4;2m",
        RequestModifyOtherKeys => "\e[?4m"
    };

    sub KeyModifierOptions ( $p, @vs ) {
        my $pp = $p > 0 ? "$p" : "$p";
        if ( !@vs ) {
            return "\e[>" . $pp . 'm';
        }
        my $v  = $vs[0];
        my $pv = $v > 0 ? "$v" : "$v";
        return "\e[>${pp};${pv}m";
    }
    sub XTMODKEYS               ( $p, @vs )  { KeyModifierOptions( $p,  @vs ) }
    sub SetKeyModifierOptions   ( $pp, $pv ) { KeyModifierOptions( $pp, $pv ) }
    sub ResetKeyModifierOptions ($pp)        { KeyModifierOptions($pp) }

    sub QueryKeyModifierOptions ($pp) {
        my $p = $pp > 0 ? "$pp" : "$pp";
        "\e[?${p}m";
    }
    sub XTQMODKEYS      ($pp)   { QueryKeyModifierOptions($pp) }
    sub ModifyOtherKeys ($mode) {"\e[>4;${mode}m"}

    # Window Operations
    use constant { ResizeWindowWinOp => 4, RequestWindowSizeWinOp => 14, RequestCellSizeWinOp => 16 };

    sub WindowOp ( $p, @ps ) {
        return '' if $p <= 0;
        if ( !@ps ) {
            return "\e[${p}t";
        }
        my @params = ("$p");
        for my $pp (@ps) {
            push @params, "$pp" if $pp >= 0;
        }
        "\e[" . join( ';', @params ) . 't';
    }
    sub XTWINOPS ( $p, @ps ) { WindowOp( $p, @ps ) }

    # Device Status Reports
    use constant { RequestCursorPositionReport => "\e[6n", RequestExtendedCursorPositionReport => "\e[?6n", RequestLightDarkReport => "\e[?996n" };

    sub DeviceStatusReport (@statuses) {
        my $dec = 0;
        for my $s (@statuses) {
            $dec = 1 if ref($s) && $s->[0] eq 'DEC';
        }
        my $seq = "\e[";
        $seq .= '?' if $dec;
        my @parts = map { ref($_) ? $_->[1] : "$_" } @statuses;
        return $seq . join( ';', @parts ) . 'n';
    }
    sub DSR (@statuses) { DeviceStatusReport(@statuses) }

    sub CursorPositionReport ( $line, $column ) {
        $line   = 1 if $line < 1;
        $column = 1 if $column < 1;
        "\e[$line;${column}R";
    }
    sub CPR ( $line, $column ) { CursorPositionReport( $line, $column ) }

    sub ExtendedCursorPositionReport ( $line, $column, $page = 0 ) {
        $line   = 1 if $line < 1;
        $column = 1 if $column < 1;
        if ( $page < 1 ) {
            return "\e[?${line};${column}R";
        }
        "\e[?${line};${column};${page}R";
    }
    sub DECXCPR ( $line, $column, $page = 0 ) { ExtendedCursorPositionReport( $line, $column, $page ) }

    sub LightDarkReport ($dark) {
        $dark ? "\e[?997;1n" : "\e[?997;2n";
    }

    # Character Set Selection
    use constant { LS1R => "\e~", LS2 => "\en", LS2R => "\e}", LS3 => "\eo", LS3R => "\e|" };
    sub SelectCharacterSet ( $gset, $charset ) {"\e$gset$charset"}
    sub SCS                ( $gset, $charset ) { SelectCharacterSet( $gset, $charset ) }

    # Underline Styles (SGR)
    use constant {
        UnderlineNone   => 0,
        UnderlineSingle => 1,
        UnderlineDouble => 2,
        UnderlineCurly  => 3,
        UnderlineDotted => 4,
        UnderlineDashed => 5,
        ResetStyle      => "\e[m"
    };

    # Style builder
    # attrStrings maps known SGR attribute integers to their string representations
    my %attr_strings = (
        0   => '0',
        1   => '1',
        2   => '2',
        3   => '3',
        4   => '4',
        5   => '5',
        6   => '6',
        7   => '7',
        8   => '8',
        9   => '9',
        22  => '22',
        23  => '23',
        24  => '24',
        25  => '25',
        27  => '27',
        28  => '28',
        29  => '29',
        30  => '30',
        31  => '31',
        32  => '32',
        33  => '33',
        34  => '34',
        35  => '35',
        36  => '36',
        37  => '37',
        38  => '38',
        39  => '39',
        40  => '40',
        41  => '41',
        42  => '42',
        43  => '43',
        44  => '44',
        45  => '45',
        46  => '46',
        47  => '47',
        48  => '48',
        49  => '49',
        58  => '58',
        59  => '59',
        90  => '90',
        91  => '91',
        92  => '92',
        93  => '93',
        94  => '94',
        95  => '95',
        96  => '96',
        97  => '97',
        100 => '100',
        101 => '101',
        102 => '102',
        103 => '103',
        104 => '104',
        105 => '105',
        106 => '106',
        107 => '107',

        # Underline style strings
        1000 => '4:2',
        1001 => '4:3',
        1002 => '4:4',
        1003 => '4:5'
    );

    # Private underscore constants matching Go's attr* strings
    use constant {
        _attrReset           => '0',
        _attrBold            => '1',
        _attrFaint           => '2',
        _attrItalic          => '3',
        _attrUnderline       => '4',
        _attrBlink           => '5',
        _attrRapidBlink      => '6',
        _attrReverse         => '7',
        _attrConceal         => '8',
        _attrStrikethrough   => '9',
        _attrNormalIntensity => '22',
        _attrNoItalic        => '23',
        _attrNoUnderline     => '24',
        _attrNoBlink         => '25',
        _attrNoReverse       => '27',
        _attrNoConceal       => '28',
        _attrNoStrikethrough => '29',
        _underlineDouble     => '4:2',
        _underlineCurly      => '4:3',
        _underlineDotted     => '4:4',
        _underlineDashed     => '4:5'
    };

    # Underline style enum values (matching Go's Underline type)
    use constant {
        _underlineNone    => 0,
        _underlineSingle  => 1,
        _underlineDoubleV => 2,
        _underlineCurlyV  => 3,
        _underlineDottedV => 4,
        _underlineDashedV => 5
    };

    package Cancer::Ansi::Style {
        use v5.42;
        use Carp;
        my $_a = \%attr_strings;

        sub new ( $class, @attrs ) {
            my @parts;
            for my $a (@attrs) {
                my $s = $_a->{$a};
                if ( defined $s ) {
                    push @parts, $s;
                }
                else {
                    $a = 0 if $a < 0;
                    push @parts, "$a";
                }
            }
            return bless \@parts, $class;
        }

        sub to_string ($self) {
            return "\e[m" if !@$self;
            return "\e[" . join( ';', @$self ) . "m";
        }

        sub styled ( $self, $str ) {
            return $str if !@$self;
            return $self->to_string . $str . "\e[m";
        }

        sub reset ($self) {
            return bless [ @$self, Cancer::Ansi::_attrReset ], ref $self;
        }

        sub bold ($self) {
            return bless [ @$self, Cancer::Ansi::_attrBold ], ref $self;
        }

        sub faint ($self) {
            return bless [ @$self, Cancer::Ansi::_attrFaint ], ref $self;
        }

        sub italic ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrItalic : Cancer::Ansi::_attrNoItalic ], ref $self;
        }

        sub underline ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrUnderline : Cancer::Ansi::_attrNoUnderline ], ref $self;
        }

        sub underline_style ( $self, $style ) {
            my %map = (
                Cancer::Ansi::_underlineNone()    => undef,
                Cancer::Ansi::_underlineSingle()  => Cancer::Ansi::_attrUnderline,
                Cancer::Ansi::_underlineDoubleV() => Cancer::Ansi::_underlineDouble,
                Cancer::Ansi::_underlineCurlyV()  => Cancer::Ansi::_underlineCurly,
                Cancer::Ansi::_underlineDottedV() => Cancer::Ansi::_underlineDotted,
                Cancer::Ansi::_underlineDashedV() => Cancer::Ansi::_underlineDashed
            );
            my $attr = $map{$style};
            if ( !defined $attr ) {
                return $self->underline(0);
            }
            return bless [ @$self, $attr ], ref $self;
        }

        sub blink ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrBlink : Cancer::Ansi::_attrNoBlink ], ref $self;
        }

        sub rapid_blink ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrRapidBlink : Cancer::Ansi::_attrNoBlink ], ref $self;
        }

        sub reverse ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrReverse : Cancer::Ansi::_attrNoReverse ], ref $self;
        }

        sub conceal ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrConceal : Cancer::Ansi::_attrNoConceal ], ref $self;
        }

        sub strikethrough ( $self, $v = 1 ) {
            return bless [ @$self, $v ? Cancer::Ansi::_attrStrikethrough : Cancer::Ansi::_attrNoStrikethrough ], ref $self;
        }

        sub normal ($self) {
            return bless [ @$self, Cancer::Ansi::_attrNormalIntensity ], ref $self;
        }

        sub foreground_color ( $self, $color ) {
            return bless [ @$self, '39' ], ref $self if !defined $color;
            return $self->_set_color( 38, $color );
        }

        sub background_color ( $self, $color ) {
            return bless [ @$self, '49' ], ref $self if !defined $color;
            return $self->_set_color( 48, $color );
        }

        sub underline_color ( $self, $color ) {
            return bless [ @$self, '59' ], ref $self if !defined $color;
            return $self->_set_color( 58, $color );
        }

        sub _set_color ( $self, $prefix, $color ) {
            if ( ref $color eq 'ARRAY' ) {
                my ( $r, $g, $b ) = @$color;
                return bless [ @$self, "${prefix};2;$r;$g;$b" ], ref $self;
            }
            $color = 0 if $color < 0;
            return bless [ @$self, "${prefix};5;$color" ], ref $self;
        }
        *Foreground   = \&foreground_color;
        *Background   = \&background_color;
        *UnderlineCol = \&underline_color;
    }

    # Style builder forwarding functions (defined in Cancer::Ansi::Style package)
    sub NewStyle { Cancer::Ansi::Style->new(@_) }
    sub Style    { Cancer::Ansi::Style->new(@_) }
}
#
1;
