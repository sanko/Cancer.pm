use v5.42;
use experimental 'class';
class Cancer::Ansi::Kitty::Decoder v0.0.1 {
    use Compress::Zlib qw[uncompress];
    use Cancer::Ansi::Kitty qw[RGBA RGB PNG];
    #
    field $decompress : param = 0;
    field $format     : param = 0;
    field $width      : param = 0;
    field $height     : param = 0;

    method decode ($data) {
        if ($decompress) {
            my $ok = uncompress($data);
            die "failed to decompress zlib data" unless defined $ok;
            $data = $ok;
        }
        my $fmt = $format || RGBA;
        if ( $fmt == RGBA || $fmt == RGB ) {
            return $self->_decode_rgba( $data, $fmt == RGBA );
        }
        elsif ( $fmt == PNG ) {
            return $self->_decode_png($data);
        }
        else {
            die "unsupported format: $fmt";
        }
    }

    method _decode_rgba ( $data, $alpha ) {
        my $bpp      = $alpha ? 4 : 3;
        my $expected = $width * $height * $bpp;
        die "incomplete pixel data" if length($data) < $expected;
        my $pixels = '';
        for my $y ( 0 .. $height - 1 ) {
            for my $x ( 0 .. $width - 1 ) {
                my $off = ( $y * $width + $x ) * $bpp;
                my $r   = ord substr $data, $off + 0, 1;
                my $g   = ord substr $data, $off + 1, 1;
                my $b   = ord substr $data, $off + 2, 1;
                my $a   = $alpha ? ord( substr $data, $off + 3, 1 ) : 0xFF;
                $pixels .= chr($r) . chr($g) . chr($b) . chr($a);
            }
        }
        return { width => $width, height => $height, pixels => $pixels, };
    }

    method _decode_png ($data) {
        my ( $w, $h, $pixels ) = _parse_png($data);
        return { width => $w, height => $h, pixels => $pixels, };
    }

    sub _parse_png ($data) {
        my $pos = 8;
        my ( $width, $height, $bit_depth, $color_type );
        my @chunks;
        while ( $pos < length($data) ) {
            last if length($data) - $pos < 8;
            my $len        = unpack 'N', substr $data, $pos, 4;
            my $type       = substr $data, $pos + 4, 4;
            my $chunk_data = substr $data, $pos + 8, $len;
            $pos += 12 + $len;
            if ( $type eq 'IHDR' ) {
                ( $width, $height, $bit_depth, $color_type ) = unpack 'NNCC', $chunk_data;
            }
            elsif ( $type eq 'IDAT' ) {
                push @chunks, $chunk_data;
            }
            elsif ( $type eq 'IEND' ) {
                last;
            }
        }
        my $compressed = join '', @chunks;
        my $raw        = uncompress($compressed);
        die "failed to decompress PNG IDAT" unless defined $raw;
        my $bpp    = _bpp( $color_type, $bit_depth );
        my $pixels = '';
        for my $y ( 0 .. $height - 1 ) {
            my $row_start = $y * ( $width * $bpp + 1 ) + 1;
            for my $x ( 0 .. $width - 1 ) {
                my ( $r, $g, $b, $a ) = _get_pixel( $raw, $row_start, $x, $color_type, $bpp );
                $pixels .= chr($r) . chr($g) . chr($b) . chr($a);
            }
        }
        return ( $width, $height, $pixels );
    }

    sub _bpp ( $color_type, $bit_depth ) {
        return 4 if $color_type == 6;
        return 3 if $color_type == 2;
        return 2 if $color_type == 4;
        return 1;
    }

    sub _get_pixel ( $data, $row_start, $x, $color_type, $bpp ) {
        my $off = $row_start + $x * $bpp;
        if ( $color_type == 6 ) {
            return (
                ord( substr $data, $off + 0, 1 ),
                ord( substr $data, $off + 1, 1 ),
                ord( substr $data, $off + 2, 1 ),
                ord( substr $data, $off + 3, 1 ),
            );
        }
        if ( $color_type == 2 ) {
            return ( ord( substr $data, $off + 0, 1 ), ord( substr $data, $off + 1, 1 ), ord( substr $data, $off + 2, 1 ), 0xFF, );
        }
        if ( $color_type == 0 ) {
            my $g = ord( substr $data, $off, 1 );
            return ( $g, $g, $g, 0xFF );
        }
        return ( 0, 0, 0, 0xFF );
    }
};
#
1;
