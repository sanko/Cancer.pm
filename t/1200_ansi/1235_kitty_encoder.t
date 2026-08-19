use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Compress::Zlib qw[uncompress];
use blib;
use Cancer::Ansi::Kitty qw[RGBA RGB PNG];
use Cancer::Ansi::Kitty::Encoder;

# Ported from charmbracelet/x/ansi/kitty/encoder_test.go
# Tests Kitty Graphics Protocol image encoding.
use constant PNG_HEADER => "\x89PNG\r\n\x1a\n";

sub test_image () {
    my $red  = "\xFF\x00\x00\xFF";
    my $blue = "\x00\x00\xFF\xFF";
    return $red . $blue . $blue . $red;
}
subtest 'Encoder->Encode' => sub {
    my $img   = test_image();
    my @tests = (
        {   name     => 'nil image',
            encoder  => { format => RGBA },
            img      => '',
            width    => 0,
            height   => 0,
            want_err => 0,
            verify   => sub ($got) {
                is length($got), 0, 'nil image: empty output';
            }
        },
        {   name     => 'RGBA format',
            encoder  => { format => RGBA },
            img      => $img,
            width    => 2,
            height   => 2,
            want_err => 0,
            verify   => sub ($got) {
                my $expected = $img;
                is $got, $expected, 'RGBA output matches';
            }
        },
        {   name     => 'RGB format',
            encoder  => { format => RGB },
            img      => $img,
            width    => 2,
            height   => 2,
            want_err => 0,
            verify   => sub ($got) {
                my $expected = "\xFF\x00\x00\x00\x00\xFF\x00\x00\xFF\xFF\x00\x00";
                is $got, $expected, 'RGB output matches';
            }
        },
        {   name     => 'PNG format',
            encoder  => { format => PNG },
            img      => $img,
            width    => 2,
            height   => 2,
            want_err => 0,
            verify   => sub ($got) {
                ok length($got) >= 8, 'PNG output has minimum length';
                is substr( $got, 0, 8 ), PNG_HEADER, 'PNG header matches';
            }
        },
        { name => 'invalid format', encoder => { format => 999 }, img => $img, width => 2, height => 2, want_err => 1, verify => undef },
        {   name     => 'RGBA with compression',
            encoder  => { format => RGBA, compress => 1 },
            img      => $img,
            width    => 2,
            height   => 2,
            want_err => 0,
            verify   => sub ($got) {
                my $decompressed = uncompress($got);
                ok defined $decompressed, 'compressed data decompresses successfully';
                my $expected = $img;
                is $decompressed, $expected, 'decompressed output matches';
            }
        },
        {   name     => 'zero format defaults to RGBA',
            encoder  => { format => 0 },
            img      => $img,
            width    => 2,
            height   => 2,
            want_err => 0,
            verify   => sub ($got) {
                my $expected = $img;
                is $got, $expected, 'default format RGBA output matches';
            }
        }
    );
    for my $tc (@tests) {
        my $e = Cancer::Ansi::Kitty::Encoder->new( compress => $tc->{encoder}{compress} // 0, format => $tc->{encoder}{format} );
        my ( $got, $err );
        eval { $got = $e->encode( $tc->{img}, $tc->{width}, $tc->{height} ) };
        $err = $@;
        my $has_err = defined $err && length $err > 0;
        ok $has_err == $tc->{want_err}, $tc->{name} . ' error flag';
        if ( !$tc->{want_err} && defined $tc->{verify} ) {
            $tc->{verify}($got);
        }
    }
};
subtest 'Encoder encode with different image types' => sub {
    my $red_rgba  = "\xFF\x00\x00\xFF";
    my $gray_rgba = "\x80\x80\x80\xFF";
    my @tests     = (
        { name => 'RGBA image to RGBA format', img => $red_rgba,  width => 1, height => 1, format => RGBA, want_len => 4, },
        { name => 'Gray image to RGBA format', img => $gray_rgba, width => 1, height => 1, format => RGBA, want_len => 4, },
        { name => 'RGBA image to RGB format',  img => $red_rgba,  width => 1, height => 1, format => RGB,  want_len => 3, },
        { name => 'Gray image to RGB format',  img => $gray_rgba, width => 1, height => 1, format => RGB,  want_len => 3, }
    );
    for my $tc (@tests) {
        my $e = Cancer::Ansi::Kitty::Encoder->new( format => $tc->{format} );
        my ( $got, $err );
        eval { $got = $e->encode( $tc->{img}, $tc->{width}, $tc->{height} ) };
        $err = $@;
        ok !( defined $err && length $err > 0 ), $tc->{name} . ' no error';
        is length($got), $tc->{want_len}, $tc->{name} . ' output length';
    }
};
#
done_testing;
