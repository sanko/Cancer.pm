use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;
use Cancer::Ansi        qw[kitty_graphics];
use Cancer::Ansi::Kitty qw[MaxChunkSize RGBA RGB PNG Zlib Direct File TempFile SharedMemory Frame];
use Cancer::Ansi::Kitty::Encoder;
use MIME::Base64;
use File::Temp qw[tempdir tempfile];

# Ported from charmbracelet/x/ansi/kitty/writer_test.go
# Tests Kitty Graphics Protocol APC sequence generation and chunking.
# build_options serializes an options hash into key=value strings, mirroring Go's Options.Options() method.
sub build_options( $o //= {} ) {
    my $format       = $o->{format} // RGBA;
    my $transmission = $o->{transmission};
    my $file         = $o->{file} // '';

    # Auto-detect file transmission from file path
    if ( !$transmission && $file ne '' ) {
        $transmission = File;
    }
    $transmission //= Direct;
    my @opts;
    push @opts, sprintf( 'f=%d', $format ) if $format != RGBA;
    my $quiet = $o->{quiet} // 0;
    $quiet = $o->{quite} if ( $o->{quite} // 0 ) > 0;
    push @opts, sprintf( 'q=%d', $quiet ) if $quiet > 0;
    push @opts, 'o=z'                     if defined $o->{compression} && $o->{compression} eq Zlib;
    push @opts, "t=$transmission"         if $transmission ne Direct;
    return @opts;
}

# build_chunk_options creates the options slice for a chunk,
# mirroring Go's buildChunkOptions.
sub build_chunk_options ( $o, $is_first, $is_last ) {
    my @opts;
    if ($is_first) {
        @opts = build_options($o);
    }
    else {
        my $quiet = $o->{quiet} // 0;
        $quiet = $o->{quite} if ( $o->{quite} // 0 ) > 0;
        push @opts, sprintf( 'q=%d', $quiet ) if $quiet > 0;
        if ( ( $o->{action} // '' ) eq Frame ) {
            push @opts, 'a=f';
        }
    }
    if ( !$is_first || !$is_last ) {
        push @opts, $is_last ? 'm=0' : 'm=1';
    }
    return @opts;
}

# encode_graphics writes an image using the Kitty Graphics protocol with the
# given options to a buffer. It chunks the written data if opts->{chunk} is true.
# Mirrors Go's EncodeGraphics.
sub encode_graphics ( $buf_ref, $pixels, $width, $height, $opts //= {} ) {
    my $transmission = $opts->{transmission};
    my $file         = $opts->{file} // '';

    # Auto-detect file transmission from file path
    if ( !$transmission && $file ne '' ) {
        $transmission = File;
    }
    $transmission //= Direct;
    my $data     = '';
    my $compress = defined $opts->{compression} && $opts->{compression} eq Zlib ? 1 : 0;
    my $format   = $opts->{format} // RGBA;
    my $encoder  = Cancer::Ansi::Kitty::Encoder->new( compress => $compress, format => $format );
    if ( $transmission eq Direct ) {
        eval { $data = $encoder->encode( $pixels, $width, $height ); };
        if ($@) {
            return "failed to encode direct image: $@";
        }
    }
    elsif ( $transmission eq SharedMemory ) {
        return "shared memory transmission is not yet implemented";
    }
    elsif ( $transmission eq File ) {
        if ( $file eq '' ) {
            return "missing file path";
        }
        if ( !-e $file ) {
            return "failed to open file: $!";
        }
        if ( !-f $file ) {
            return "file is not a regular file";
        }
        $data = $file;
    }
    elsif ( $transmission eq TempFile ) {
        my ( $fh, $tempfile ) = tempfile( 'tty-graphics-protocol-XXXXXX', UNLINK => 1 );
        binmode($fh);
        my $encoded = $encoder->encode( $pixels, $width, $height );
        print $fh $encoded;
        close $fh;
        $data = $tempfile;
    }
    else {
        return "unknown transmission: $transmission";
    }

    # Base64 encode the data
    my $payload = encode_base64( $data, '' );

    # If not chunking, write all at once
    if ( !$opts->{chunk} ) {
        my @apc_opts = build_options($opts);
        $$buf_ref .= kitty_graphics( $payload, @apc_opts );
        return undef;
    }

    # Write in chunks.
    # Mirrors Go's io.ReadFull pattern: loop writes full MaxChunkSize chunks
    # with m=1, then writes the final (possibly empty) remainder with m=0.
    my $is_first = 1;
    while ( length($payload) >= MaxChunkSize ) {
        my $chunk = substr( $payload, 0, MaxChunkSize, '' );
        my @opts  = build_chunk_options( $opts, $is_first, 0 );
        $$buf_ref .= kitty_graphics( $chunk, @opts );
        $is_first = 0;
    }

    # Final chunk (may be partial or empty if payload was exact multiple)
    my @opts = build_chunk_options( $opts, $is_first, 1 );
    $$buf_ref .= kitty_graphics( $payload, @opts );
    return undef;    # success
}

# 2x2 RGBA image: Red, Green, Blue, White (matching Go test)
my $pixels_2x2 = '';

# Row 0
$pixels_2x2 .= chr(255) . chr(0) . chr(0) . chr(255);    # Red
$pixels_2x2 .= chr(0) . chr(255) . chr(0) . chr(255);    # Green

# Row 1
$pixels_2x2 .= chr(0) . chr(0) . chr(255) . chr(255);        # Blue
$pixels_2x2 .= chr(255) . chr(255) . chr(255) . chr(255);    # White

# 100x100 RGBA image, all red (larger than MaxChunkSize when base64 encoded)
my $pixels_large = ( chr(255) . chr(0) . chr(0) . chr(255) ) x ( 100 * 100 );

# Temporary test file for file transmission
my $tmpdir  = tempdir( CLEANUP => 1 );
my $tmpfile = "$tmpdir/test-image";
open my $tmpfh, '>', $tmpfile or die "Can't write $tmpfile: $!";
print $tmpfh "test image data";
close $tmpfh;
#
subtest 'write kitty graphics' => sub {
    my @tests = (
        {   name       => 'direct transmission',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { format => RGB, transmission => Direct },
            want_error => 0,
            check      => sub ($output) {
                ok index( $output, "\e_G" ) == 0,   'output should start with ESC sequence';
                ok substr( $output, -2 ) eq "\e\\", 'output should end with ST sequence';
                like $output, qr/f=24/, 'output should contain format specification';
            }
        },
        {   name       => 'chunked transmission',
            pixels     => $pixels_large,
            width      => 100,
            height     => 100,
            opts       => { format => RGB, transmission => Direct, chunk => 1 },
            want_error => 0,
            check      => sub ($output) {
                my @chunks = split( /\e\\/, $output );
                ok scalar @chunks >= 2, 'output should contain multiple chunks';
                for my $i ( 0 .. $#chunks ) {
                    if ( $i == $#chunks ) {
                        like $chunks[$i], qr/m=0/, "output should contain chunk end-of-data indicator for chunk $i";
                    }
                    else {
                        like $chunks[$i], qr/m=1/, "output should contain chunk indicator for chunk $i";
                    }
                }
            }
        },
        {   name       => 'file transmission',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { transmission => File, file => $tmpfile },
            want_error => 0,
            check      => sub ($output) {
                like $output, qr/\Q@{[ encode_base64( $tmpfile, '' ) ]}/, 'output should contain encoded file path';
            }
        },
        {   name       => 'temp file transmission',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { transmission => TempFile },
            want_error => 0,
            check      => sub($output) {
                my $stripped = $output;
                $stripped =~ s/^\e_G//;
                $stripped =~ s/\e\\$//;
                my ( undef, $b64payload ) = split( /;/, $stripped, 2 );
                my $decoded = decode_base64($b64payload);
                ok defined $decoded && length($decoded) > 0, 'output should contain base64 encoded temp file path';
                like $decoded, qr/tty-graphics-protocol/, 'output should contain temp file path';
                like $output,  qr/t=t/,                   'output should contain transmission specification';
            }
        },
        {   name       => 'compression enabled',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { compression => Zlib, transmission => Direct },
            want_error => 0,
            check      => sub($output) {
                like $output, qr/o=z/, 'output should contain compression specification';
            }
        },
        {   name       => 'invalid file path',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { transmission => File, file => '/nonexistent/file' },
            want_error => 1,
            check      => undef
        },
        {   name       => 'nil options',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => undef,
            want_error => 0,
            check      => sub ($output) {
                ok index( $output, "\e_G" ) == 0, 'output should start with ESC sequence';
            }
        }
    );
    for my $tc (@tests) {
        subtest $tc->{name} => sub {
            my $output = '';
            my $err    = encode_graphics( \$output, $tc->{pixels}, $tc->{width}, $tc->{height}, $tc->{opts} );
            if ( $tc->{want_error} ) {
                ok defined $err, 'should return error';
            }
            else {
                ok !defined $err, 'should not return error';
                $tc->{check}->($output) if $tc->{check};
            }
        }
    }
};
subtest 'TestWriteKittyGraphicsEdgeCases' => sub {
    my @tests = (
        { name => 'zero size image', pixels => '', width => 0, height => 0, opts => { transmission => Direct }, want_error => 0 },
        {   name       => 'shared memory transmission',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { transmission => SharedMemory },
            want_error => 1
        },
        {   name       => 'file transmission without file path',
            pixels     => $pixels_2x2,
            width      => 2,
            height     => 2,
            opts       => { transmission => File },
            want_error => 1
        }
    );
    for my $tc (@tests) {
        subtest $tc->{name} => sub {
            my $output = '';
            my $err    = encode_graphics( \$output, $tc->{pixels}, $tc->{width}, $tc->{height}, $tc->{opts} );
            if ( $tc->{want_error} ) {
                ok defined $err, 'should return error';
            }
            else {
                ok !defined $err, 'should not return error';
            }
        };
    }
};
#
done_testing;
