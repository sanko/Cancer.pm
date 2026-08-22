use v5.42;
use experimental 'class';
#
package Cancer::Util v0.0.1 {
    use parent 'Exporter';
    use Encode;
    state @zero_ranges = (
        [ 0x00AD,  0x00AD ],                                                                                    # Soft Hyphen
        [ 0x0300,  0x036F ],                                                                                    # Combining Diacritical Marks
        [ 0x0483,  0x0489 ],                                                                                    # Cyrillic combining marks
        [ 0x0591,  0x05BD ],                                                                                    # Hebrew combining marks
        [ 0x05BF,  0x05BF ], [ 0x05C1, 0x05C2 ], [ 0x05C4, 0x05C5 ], [ 0x05C7, 0x05C7 ], [ 0x0610, 0x061A ],    # Arabic combining marks
        [ 0x064B,  0x065F ], [ 0x0670, 0x0670 ], [ 0x06D6, 0x06DC ], [ 0x06DF, 0x06E4 ], [ 0x06E7, 0x06E8 ], [ 0x06EA, 0x06ED ],
        [ 0x0711,  0x0711 ],                                                                                    # Syriac
        [ 0x0730,  0x074A ], [ 0x07A6, 0x07B0 ],                                                                # Thaana
        [ 0x0900,  0x0902 ],                                                                                    # Devanagari
        [ 0x093A,  0x093A ], [ 0x093C, 0x093C ], [ 0x0941, 0x0948 ], [ 0x094D, 0x094D ], [ 0x0951, 0x0957 ], [ 0x0962, 0x0963 ],
        [ 0x0981,  0x0981 ],                                                                                    # Bengali
        [ 0x09BC,  0x09BC ], [ 0x09C1, 0x09C4 ], [ 0x09CD, 0x09CD ], [ 0x09E2, 0x09E3 ], [ 0x0A01, 0x0A02 ],    # Gurmukhi
        [ 0x0A3C,  0x0A3C ], [ 0x0A41, 0x0A42 ], [ 0x0A47, 0x0A48 ], [ 0x0A4B, 0x0A4D ], [ 0x0A70, 0x0A71 ], [ 0x0A81, 0x0A82 ],    # Gujarati
        [ 0x0ABC,  0x0ABC ], [ 0x0AC1, 0x0AC5 ], [ 0x0AC7, 0x0AC8 ], [ 0x0ACD, 0x0ACD ], [ 0x0AE2, 0x0AE3 ], [ 0x0B01, 0x0B01 ],    # Oriya
        [ 0x0B3C,  0x0B3C ], [ 0x0B3F, 0x0B3F ], [ 0x0B41, 0x0B43 ], [ 0x0B4D, 0x0B4D ], [ 0x0B56, 0x0B56 ], [ 0x0B82, 0x0B82 ],    # Tamil
        [ 0x0BC0,  0x0BC0 ], [ 0x0BCD, 0x0BCD ], [ 0x0C3E, 0x0C40 ],                                                                # Telugu
        [ 0x0C46,  0x0C48 ], [ 0x0C4A, 0x0C4D ], [ 0x0C55, 0x0C56 ], [ 0x0CBC, 0x0CBC ],                                            # Kannada
        [ 0x0CBF,  0x0CBF ], [ 0x0CC6, 0x0CC6 ], [ 0x0CCC, 0x0CCD ], [ 0x0CE2, 0x0CE3 ], [ 0x0D41, 0x0D43 ],                        # Malayalam
        [ 0x0D4D,  0x0D4D ], [ 0x0DCA, 0x0DCA ],                                                                                    # Sinhala
        [ 0x0DD2,  0x0DD4 ], [ 0x0DD6, 0x0DD6 ], [ 0x0E31, 0x0E31 ],                                                                # Thai
        [ 0x0E34,  0x0E3A ], [ 0x0E47, 0x0E4E ], [ 0x0EB1, 0x0EB1 ],                                                                # Lao
        [ 0x0EB4,  0x0EB9 ], [ 0x0EBB, 0x0EBC ], [ 0x0EC8, 0x0ECD ], [ 0x0F18, 0x0F19 ],                                            # Tibetan
        [ 0x0F35,  0x0F35 ], [ 0x0F37, 0x0F37 ], [ 0x0F39, 0x0F39 ], [ 0x0F71, 0x0F7E ], [ 0x0F80, 0x0F84 ], [ 0x0F86, 0x0F87 ], [ 0x0F90, 0x0F97 ],
        [ 0x0F99,  0x0FBC ], [ 0x0FC6, 0x0FC6 ], [ 0x1032, 0x1032 ],                                                                # Myanmar
        [ 0x1036,  0x1037 ], [ 0x1039, 0x1039 ], [ 0x1058, 0x1059 ], [ 0x108D, 0x108D ],
        [ 0x1160,  0x11FF ],    # Hangul Jungseong/Jongseong (zero-width fillers)
        [ 0x135F,  0x135F ],    # Ethiopic
        [ 0x1712,  0x1714 ],    # Tagalog
        [ 0x1732,  0x1734 ],    # Hanunoo
        [ 0x1752,  0x1753 ],    # Buhid
        [ 0x1772,  0x1773 ],    # Tagbanwa
        [ 0x17B4,  0x17B5 ],    # Khmer
        [ 0x17B7,  0x17BD ], [ 0x17C6, 0x17C6 ], [ 0x17C9, 0x17D3 ], [ 0x17DD, 0x17DD ], [ 0x180B, 0x180E ],    # Mongolian
        [ 0x18A9,  0x18A9 ], [ 0x1920, 0x1922 ],                                                                # Limbu
        [ 0x1927,  0x1928 ], [ 0x1932, 0x1932 ], [ 0x1939, 0x193B ], [ 0x1A17, 0x1A18 ],                        # Buginese
        [ 0x1B00,  0x1B03 ],                                                                                    # Balinese
        [ 0x1B34,  0x1B34 ], [ 0x1B36, 0x1B3A ], [ 0x1B3C, 0x1B3C ], [ 0x1B42, 0x1B42 ], [ 0x1B6B, 0x1B73 ],    # Balinese musical
        [ 0x1DC0,  0x1DFF ],     # Combining Diacritical Marks Supplement
        [ 0x200B,  0x200F ],     # ZW space, ZWNJ, ZWJ, LRM, RLM
        [ 0x2028,  0x202E ],     # Line/Paragraph separator, Bidi controls
        [ 0x2060,  0x2064 ],     # Word joiner, invisible operators
        [ 0x2066,  0x206F ],     # Bidi controls
        [ 0x20D0,  0x20EF ],     # Combining Marks for Symbols
        [ 0x3099,  0x309A ],     # Combining Katakana-Hiragana voiced sound marks
        [ 0xFE00,  0xFE0F ],     # Variation Selectors
        [ 0xFE20,  0xFE2F ],     # Combining Half Marks
        [ 0xFEFF,  0xFEFF ],     # BOM / ZWNBSP
        [ 0xFF9E,  0xFF9F ],     # Halfwidth Katakana voiced sound marks
        [ 0xFFF9,  0xFFFB ],     # Interlinear annotation
        [ 0x1D165, 0x1D169 ],    # Musical combining marks
        [ 0x1D16D, 0x1D172 ], [ 0x1D17B, 0x1D182 ], [ 0x1D185, 0x1D18B ], [ 0x1D1AA, 0x1D1AD ], [ 0x1D242, 0x1D244 ],    # Combined musical
        [ 0xE0020, 0xE007F ],    # Tag characters
        [ 0xE0100, 0xE01EF ]     # Variation Selectors Supplement
    );
    state @wide_ranges = (
        [ 0x1100,  0x115F ],     # Hangul Jamo
        [ 0x231A,  0x231B ],     # Watch, hourglass
        [ 0x2329,  0x232A ],     # Angle brackets
        [ 0x23E9,  0x23EC ],     # Fast forward, rewind etc
        [ 0x23F0,  0x23F0 ],     # Alarm clock
        [ 0x23F3,  0x23F3 ],     # Hourglass with flowing sand
        [ 0x25FD,  0x25FE ],     # Medium small squares
        [ 0x2614,  0x2615 ],     # Umbrella, hot beverage
        [ 0x2630,  0x2637 ],     # Trigram symbols
        [ 0x2648,  0x2653 ],     # Zodiac symbols
        [ 0x267F,  0x267F ],     # Wheelchair
        [ 0x268A,  0x268F ],     # Dice
        [ 0x2693,  0x2693 ],     # Anchor
        [ 0x26A1,  0x26A1 ],     # High voltage
        [ 0x26AA,  0x26AB ],     # White/black circles
        [ 0x26BD,  0x26BE ],     # Soccer, baseball
        [ 0x26C4,  0x26C5 ],     # Snowman, sun
        [ 0x26CE,  0x26CE ],     # Ophiuchus
        [ 0x26D4,  0x26D4 ],     # No entry
        [ 0x26EA,  0x26EA ],     # Church
        [ 0x26F2,  0x26F3 ],     # Fountain, golf
        [ 0x26F5,  0x26F5 ],     # Sailboat
        [ 0x26FA,  0x26FA ],     # Tent
        [ 0x26FD,  0x26FD ],     # Fuel pump
        [ 0x2705,  0x2705 ],     # Check mark
        [ 0x270A,  0x270B ],     # Raised fist, hand
        [ 0x2728,  0x2728 ],     # Sparkles
        [ 0x274C,  0x274C ],     # Cross mark
        [ 0x274E,  0x274E ],     # Cross mark button
        [ 0x2753,  0x2755 ],     # Question marks
        [ 0x2757,  0x2757 ],     # Exclamation mark
        [ 0x2795,  0x2797 ],     # Plus, minus, divide
        [ 0x27B0,  0x27B0 ],     # Curly loop
        [ 0x27BF,  0x27BF ],     # Double curly loop
        [ 0x2B1B,  0x2B1C ],     # Black/white large squares
        [ 0x2B50,  0x2B50 ],     # Star
        [ 0x2B55,  0x2B55 ],     # Heavy circle
        [ 0x2E80,  0x2E99 ],     # CJK Radicals Supplement
        [ 0x2E9B,  0x2EF3 ],     # CJK Radicals Supplement (cont)
        [ 0x2F00,  0x2FD5 ],     # Kangxi Radicals
        [ 0x2FF0,  0x303E ],     # Ideographic Description + CJK Symbols
        [ 0x3041,  0x3096 ],     # Hiragana
        [ 0x3099,  0x30FF ],     # Combining marks + Katakana
        [ 0x3105,  0x312F ],     # Bopomofo
        [ 0x3131,  0x318E ],     # Hangul Compatibility Jamo
        [ 0x3190,  0x31E5 ],     # Kanbun + CJK Strokes
        [ 0x31EF,  0x321E ],     # CJK Strokes + Enclosed CJK Letters
        [ 0x3220,  0x3247 ],     # Parenthesized CJK
        [ 0x3250,  0xA48C ],     # CJK Unified Ideographs Ext A + Yi
        [ 0xA490,  0xA4C6 ],     # Yi Radicals
        [ 0xA960,  0xA97C ],     # Hangul Jamo Extended-A
        [ 0xAC00,  0xD7A3 ],     # Hangul Syllables
        [ 0xF900,  0xFAFF ],     # CJK Compatibility Ideographs
        [ 0xFE10,  0xFE19 ],     # Vertical Forms
        [ 0xFE30,  0xFE52 ],     # CJK Compatibility Forms
        [ 0xFE54,  0xFE66 ],     # CJK Compatibility Forms (cont)
        [ 0xFE68,  0xFE6B ],     # Small symbols
        [ 0xFF01,  0xFF60 ],     # Fullwidth Forms
        [ 0xFFE0,  0xFFE6 ],     # Fullwidth Signs
        [ 0x16FE0, 0x16FE4 ],    # Ideographic Symbols + Tangut
        [ 0x16FF0, 0x16FF6 ],    # Miao
        [ 0x17000, 0x18CD5 ],    # Tangut
        [ 0x18CFF, 0x18D1E ],    # Tangut Supplement
        [ 0x18D80, 0x18DF2 ],    # Tangut Components
        [ 0x1AFF0, 0x1AFF3 ],    # Kana Extended-B
        [ 0x1AFF5, 0x1AFFB ],    # Kana Extended-B (cont)
        [ 0x1AFFD, 0x1AFFE ],    # Kana Extended-B (cont)
        [ 0x1B000, 0x1B122 ],    # Kana Supplement + Extended-A
        [ 0x1B132, 0x1B132 ],    # Hiragana small A
        [ 0x1B150, 0x1B152 ],    # Hiragana small vowel
        [ 0x1B155, 0x1B155 ],    # Katakana small O
        [ 0x1B164, 0x1B167 ],    # Katakana small vowel
        [ 0x1B170, 0x1B2FB ],    # Nushu
        [ 0x1D300, 0x1D356 ],    # Tai Xuan Jing
        [ 0x1D360, 0x1D376 ],    # Counting rod
        [ 0x1F004, 0x1F004 ],    # Mahjong red dragon
        [ 0x1F0CF, 0x1F0CF ],    # Joker
        [ 0x1F18E, 0x1F18E ],    # AB button
        [ 0x1F191, 0x1F19A ],    # CL etc squared buttons
        [ 0x1F200, 0x1F202 ],    # Squared katakana
        [ 0x1F210, 0x1F23B ],    # Squared CJK
        [ 0x1F240, 0x1F248 ],    # Tortoised shell CJK
        [ 0x1F250, 0x1F251 ],    # Circled CJK
        [ 0x1F260, 0x1F265 ],    # Rounded symbols
        [ 0x1F300, 0x1F320 ],    # Misc Symbols + Weather
        [ 0x1F32D, 0x1F335 ],    # Food emoji
        [ 0x1F337, 0x1F37C ],    # Plant + drink emoji
        [ 0x1F37E, 0x1F393 ],    # Bottle + celebration emoji
        [ 0x1F3A0, 0x1F3CA ],    # Entertainment + sport emoji
        [ 0x1F3CF, 0x1F3D3 ],    # Cricket + paddle etc
        [ 0x1F3E0, 0x1F3F0 ],    # Building emoji
        [ 0x1F3F4, 0x1F3F4 ],    # Black flag
        [ 0x1F3F8, 0x1F43E ],    # Sport + animal emoji
        [ 0x1F440, 0x1F440 ],    # Eyes
        [ 0x1F442, 0x1F4FC ],    # Body parts + object emoji
        [ 0x1F4FF, 0x1F53D ],    # Objects + symbols emoji
        [ 0x1F54B, 0x1F54E ],    # Mosque + candle emoji
        [ 0x1F550, 0x1F567 ],    # Clock emoji
        [ 0x1F57A, 0x1F57A ],    # Man dancing
        [ 0x1F595, 0x1F596 ],    # Middle finger + vulcan
        [ 0x1F5A4, 0x1F5A4 ],    # Black heart
        [ 0x1F5FB, 0x1F64F ],    # Landmark + emotion emoji
        [ 0x1F680, 0x1F6C5 ],    # Transport emoji
        [ 0x1F6CC, 0x1F6CC ],    # Sleeping accommodation
        [ 0x1F6D0, 0x1F6D2 ],    # Place of worship + hindu + chinese
        [ 0x1F6D5, 0x1F6D8 ],    # Hindu temple etc
        [ 0x1F6DC, 0x1F6DF ],    # Ring buoy etc
        [ 0x1F6EB, 0x1F6EC ],    # Airplane
        [ 0x1F6F4, 0x1F6FC ],    # Scooter + roller skate etc
        [ 0x1F7E0, 0x1F7EB ],    # Orange/blue/red dots
        [ 0x1F7F0, 0x1F7F0 ],    # Heavy equals sign
        [ 0x1F90C, 0x1F93A ],    # Hand + juggling emoji
        [ 0x1F93C, 0x1F945 ],    # Wrestling + goal emoji
        [ 0x1F947, 0x1F9FF ],    # Medal + medical emoji
        [ 0x1FA70, 0x1FA7C ],    # Symbols Extended-A
        [ 0x1FA80, 0x1FA8A ],    # Symbols Extended-A (cont)
        [ 0x1FA8E, 0x1FAC6 ],    # Symbols Extended-A (cont)
        [ 0x1FAC8, 0x1FAC8 ],    # Pouring liquid
        [ 0x1FACD, 0x1FADC ],    # Heart hands etc
        [ 0x1FADF, 0x1FAEA ],    # Folding fan etc
        [ 0x1FAEF, 0x1FAF8 ],    # Lower left ballpoint pen etc
        [ 0x20000, 0x2FFFD ],    # CJK Extensions B-F
        [ 0x30000, 0x3FFFD ]     # CJK Extensions G, H
    );
    our @EXPORT_OK
        = qw[byte_to_grapheme_range truncate truncate_left cut visual_width grapheme_width width height size visual_truncate ansi_cut strip_ansi
        string_width string_width_wc go_duration hardwrap wordwrap wrap
        _max _min _to6cube _dist_sq];
    sub _max ( $a, $b ) { $a > $b ? $a : $b }
    sub _min ( $a, $b ) { $a < $b ? $a : $b }

    sub _to6cube ($v) {
        return 0 if $v < 48;
        return 1 if $v < 115;
        return int( ( $v - 35 ) / 40 );
    }

    sub _dist_sq ( $r1, $g1, $b1, $r2, $g2, $b2 ) {
        ( $r1 - $r2 )**2 + ( $g1 - $g2 )**2 + ( $b1 - $b2 )**2;
    }

    sub _in_ranges ( $cp, $ranges ) {
        my $lo = 0;
        my $hi = $#$ranges;
        while ( $lo <= $hi ) {
            my $mid = int( ( $lo + $hi ) / 2 );
            my $r   = $ranges->[$mid];
            return 1 if $cp >= $r->[0] && $cp <= $r->[1];
            if ( $cp < $r->[0] ) {
                $hi = $mid - 1;
            }
            else {
                $lo = $mid + 1;
            }
        }
        return 0;
    }

    sub _char_width ($cp) {
        return 0 if $cp < 0x20;                          # C0 controls
        return 1 if $cp >= 0x20 && $cp < 0x7F;           # ASCII printable fast path
        return 0 if $cp == 0x7F;                         # DEL
        return 0 if $cp >= 0x80    && $cp <= 0x9F;       # C1 controls
        return 1 if $cp >= 0x1F1E6 && $cp <= 0x1F1FF;    # Regional Indicators: width 1 each
        return 2 if _in_ranges( $cp, \@wide_ranges );
        return 0 if _in_ranges( $cp, \@zero_ranges );
        return 1;
    }

    # Width of one extended grapheme cluster. Single code points take the fast
    # path; multi-code-point clusters (ZWJ emoji, combining marks, RI pairs,
    # VS16 upgrades) are measured as a whole so they can never be torn apart.
    sub _cluster_width ($tok) {
        return _char_width( ord($tok) ) if length($tok) == 1;
        return _calc_width_grapheme($tok);
    }

    sub visual_width ($str) {
        return 0 if !defined $str;
        my $clean = $str;
        $clean =~ s/\ePzone:.*?\e//g;
        $clean =~ s/\e\[[\d;]*[a-zA-Z~]//g;
        $clean =~ s/\e\(B//g;
        $clean =~ s/\x9b[\d;]*[a-zA-Z~]//g;
        $clean =~ s/\x9d.*?(\a|\x9c|\e\\)//g;
        $clean =~ s/[\x90\x98\x9e\x9f].*?(\x9c|\e\\)//g;
        $clean =~ s/[\x80-\x8a\x8c-\x8f\x91-\x97\x99\x9a\x9c]//g;
        return _calc_width( $clean, 1 );
    }

    sub grapheme_width ($str) {
        return 0 if !defined $str;
        my $clean = $str;
        $clean =~ s/\ePzone:.*?\e//g;
        $clean =~ s/\e\[[\d;]*[a-zA-Z~]//g;
        $clean =~ s/\e\(B//g;
        $clean =~ s/\x9b[\d;]*[a-zA-Z~]//g;
        $clean =~ s/\x9d.*?(\a|\x9c|\e\\)//g;
        $clean =~ s/[\x90\x98\x9e\x9f].*?(\x9c|\e\\)//g;
        $clean =~ s/[\x80-\x8a\x8c-\x8f\x91-\x97\x99\x9a\x9c]//g;
        return _calc_width_grapheme($clean);
    }

    sub _is_indic_virama ($cp) {
        return 1 if $cp == 0x094D;    # Devanagari
        return 1 if $cp == 0x09CD;    # Bengali
        return 1 if $cp == 0x0A4D;    # Gurmukhi
        return 1 if $cp == 0x0ACD;    # Gujarati
        return 1 if $cp == 0x0B4D;    # Oriya
        return 1 if $cp == 0x0BCD;    # Tamil
        return 1 if $cp == 0x0C4D;    # Telugu
        return 1 if $cp == 0x0CCD;    # Kannada
        return 1 if $cp == 0x0D4D;    # Malayalam
        return 1 if $cp == 0x0DCA;    # Sinhala
        return 0;
    }

    sub _calc_width_grapheme ($str) {
        my $width = 0;
        my @cp    = unpack 'U*', $str;
        my $i     = 0;
        while ( $i <= $#cp ) {
            my $o = $cp[ $i++ ];
            next if $o < 0x20;

            # Isolated ZWJ in continuation (shouldn't start a cluster)
            if ( $o == 0x200D ) { $i++ if $i <= $#cp; next }

            # Indic virama acts as cluster joiner (consonant + virama + consonant)
            if ( _is_indic_virama($o) ) { $i++ if $i <= $#cp; next }

            # Regional Indicator pair
            if ( $o >= 0x1F1E6 && $o <= 0x1F1FF ) {
                $i++ if $i <= $#cp && $cp[$i] >= 0x1F1E6 && $cp[$i] <= 0x1F1FF;
                $width += 2;
                next;
            }

            # VS16 upgrade (emoji presentation)
            my $has_vs16 = ( $i <= $#cp && $cp[$i] == 0xFE0F ) ? ( $i++, 1 ) : 0;
            my $w        = _char_width($o);
            $w = 2 if $has_vs16 && $w == 1;

            # Consume Fitzpatrick skin tone modifier as part of this cluster
            if ( $i <= $#cp && $cp[$i] >= 0x1F3FB && $cp[$i] <= 0x1F3FF ) {
                $i++;
            }

            # Consume ZWJ continuation as part of this cluster
            while ( $i <= $#cp && $cp[$i] == 0x200D ) {
                $i++;
                $i++ if $i <= $#cp;
            }
            $width += $w;
        }
        return $width;
    }

    sub width ($str) {
        return 0 if !defined $str;
        my $max = 0;
        my $pos = 0;
        while (1) {
            my $nl   = index( $str, "\n", $pos );
            my $line = $nl == -1 ? substr( $str, $pos ) : substr( $str, $pos, $nl - $pos );
            my $w    = visual_width($line);
            $max = $w if $w > $max;
            last if $nl == -1;
            $pos = $nl + 1;
        }
        return $max;
    }

    sub height ($str) {
        return 0 if !defined $str;
        return 1 if $str eq '';
        my $count = 0;
        my $pos   = 0;
        while ( ( $pos = index( $str, "\n", $pos ) ) != -1 ) {
            $count++;
            $pos++;
        }
        return $count + 1;
    }
    sub size ($str) { width($str), height($str) }

    sub visual_truncate ( $str, $max_width ) {
        return '' if !defined $str;
        my $current_width = 0;
        my $result        = '';
        my $in_escape     = 0;

        # \X iterates whole extended grapheme clusters; ANSI escapes are pure
        # ASCII so each of their bytes still arrives as its own cluster and the
        # state machine below works unchanged.
        while ( $str =~ /(\X)/gc ) {
            my $char = $1;
            if ($in_escape) {
                $result .= $char;
                $in_escape = 0 if $char =~ /[a-zA-Z~]/;
                next;
            }
            if ( $char eq "\e" ) {
                $result .= $char;
                $in_escape = 1;
                next;
            }
            my $w = _cluster_width($char);
            last if ( $current_width + $w ) > $max_width;
            $result .= $char;
            $current_width += $w;
        }
        return $result;
    }

    # ansi_cut mirrors x/ansi Cut(s, 0, width): the first `$width` cells of the
    # string are kept, and every ANSI escape sequence after the cut is still
    # emitted (with the printable text dropped) so a styled line keeps its
    # trailing style-only segments, exactly as the v2 viewport renders.
    sub ansi_cut ( $str, $width ) {
        return ''   if !defined $str;
        return $str if visual_width($str) <= $width;
        my $out      = '';
        my $cur      = 0;
        my $ignoring = 0;
        my $pos      = 0;
        my $len      = length $str;
        while ( $pos < $len ) {
            my $c = substr( $str, $pos, 1 );
            if ( $c eq "\e" ) {
                if ( substr( $str, $pos ) =~ /\A\e\[[0-9;]*[A-Za-z]/ ) {
                    $out .= $&;
                    $pos += length $&;
                    next;
                }
                $out .= "\e";
                $pos++;
                next;
            }
            pos($str) = $pos;
            my $cluster = ( $str =~ /\G(\X)/gc ) ? $1 : undef;
            if ($ignoring) {
                if ( defined $cluster ) {
                    $pos += length $cluster;
                }
                else {
                    $pos++;
                }
                next;
            }
            if ( !defined $cluster ) {
                $out .= $c;
                $pos++;
                next;
            }
            $out .= $cluster;
            $cur += _cluster_width($cluster);
            $pos += length $cluster;
            if ( $cur >= $width ) {
                $ignoring = 1;
            }
        }
        return $out;
    }

    sub strip_ansi ($str) {
        return '' unless defined $str;
        my $s = $str;
        $s =~ s/\e\[[\d;]*[a-zA-Z~]//g;
        $s =~ s/\e\].*?(\a|\e\\)//g;
        $s =~ s/\e[PX^_].*?\e\\//g;
        $s =~ s/\e[NO\\]//g;
        $s =~ s/\x9b[\d;]*[a-zA-Z~]//g;                          # 8-bit CSI
        $s =~ s/\x9d.*?(\a|\x9c|\e\\)//g;                        # 8-bit OSC
        $s =~ s/[\x90\x98\x9e\x9f].*?(\x9c|\e\\)//g;             # 8-bit DCS/SOS/PM/APC
        $s =~ s/[\x80-\x8a\x8c-\x8f\x91-\x97\x99\x9a\x9c]//g;    # Other C1 controls
        return $s;
    }

    sub _calc_width ( $str, $wc ) {
        my $width = 0;
        for my $char ( split //, $str ) {
            my $o = ord($char);
            next if $o < 0x20;
            if ( $wc && $o >= 0x1F1E6 && $o <= 0x1F1FF ) {
                $width++;
                next;
            }
            my $w = _char_width($o);
            if ( $wc && $o >= 0xFF9E && $o <= 0xFF9F ) { $w = 1 }
            $width += $w;
        }
        return $width;
    }

    sub string_width ($str) {
        my $s = strip_ansi($str);
        return 0 unless length $s;
        return _calc_width_grapheme($s);
    }

    sub string_width_wc ($str) {
        my $s = strip_ansi($str);
        return 0 unless length $s;
        return _calc_width( $s, 1 );
    }

    sub go_duration ($sec) {
        my $neg = $sec < 0;
        my $u   = int( abs($sec) * 1_000_000_000 + 0.5 );
        if ( $u < 1_000_000_000 ) {
            if ( $u == 0 ) {
                return '0s';
            }
            my ( $unit, $prec );
            if ( $u < 1_000 ) {
                $prec = 0;
                $unit = 'n';
            }
            elsif ( $u < 1_000_000 ) {
                $prec = 3;
                $unit = "\x{00B5}";
            }
            else {
                $prec = 6;
                $unit = 'm';
            }
            my ( $frac, $v ) = _go_fmt_frac( $u, $prec );
            my $out = _go_fmt_int($v) . $frac . $unit . 's';
            return $neg ? "-$out" : $out;
        }
        my ( $frac, $v ) = _go_fmt_frac( $u, 9 );
        my $out = _go_fmt_int( $v % 60 ) . $frac . 's';
        $v = int( $v / 60 );
        if ( $v > 0 ) {
            $out = _go_fmt_int( $v % 60 ) . 'm' . $out;
            $v   = int( $v / 60 );
            if ( $v > 0 ) {
                $out = _go_fmt_int($v) . 'h' . $out;
            }
        }
        return $neg ? "-$out" : $out;
    }

    sub _go_fmt_frac ( $v, $prec ) {
        my $print = 0;
        my $frac  = '';
        for ( 1 .. $prec ) {
            my $digit = $v % 10;
            $print ||= $digit != 0;
            $frac = $digit . $frac if $print;
            $v    = int( $v / 10 );
        }
        $frac = '.' . $frac if $print;
        return ( $frac, $v );
    }

    sub _go_fmt_int ($v) {
        $v = int($v);
        return '0' if $v == 0;
        my $out = '';
        while ( $v > 0 ) {
            $out = ( $v % 10 ) . $out;
            $v   = int( $v / 10 );
        }
        return $out;
    }

    sub truncate ( $str, $width, $tail = '' ) {
        return '' unless defined $str;
        return '' if $width <= 0 && length $tail == 0;
        my $sw = string_width($str);
        return $str if $sw <= $width;
        my $tail_w = string_width($tail);
        return $str if $width < $tail_w;
        my $avail    = $width - $tail_w;
        my $result   = '';
        my $cw       = 0;
        my $ignoring = 0;
        my $state    = 0;

        # \X iterates whole extended grapheme clusters so combining marks,
        # ZWJ emoji sequences, etc. are never torn apart. ANSI escape bytes are
        # pure ASCII, so each still arrives as its own cluster for the state
        # machine below.
        while ( $str =~ /(\X)/gc ) {
            my $ch = $1;
            if ( $state == 3 ) {
                $result .= $ch;
                if    ( $ch eq "\a" ) { $state = 0; }
                elsif ( $ch eq "\e" ) { $state = 1; }
                next;
            }
            if ( $state == 2 ) {
                $result .= $ch;
                $state = 0 if $ch =~ /^[a-zA-Z~]$/;
                next;
            }
            if ( $state == 1 ) {
                $result .= $ch;
                if    ( $ch eq '[' ) { $state = 2; }
                elsif ( $ch eq ']' ) { $state = 3; }
                else                 { $state = 0; }
                next;
            }
            if ( $ch eq "\e" ) {
                $result .= $ch;
                $state = 1;
                next;
            }
            if ( $ch eq "\n" ) {
                $result .= "\n" unless $ignoring;
                next;
            }
            if ( $ch eq "\t" ) {
                $result .= "\t" unless $ignoring;
                next;
            }
            if ($ignoring) {
                next;
            }
            my $w = _cluster_width($ch);
            if ( $cw + $w > $avail ) {
                $ignoring = 1;
                $result .= $tail;
                next;
            }
            $result .= $ch;
            $cw += $w;
        }
        return $result;
    }

    sub truncate_left ( $str, $width, $tail = '' ) {
        return '' unless defined $str;
        return $str if $width <= 0;
        my $result   = '';
        my $cw       = 0;
        my $ignoring = 1;
        my $state    = 0;

        # \X iterates whole extended grapheme clusters; see truncate().
        while ( $str =~ /(\X)/gc ) {
            my $ch       = $1;
            my $tok_from = pos($str) - length($ch);
            if ( $state == 3 ) {
                $result .= $ch;
                if    ( $ch eq "\a" ) { $state = 0; }
                elsif ( $ch eq "\e" ) { $state = 1; }
                next;
            }
            if ( $state == 2 ) {
                $result .= $ch;
                $state = 0 if $ch =~ /^[a-zA-Z~]$/;
                next;
            }
            if ( $state == 1 ) {
                $result .= $ch;
                if    ( $ch eq '[' ) { $state = 2; }
                elsif ( $ch eq ']' ) { $state = 3; }
                else                 { $state = 0; }
                next;
            }
            if ( $ch eq "\e" ) {
                $result .= $ch;
                $state = 1;
                next;
            }
            if ( !$ignoring ) {
                $result .= substr( $str, $tok_from );
                last;
            }
            if ( $ch eq "\n" ) {
                next;
            }
            if ( $ch eq "\t" ) {
                next;
            }
            my $w = _cluster_width($ch);
            $cw += $w;
            if ( $cw > $width ) {
                $ignoring = 0;
                $result .= $tail . $ch;
            }
        }
        return $result;
    }

    sub cut ( $str, $left, $right ) {
        return '' unless defined $str;
        return '' if $right <= $left;
        my $t = Cancer::Util::truncate( $str, $right, '' );
        return truncate_left( $t, $left, '' );
    }

    sub byte_to_grapheme_range ( $str, $byte_start, $byte_end ) {
        $byte_start = 0                                      if $byte_start < 0;
        $byte_end   = length Encode::encode( 'UTF-8', $str ) if $byte_end > length $str;
        return ( 0, 0 ) if $byte_start >= $byte_end;
        my $b_pos   = 0;
        my $gpos    = 0;
        my $g_start = 0;
        my $g_stop  = 0;
        my $found   = 0;

        # \X iterates whole extended grapheme clusters, so the returned range
        # indexes real graphemes rather than raw code points.
        while ( $str =~ /(\X)/gc ) {
            my $ch   = $1;
            my $blen = length( Encode::encode( 'UTF-8', $ch ) );
            if ( $b_pos + $blen > $byte_start && !$found ) {
                $g_start = $gpos;
                $found   = 1;
            }
            $b_pos += $blen;
            if ( $found && $b_pos > $byte_end ) {
                last;
            }
            $gpos++;
        }
        if ($found) {
            $g_stop = $gpos;
        }
        elsif ( $b_pos >= $byte_end ) {
            $g_stop = $gpos;
        }
        return ( $g_start, $g_stop );
    }

    sub _is_ws ($ch) {
        my $o = ord($ch);
        return 1 if $o == 0x20 || $o == 0x09 || $o == 0x0A || $o == 0x0D || $o == 0x0B || $o == 0x0C;
        return 1 if $o == 0xA0;
        return 1 if $o >= 0x1680 && $o <= 0x180E;
        return 1 if $o >= 0x2000 && $o <= 0x200A;
        return 1 if $o == 0x2028 || $o == 0x2029 || $o == 0x202F || $o == 0x205F || $o == 0x3000;
        return 0;
    }

    sub hardwrap ( $str, $limit, $preserve_space = 0 ) {
        return $str if $limit <= 0;
        my $result        = '';
        my $line          = '';
        my $width         = 0;
        my $state         = 0;
        my $force_newline = 0;

        # \X iterates whole extended grapheme clusters; see truncate().
        while ( $str =~ /(\X)/gc ) {
            my $ch = $1;
            if ( $state == 3 ) {
                $line .= $ch;
                if    ( $ch eq "\a" ) { $state = 0; }
                elsif ( $ch eq "\e" ) { $state = 1; }
                next;
            }
            if ( $state == 2 ) {
                $line .= $ch;
                $state = 0 if $ch =~ /^[a-zA-Z~]$/;
                next;
            }
            if ( $state == 1 ) {
                $line .= $ch;
                if    ( $ch eq '[' ) { $state = 2; }
                elsif ( $ch eq ']' ) { $state = 3; }
                else                 { $state = 0; }
                next;
            }
            if ( $ch eq "\e" ) {
                $line .= $ch;
                $state = 1;
                next;
            }
            if ( $ch eq "\n" or $ch eq "\r\n" ) {
                $result .= $line . $ch;
                $line          = '';
                $width         = 0;
                $force_newline = 0;
                next;
            }
            my $o = ord($ch);
            if ( $o < 0x80 ) {
                if ( $width + 1 > $limit ) {
                    $result .= $line . "\n";
                    $line          = '';
                    $width         = 0;
                    $force_newline = 1;
                }
                if ( !$preserve_space && $width == 0 && $force_newline && _is_ws($ch) ) {
                    next;
                }
                $force_newline = 0 if $width == 0;
                $line .= $ch;
                $width++ if $o >= 0x20;
            }
            else {
                my $w = _cluster_width($ch);
                if ( $width + $w > $limit ) {
                    $result .= $line . "\n";
                    $line  = '';
                    $width = 0;
                }
                next if !$preserve_space && $width == 0 && _is_ws($ch);
                $line .= $ch;
                $width += $w;
            }
        }
        $result .= $line if length $line;
        return $result;
    }

    sub wordwrap ( $str, $limit, $break_points = '' ) {
        return $str if $limit <= 0;
        my $result     = '';
        my $line_width = 0;
        my $word       = '';
        my $word_width = 0;
        my $space      = '';
        my $sp_width   = 0;
        my $state      = 0;

        # \X iterates whole extended grapheme clusters; see truncate().
        while ( $str =~ /(\X)/gc ) {
            my $ch = $1;
            if ( $state == 3 ) {
                $word .= $ch;
                if    ( $ch eq "\a" ) { $state = 0; }
                elsif ( $ch eq "\e" ) { $state = 1; }
                next;
            }
            if ( $state == 2 ) {
                $word .= $ch;
                $state = 0 if $ch =~ /^[a-zA-Z~]$/;
                next;
            }
            if ( $state == 1 ) {
                $word .= $ch;
                if    ( $ch eq '[' ) { $state = 2; }
                elsif ( $ch eq ']' ) { $state = 3; }
                else                 { $state = 0; }
                next;
            }
            if ( $ch eq "\e" ) {
                $word .= $ch;
                $state = 1;
                next;
            }
            if ( $ch eq "\n" or $ch eq "\r\n" ) {
                if ( $word_width == 0 ) {
                    if ( $line_width + $sp_width > $limit ) {
                        $line_width = 0;
                    }
                    else {
                        $result .= $space;
                    }
                    $space    = '';
                    $sp_width = 0;
                }
                $result .= $word . $ch;
                $word       = '';
                $word_width = 0;
                $space      = '';
                $sp_width   = 0;
                $line_width = 0;
                next;
            }
            my $w = _cluster_width($ch);
            if ( _is_ws($ch) && $w > 0 ) {
                if ( $word_width > 0 ) {
                    $line_width += $sp_width;
                    $result .= $space;
                    $space    = '';
                    $sp_width = 0;
                    $line_width += $word_width;
                    $result .= $word;
                    $word       = '';
                    $word_width = 0;
                }
                $space .= $ch;
                $sp_width += $w;
                next;
            }
            if ( $ch eq '-' || ( length $break_points && index( $break_points, $ch ) >= 0 ) ) {
                $line_width += $sp_width;
                $result .= $space;
                $space    = '';
                $sp_width = 0;
                $line_width += $word_width;
                $result .= $word;
                $word       = '';
                $word_width = 0;
                $result .= $ch;
                $line_width += $w;
                next;
            }
            $word .= $ch;
            $word_width += $w;
            if ( $line_width + $sp_width + $word_width > $limit && $word_width > 0 && $word_width < $limit ) {
                $result .= "\n";
                $line_width = 0;
                $space      = '';
                $sp_width   = 0;
            }
        }
        if ( $word_width > 0 ) {
            $line_width += $sp_width;
            $result .= $space;
            $line_width += $word_width;
            $result .= $word;
        }
        return $result;
    }

    sub wrap ( $str, $width, $break_points = '' ) {
        return $str if $width <= 0;
        my $result     = '';
        my $line_width = 0;
        my $word       = '';
        my $word_width = 0;
        my $space      = '';
        my $sp_width   = 0;
        my $state      = 0;

        # \X iterates whole extended grapheme clusters; see truncate().
        while ( $str =~ /(\X)/gc ) {
            my $ch = $1;
            if ( $state == 3 ) {
                $word .= $ch;
                if    ( $ch eq "\a" ) { $state = 0; }
                elsif ( $ch eq "\e" ) { $state = 1; }
                next;
            }
            if ( $state == 2 ) {
                $word .= $ch;
                $state = 0 if $ch =~ /^[a-zA-Z~]$/;
                next;
            }
            if ( $state == 1 ) {
                $word .= $ch;
                if    ( $ch eq '[' ) { $state = 2; }
                elsif ( $ch eq ']' ) { $state = 3; }
                else                 { $state = 0; }
                next;
            }
            if ( $ch eq "\e" ) {
                $word .= $ch;
                $state = 1;
                next;
            }
            if ( $ch eq "\n" or $ch eq "\r\n" ) {
                if ( $word_width == 0 ) {
                    if ( $line_width + $sp_width > $width ) {
                        $line_width = 0;
                    }
                    else {
                        $result .= $space;
                    }
                    $space    = '';
                    $sp_width = 0;
                }
                $result .= $word . "\n";
                $word       = '';
                $word_width = 0;
                $space      = '';
                $sp_width   = 0;
                $line_width = 0;
                next;
            }
            my $w = _cluster_width($ch);
            if ( _is_ws($ch) ) {
                if ( $word_width > 0 ) {
                    $line_width += $sp_width;
                    $result .= $space;
                    $space    = '';
                    $sp_width = 0;
                    $line_width += $word_width;
                    $result .= $word;
                    $word       = '';
                    $word_width = 0;
                }
                $space .= $ch;
                $sp_width += $w;
                next;
            }
            if ( $ch eq '-' || ( length $break_points && index( $break_points, $ch ) >= 0 ) ) {
                if ( $line_width + $word_width >= $width ) {
                    $word .= $ch;
                    $word_width += $w;
                }
                else {
                    $line_width += $sp_width;
                    $result .= $space;
                    $space    = '';
                    $sp_width = 0;
                    $line_width += $word_width;
                    $result .= $word;
                    $word       = '';
                    $word_width = 0;
                    $result .= $ch;
                    $line_width += $w;
                }
                next;
            }
            if ( $line_width == $width ) {
                $result .= "\n";
                $line_width = 0;
                $space      = '';
                $sp_width   = 0;
            }
            if ( $word_width + $w > $width && $word_width > 0 ) {
                $line_width += $sp_width;
                $result .= $space;
                $space    = '';
                $sp_width = 0;
                $line_width += $word_width;
                $result .= $word;
                $word       = '';
                $word_width = 0;
            }
            $word .= $ch;
            $word_width += $w;
            if ( $line_width + $word_width + $sp_width > $width ) {
                $result .= "\n";
                $line_width = 0;
                $space      = '';
                $sp_width   = 0;
            }
            if ( $word_width == $width && $word_width > 0 ) {
                $line_width += $sp_width;
                $result .= $space;
                $space    = '';
                $sp_width = 0;
                $line_width += $word_width;
                $result .= $word;
                $word       = '';
                $word_width = 0;
            }
        }
        if ( $word_width > 0 || length $word ) {
            $line_width += $sp_width;
            $result .= $space;
            $line_width += $word_width;
            $result .= $word;
        }
        elsif ( $line_width + $sp_width > $width ) {
            $line_width = 0;
        }
        else {
            $result .= $space;
        }
        $space      = '';
        $sp_width   = 0;
        $word       = '';
        $word_width = 0;
        return $result;
    }
};
#
1;
