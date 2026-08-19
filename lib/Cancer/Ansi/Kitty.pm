package Cancer::Ansi::Kitty v0.0.1 {
    use v5.42;
    use Exporter 'import';
    our @EXPORT_OK = qw[
        MaxChunkSize Placeholder
        RGBA RGB PNG
        Zlib
        Direct File TempFile SharedMemory
        Transmit TransmitAndPut Query Put Delete Frame Animate Compose
        DeleteAll DeleteID DeleteNumber DeleteCursor DeleteFrames
        DeleteCell DeleteCellZ DeleteRange DeleteColumn DeleteRow DeleteZ
        Diacritic diacritics
        KittyKeyboard PushKittyKeyboard PopKittyKeyboard
        KittyDisambiguateEscapeCodes KittyReportEventTypes
        KittyReportAlternateKeys KittyReportAllKeysAsEscapeCodes
        KittyReportAssociatedKeys KittyAllFlags
        RequestKittyKeyboard DisableKittyKeyboard
    ];
    use constant {
        MaxChunkSize   => 4096,
        Placeholder    => "\x{10EEEE}",
        RGBA           => 32,
        RGB            => 24,
        PNG            => 100,
        Zlib           => 'z',
        Direct         => 'd',
        File           => 'f',
        TempFile       => 't',
        SharedMemory   => 's',
        Transmit       => 't',
        TransmitAndPut => 'T',
        Query          => 'q',
        Put            => 'p',
        Delete         => 'd',
        Frame          => 'f',
        Animate        => 'a',
        Compose        => 'c',
        DeleteAll      => 'a',
        DeleteID       => 'i',
        DeleteNumber   => 'n',
        DeleteCursor   => 'c',
        DeleteFrames   => 'f',
        DeleteCell     => 'p',
        DeleteCellZ    => 'q',
        DeleteRange    => 'r',
        DeleteColumn   => 'x',
        DeleteRow      => 'y',
        DeleteZ        => 'z'
    };
    our @diacritics = (
        "\x{0305}",  "\x{030D}",  "\x{030E}",  "\x{0310}",  "\x{0312}",  "\x{033D}",  "\x{033E}",  "\x{033F}",  "\x{0346}",  "\x{034A}",
        "\x{034B}",  "\x{034C}",  "\x{0350}",  "\x{0351}",  "\x{0352}",  "\x{0357}",  "\x{035B}",  "\x{0363}",  "\x{0364}",  "\x{0365}",
        "\x{0366}",  "\x{0367}",  "\x{0368}",  "\x{0369}",  "\x{036A}",  "\x{036B}",  "\x{036C}",  "\x{036D}",  "\x{036E}",  "\x{036F}",
        "\x{0483}",  "\x{0484}",  "\x{0485}",  "\x{0486}",  "\x{0487}",  "\x{0592}",  "\x{0593}",  "\x{0594}",  "\x{0595}",  "\x{0597}",
        "\x{0598}",  "\x{0599}",  "\x{059C}",  "\x{059D}",  "\x{059E}",  "\x{059F}",  "\x{05A0}",  "\x{05A1}",  "\x{05A8}",  "\x{05A9}",
        "\x{05AB}",  "\x{05AC}",  "\x{05AF}",  "\x{05C4}",  "\x{0610}",  "\x{0611}",  "\x{0612}",  "\x{0613}",  "\x{0614}",  "\x{0615}",
        "\x{0616}",  "\x{0617}",  "\x{0657}",  "\x{0658}",  "\x{0659}",  "\x{065A}",  "\x{065B}",  "\x{065D}",  "\x{065E}",  "\x{06D6}",
        "\x{06D7}",  "\x{06D8}",  "\x{06D9}",  "\x{06DA}",  "\x{06DB}",  "\x{06DC}",  "\x{06DF}",  "\x{06E0}",  "\x{06E1}",  "\x{06E2}",
        "\x{06E4}",  "\x{06E7}",  "\x{06E8}",  "\x{06EB}",  "\x{06EC}",  "\x{0730}",  "\x{0732}",  "\x{0733}",  "\x{0735}",  "\x{0736}",
        "\x{073A}",  "\x{073D}",  "\x{073F}",  "\x{0740}",  "\x{0741}",  "\x{0743}",  "\x{0745}",  "\x{0747}",  "\x{0749}",  "\x{074A}",
        "\x{07EB}",  "\x{07EC}",  "\x{07ED}",  "\x{07EE}",  "\x{07EF}",  "\x{07F0}",  "\x{07F1}",  "\x{07F3}",  "\x{0816}",  "\x{0817}",
        "\x{0818}",  "\x{0819}",  "\x{081B}",  "\x{081C}",  "\x{081D}",  "\x{081E}",  "\x{081F}",  "\x{0820}",  "\x{0821}",  "\x{0822}",
        "\x{0823}",  "\x{0825}",  "\x{0826}",  "\x{0827}",  "\x{0829}",  "\x{082A}",  "\x{082B}",  "\x{082C}",  "\x{082D}",  "\x{0951}",
        "\x{0953}",  "\x{0954}",  "\x{0F82}",  "\x{0F83}",  "\x{0F86}",  "\x{0F87}",  "\x{135D}",  "\x{135E}",  "\x{135F}",  "\x{17DD}",
        "\x{193A}",  "\x{1A17}",  "\x{1A75}",  "\x{1A76}",  "\x{1A77}",  "\x{1A78}",  "\x{1A79}",  "\x{1A7A}",  "\x{1A7B}",  "\x{1A7C}",
        "\x{1B6B}",  "\x{1B6D}",  "\x{1B6E}",  "\x{1B6F}",  "\x{1B70}",  "\x{1B71}",  "\x{1B72}",  "\x{1B73}",  "\x{1CD0}",  "\x{1CD1}",
        "\x{1CD2}",  "\x{1CDA}",  "\x{1CDB}",  "\x{1CE0}",  "\x{1DC0}",  "\x{1DC1}",  "\x{1DC3}",  "\x{1DC4}",  "\x{1DC5}",  "\x{1DC6}",
        "\x{1DC7}",  "\x{1DC8}",  "\x{1DC9}",  "\x{1DCB}",  "\x{1DCC}",  "\x{1DD1}",  "\x{1DD2}",  "\x{1DD3}",  "\x{1DD4}",  "\x{1DD5}",
        "\x{1DD6}",  "\x{1DD7}",  "\x{1DD8}",  "\x{1DD9}",  "\x{1DDA}",  "\x{1DDB}",  "\x{1DDC}",  "\x{1DDD}",  "\x{1DDE}",  "\x{1DDF}",
        "\x{1DE0}",  "\x{1DE1}",  "\x{1DE2}",  "\x{1DE3}",  "\x{1DE4}",  "\x{1DE5}",  "\x{1DE6}",  "\x{1DFE}",  "\x{20D0}",  "\x{20D1}",
        "\x{20D4}",  "\x{20D5}",  "\x{20D6}",  "\x{20D7}",  "\x{20DB}",  "\x{20DC}",  "\x{20E1}",  "\x{20E7}",  "\x{20E9}",  "\x{20F0}",
        "\x{2CEF}",  "\x{2CF0}",  "\x{2CF1}",  "\x{2DE0}",  "\x{2DE1}",  "\x{2DE2}",  "\x{2DE3}",  "\x{2DE4}",  "\x{2DE5}",  "\x{2DE6}",
        "\x{2DE7}",  "\x{2DE8}",  "\x{2DE9}",  "\x{2DEA}",  "\x{2DEB}",  "\x{2DEC}",  "\x{2DED}",  "\x{2DEE}",  "\x{2DEF}",  "\x{2DF0}",
        "\x{2DF1}",  "\x{2DF2}",  "\x{2DF3}",  "\x{2DF4}",  "\x{2DF5}",  "\x{2DF6}",  "\x{2DF7}",  "\x{2DF8}",  "\x{2DF9}",  "\x{2DFA}",
        "\x{2DFB}",  "\x{2DFC}",  "\x{2DFD}",  "\x{2DFE}",  "\x{2DFF}",  "\x{A66F}",  "\x{A67C}",  "\x{A67D}",  "\x{A6F0}",  "\x{A6F1}",
        "\x{A8E0}",  "\x{A8E1}",  "\x{A8E2}",  "\x{A8E3}",  "\x{A8E4}",  "\x{A8E5}",  "\x{A8E6}",  "\x{A8E7}",  "\x{A8E8}",  "\x{A8E9}",
        "\x{A8EA}",  "\x{A8EB}",  "\x{A8EC}",  "\x{A8ED}",  "\x{A8EE}",  "\x{A8EF}",  "\x{A8F0}",  "\x{A8F1}",  "\x{AAB0}",  "\x{AAB2}",
        "\x{AAB3}",  "\x{AAB7}",  "\x{AAB8}",  "\x{AABE}",  "\x{AABF}",  "\x{AAC1}",  "\x{FE20}",  "\x{FE21}",  "\x{FE22}",  "\x{FE23}",
        "\x{FE24}",  "\x{FE25}",  "\x{FE26}",  "\x{10A0F}", "\x{10A38}", "\x{1D185}", "\x{1D186}", "\x{1D187}", "\x{1D188}", "\x{1D189}",
        "\x{1D1AA}", "\x{1D1AB}", "\x{1D1AC}", "\x{1D1AD}", "\x{1D242}", "\x{1D243}", "\x{1D244}"
    );

    sub Diacritic ($i) {
        return $diacritics[0] if $i < 0 || $i >= @diacritics;
        return $diacritics[$i];
    }

    # Kitty Keyboard Protocol
    use constant {
        KittyDisambiguateEscapeCodes    => 1,
        KittyReportEventTypes           => 2,
        KittyReportAlternateKeys        => 4,
        KittyReportAllKeysAsEscapeCodes => 8,
        KittyReportAssociatedKeys       => 16,
        KittyAllFlags                   => 1 | 2 | 4 | 8 | 16,
        RequestKittyKeyboard            => "\e[?u",
        DisableKittyKeyboard            => "\e[>u"
    };
    sub KittyKeyboard ( $flags, $mode ) {"\e[=${flags};${mode}u"}

    sub PushKittyKeyboard ( $flags = 0 ) {
        $flags > 0 ? "\e[>${flags}u" : "\e[>u";
    }

    sub PopKittyKeyboard ( $n = 0 ) {
        $n > 0 ? "\e[<${n}u" : "\e[<u";
    }
};
#
1;
