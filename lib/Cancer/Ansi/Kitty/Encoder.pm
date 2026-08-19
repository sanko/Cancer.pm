use v5.42;
use experimental 'class';
class Cancer::Ansi::Kitty::Encoder v0.0.1 {
    use Compress::Zlib qw[compress crc32];
    use Cancer::Ansi::Kitty qw[RGBA RGB PNG];
    #
    field $compress : param = 0;
    field $format   : param = 0;

    method encode ( $pixels, $width, $height ) {
        return '' unless defined $pixels && length $pixels > 0;
        my $fmt = $format || RGBA;
        my $out;
        if ( $fmt == RGBA || $fmt == RGB ) {
            my $bpp = $fmt == RGBA ? 4 : 3;
            for my $y ( 0 .. $height - 1 ) {
                for my $x ( 0 .. $width - 1 ) {
                    my $off = ( $y * $width + $x ) * 4;
                    my $r   = ord substr $pixels, $off + 0, 1;
                    my $g   = ord substr $pixels, $off + 1, 1;
                    my $b   = ord substr $pixels, $off + 2, 1;
                    my $a   = ord substr $pixels, $off + 3, 1;
                    if ( $fmt == RGBA ) {
                        $out .= chr($r) . chr($g) . chr($b) . chr($a);
                    }
                    else {
                        $out .= chr($r) . chr($g) . chr($b);
                    }
                }
            }
        }
        elsif ( $fmt == PNG ) {
            $out = _make_png( $pixels, $width, $height );
        }
        else {
            die "unsupported format: $fmt";
        }
        if ($compress) {
            $out = compress($out);
        }
        return $out;
    }

    sub _make_png ( $pixels, $width, $height ) {
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

    sub _png_chunk ( $type, $data ) {
        my $crc = crc32( $type . $data );
        return pack( 'N', length($data) ) . $type . $data . pack( 'N', $crc );
    }
};
#
1;
