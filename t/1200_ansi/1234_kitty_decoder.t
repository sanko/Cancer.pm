use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Compress::Zlib qw[compress crc32];
use blib;
use Cancer::Ansi::Kitty qw[RGBA RGB PNG Zlib];
use Cancer::Ansi::Kitty::Decoder;

# Ported from charmbracelet/x/ansi/kitty/decoder_test.go
# Tests Kitty Graphics Protocol image decoding.
sub make_image ( $w, $h, $pixels ) {
    return { width => $w, height => $h, pixels => $pixels };
}

sub _png_chunk ( $type, $data ) {
    my $crc = crc32( $type . $data );
    return pack( 'N', length($data) ) . $type . $data . pack( 'N', $crc );
}

sub _make_test_png ( $pixels, $width, $height ) {
    my $sig       = "\x89PNG\r\n\x1a\n";
    my $ihdr_data = pack 'NNCCCCC', $width, $height, 8, 6, 0, 0, 0;
    my $ihdr      = _png_chunk( 'IHDR', $ihdr_data );
    my $raw       = '';
    for my $y ( 0 .. $height - 1 ) {
        $raw .= "\x00";
        for my $x ( 0 .. $width - 1 ) {
            my $off = ( $y * $width + $x ) * 4;
            $raw .= substr $pixels, $off, 4;
        }
    }
    my $compressed = compress($raw);
    my $idat       = _png_chunk( 'IDAT', $compressed );
    my $iend       = _png_chunk( 'IEND', '' );
    return $sig . $ihdr . $idat . $iend;
}
subtest 'Decoder->Decode' => sub {
    my $red      = "\xFF\x00\x00\xFF";
    my $blue     = "\x00\x00\xFF\xFF";
    my $rgba2x2  = $red . $blue . $blue . $red;
    my $rgb2x2   = "\xFF\x00\x00\x00\x00\xFF\x00\x00\xFF\xFF\x00\x00";
    my $test_png = _make_test_png( $red, 1, 1 );
    my @tests    = (
        {   name     => 'RGBA format 2x2',
            decoder  => { format => RGBA, width => 2, height => 2 },
            input    => $rgba2x2,
            want     => make_image( 2, 2, $rgba2x2 ),
            want_err => 0
        },
        {   name     => 'RGB format 2x2',
            decoder  => { format => RGB, width => 2, height => 2 },
            input    => $rgb2x2,
            want     => make_image( 2, 2, $rgba2x2 ),
            want_err => 0
        },
        {   name     => 'RGBA with compression',
            decoder  => { format => RGBA, width => 2, height => 2, decompress => 1 },
            input    => compress($rgba2x2),
            want     => make_image( 2, 2, $rgba2x2 ),
            want_err => 0
        },
        { name => 'PNG format',     decoder => { format => PNG }, input => $test_png, want => make_image( 1, 1, $red ),            want_err => 0 },
        { name => 'invalid format', decoder => { format => 999, width => 2, height => 2 }, input => "\x00\x00\x00", want => undef, want_err => 1 },
        {   name     => 'incomplete RGBA data',
            decoder  => { format => RGBA, width => 2, height => 2 },
            input    => "\xFF\x00\x00",
            want     => undef,
            want_err => 1
        },
        {   name     => 'invalid compressed data',
            decoder  => { format => RGBA, width => 2, height => 2, decompress => 1 },
            input    => "\x01\x02\x03",
            want     => undef,
            want_err => 1
        },
        {   name     => 'default format (RGBA)',
            decoder  => { format => 0, width => 1, height => 1 },
            input    => $red,
            want     => make_image( 1, 1, $red ),
            want_err => 0
        }
    );
    for my $tc (@tests) {
        my $d = Cancer::Ansi::Kitty::Decoder->new(
            decompress => $tc->{decoder}{decompress} // 0,
            format     => $tc->{decoder}{format},
            width      => $tc->{decoder}{width}  // 0,
            height     => $tc->{decoder}{height} // 0,
        );
        my $got;
        my $err;
        eval { $got = $d->decode( $tc->{input} ) };
        $err = $@;
        my $has_err = defined $err && length $err > 0;
        ok $has_err == $tc->{want_err}, $tc->{name} . ' error flag';
        next if $tc->{want_err};

        if ( defined $got && defined $tc->{want} ) {
            is $got->{width},  $tc->{want}{width},  $tc->{name} . ' width';
            is $got->{height}, $tc->{want}{height}, $tc->{name} . ' height';
            is $got->{pixels}, $tc->{want}{pixels}, $tc->{name} . ' pixels';
        }
        else {
            ok !defined $got && !defined $tc->{want}, $tc->{name} . ' nil result';
        }
    }
};
subtest 'Decoder edge cases' => sub {
    my @tests = (
        { name => 'zero dimensions', decoder => { format => RGBA, width =>  0, height => 0 }, input => '',                 want_err => 0 },
        { name => 'negative width',  decoder => { format => RGBA, width => -1, height => 1 }, input => "\xFF\x00\x00\xFF", want_err => 0 },
        {   name     => 'very large dimensions',
            decoder  => { format => RGBA, width => 1, height => 1_000_000 },
            input    => "\xFF\x00\x00\xFF",
            want_err => 1
        }
    );
    for my $tc (@tests) {
        my $d = Cancer::Ansi::Kitty::Decoder->new(
            decompress => 0,
            format     => $tc->{decoder}{format},
            width      => $tc->{decoder}{width},
            height     => $tc->{decoder}{height}
        );
        my ( $got, $err );
        eval { $got = $d->decode( $tc->{input} ) };
        $err = $@;
        my $has_err = defined $err && length $err > 0;
        ok $has_err == $tc->{want_err}, $tc->{name} . ' error flag';
    }
};
#
done_testing;
