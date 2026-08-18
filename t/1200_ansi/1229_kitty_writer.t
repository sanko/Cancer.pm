use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Ansi qw(kitty_graphics);
use MIME::Base64;

# Ported from charmbracelet/x/ansi/kitty/writer_test.go
# Tests Kitty Graphics Protocol APC sequence generation.
#
# The Go version uses image/zlib to encode actual image data.
# The Perl version tests the text-based APC sequence structure
# using kitty_graphics() from Cancer::Ansi.
#
# EncodeGraphics writes an APC sequence:
#   \e_G<options>;<base64-payload>\e\\
sub encode_graphics {
    my ( $payload, $opts ) = @_;
    $opts //= [];
    return kitty_graphics( $payload, @$opts );
}

# -- Tests ---------------------------------------------------------------
subtest 'TestWriteKittyGraphics' => sub {
    my $test_payload = "AAAA";    # simple base64-like data
    my @tests        = (
        {   name    => 'direct transmission',
            payload => $test_payload,
            opts    => [ 'f=24', 't=d' ],
            check   => sub {
                my ($out) = @_;
                ok index( $out, "\e_G" ) == 0,   'output should start with ESC sequence';
                ok substr( $out, -2 ) eq "\e\\", 'output should end with ST sequence';
                like $out, qr/f=24/, 'output should contain format specification';
            },
        },
        {   name    => 'file transmission',
            payload => encode_base64( '/tmp/test.png', '' ),
            opts    => ['t=f'],
            check   => sub {
                my ($out) = @_;
                like $out, qr{t=f}, 'output should contain transmission specification';
                ok index( $out, encode_base64( '/tmp/test.png', '' ) ) > 0, 'output should contain encoded file path';
            },
        },
        {   name    => 'compression enabled',
            payload => $test_payload,
            opts    => [ 'f=32', 'o=z' ],
            check   => sub {
                my ($out) = @_;
                like $out, qr/o=z/, 'output should contain compression specification';
            },
        },
        {   name    => 'nil options (no options)',
            payload => $test_payload,
            opts    => [],
            check   => sub {
                my ($out) = @_;
                ok index( $out, "\e_G" ) == 0, 'output should start with ESC sequence';
            },
        },
    );
    for my $tc (@tests) {
        my $out = encode_graphics( $tc->{payload}, $tc->{opts} );
        $tc->{check}($out);
    }
};
subtest 'TestWriteKittyGraphicsEdgeCases' => sub {

    # Test zero-size payload (empty string)
    my $out1 = encode_graphics( '', ['f=24'] );
    ok index( $out1, "\e_G" ) == 0,   'zero size payload starts with ESC';
    ok substr( $out1, -2 ) eq "\e\\", 'zero size payload ends with ST';

    # The Go test also tests SharedMemory transmission (returns error) and
    # File transmission without file path (returns error) — these are
    # error-handling cases that the Perl kitty_graphics function does
    # not validate, so we skip those.
};
done_testing;
