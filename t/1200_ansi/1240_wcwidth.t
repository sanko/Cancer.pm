use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Util qw[string_width string_width_wc];
#
subtest 'cluster width' => sub {    # maps Go TestWcClusterWidth
    my @cases = (
        [ ascii               => 'a',                                                            1, 1 ], [ combining_acute => "\x{00e9}", 1, 1 ],  # é
        [ devanagari_conjunct => "\x{0938}\x{094d}\x{0924}\x{0947}",                             2, 1 ],    # स्ते
        [ devanagari_kssa     => "\x{0915}\x{094d}\x{0937}",                                     2, 1 ],    # क्ष
        [ cjk                 => "\x{4e16}",                                                     2, 2 ],    # 世
        [ emoji               => "\x{1f308}",                                                    2, 2 ],    # 🌈
        [ vs16                => "\x{26a0}\x{fe0f}",                                             1, 2 ],    # ⚠️
        [ vs15                => "\x{2639}\x{fe0e}",                                             1, 1 ],    # ☹︎
        [ keycap              => "1\x{fe0f}\x{20e3}",                                            1, 2 ],    # 1️⃣
        [ zwj_pair            => "\x{1f468}\x{200d}\x{1f4bb}",                                   4, 2 ],    # 👨‍💻
        [ zwj_family          => "\x{1f468}\x{200d}\x{1f469}\x{200d}\x{1f467}\x{200d}\x{1f466}", 8, 2 ],
        [ zwj_flag            => "\x{1f3f3}\x{fe0f}\x{200d}\x{1f308}", 3, 2 ], [ skin_tone             => "\x{1f449}\x{1f3fd}", 4, 2 ],
        [ regional_indicators => "\x{1f1fa}\x{1f1f8}",                 2, 2 ], [ halfwidth_voiced_mark => "\x{FF73}\x{FF9E}",   2, 1 ],    # ｶﾞ

        # C1 string: Go expects 1 (rune-level), Perl's string_width_wc strips C1 CSI via strip_ansi
        [ c1_string => "\x{9b}x", 0, 0 ]
    );
    for my $tc (@cases) {
        my ( $name, $in, $wc_want, $grapheme_want ) = @$tc;
        is string_width_wc($in), $wc_want,       "$name: string_width_wc";
        is string_width($in),    $grapheme_want, "$name: string_width";
    }
};
subtest 'TestWcRuneWidth' => sub {    # maps Go TestWcRuneWidth
    my @cases = (
        [ nul                           => 0,        0 ],
        [ bell                          => 0x07,     0 ],
        [ del                           => 0x7f,     0 ],
        [ c1_pad                        => 0x80,     0 ],
        [ c1_csi                        => 0x9b,     0 ],
        [ c1_apc                        => 0x9f,     0 ],
        [ ascii_a                       => ord('a'), 1 ],
        [ latin1_e_acute                => 0xe9,     1 ],
        [ combining_acute               => 0x301,    0 ],
        [ devanagari_virama             => 0x94d,    0 ],
        [ devanagari_vowel_sign         => 0x947,    0 ],
        [ hebrew_point                  => 0x5b0,    0 ],
        [ arabic_fatha                  => 0x64e,    0 ],
        [ thai_vowel                    => 0xe34,    0 ],
        [ zwj                           => 0x200d,   0 ],
        [ vs15                          => 0xfe0e,   0 ],
        [ vs16                          => 0xfe0f,   0 ],
        [ enclosing_keycap              => 0x20e3,   0 ],
        [ cjk                           => 0x4e16,   2 ],
        [ hangul                        => 0xd55c,   2 ],
        [ halfwidth_katakana            => 0xff76,   1 ],
        [ emoji                         => 0x1f308,  2 ],
        [ skin_tone_modifier            => 0x1f3fd,  2 ],
        [ regional_indicator            => 0x1f1fa,  1 ],
        [ musical_symbol_mark           => 0x1d167,  0 ],
        [ variation_selector_supplement => 0xe0100,  0 ],
        [ tag_character                 => 0xe0041,  0 ]
    );
    for my $tc (@cases) {
        my ( $name, $cp, $want ) = @$tc;
        my $ch = chr($cp);
        is string_width_wc($ch), $want, "$name: string_width_wc(U+ sprintf('%04X', $cp))";
    }
};
subtest 'halfwidth_voiced_mark_cluster' => sub {    # ｶﾞ (2 codepoints, wc=2, grapheme=1)
    my $s = "\x{FF73}\x{FF9E}";
    is string_width_wc($s), 2, 'string_width_wc for halfwidth voiced mark cluster';
    is string_width($s),    1, 'string_width for halfwidth voiced mark cluster';
};
#
done_testing;
