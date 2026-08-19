use v5.42;
use experimental 'class';

package Cancer::Ansi::Sixel v0.0.1 {
    use Exporter 'import';
    our @EXPORT_OK = qw[
        RasterAttribute RepeatIntroducer
        Raster WriteRaster DecodeRaster
        Repeat WriteRepeat DecodeRepeat
    ];
    use constant { RasterAttribute => '"', RepeatIntroducer => '!' };
    #
    sub Raster (%attr) { Cancer::Ansi::Sixel::Raster->new(%attr) }

    sub WriteRaster ( $pan, $pad, $ph //= 0, $pv //= 0 ) {
        return WriteRaster( 1, 1, $ph, $pv ) if $pad == 0;
        return qq["${pan};${pad}]            if $ph <= 0 && $pv <= 0;
        return qq["${pan};${pad};${ph};${pv}];
    }

    sub DecodeRaster ($data) {
        return ( Raster(), 0 ) if !defined $data || length $data == 0 || substr( $data, 0, 1 ) ne RasterAttribute;
        my $r     = Raster();
        my $field = 'Pan';
        my $n     = 1;
        while ( $n < length $data ) {
            my $c = substr $data, $n, 1;
            if ( $c eq ';' ) {
                if    ( $field eq 'Pan' ) { $field = 'Pad' }
                elsif ( $field eq 'Pad' ) { $field = 'Ph' }
                elsif ( $field eq 'Ph' )  { $field = 'Pv' }
                else                      { $n++; last }
            }
            elsif ( $c ge '0' && $c le '9' ) {
                $r->can( 'set_' . $field )->( $r, $r->$field * 10 + ord($c) - 48 );
            }
            else {
                last;
            }
            $n++;
        }
        return ( $r, $n );
    }
    #
    sub Repeat      ( $count, $char ) { Cancer::Ansi::Sixel::Repeat->new( Count => $count, Char => $char ) }
    sub WriteRepeat ( $count, $char ) {"!${count}${char}"}

    sub DecodeRepeat ($data) {
        return ( Repeat( 0, '' ), 0 ) if !defined $data || length $data == 0 || substr( $data, 0, 1 ) ne RepeatIntroducer;
        return ( Repeat( 0, '' ), 0 ) if length $data < 3;
        my $count = 0;
        my $n;
        for ( $n = 1; $n < length $data; $n++ ) {
            my $c = substr $data, $n, 1;
            if ( $c ge '0' && $c le '9' ) {
                $count = $count * 10 + ord($c) - 48;
            }
            else {
                $n++;
                return ( Repeat( $count, $c ), $n );
            }
        }
        return ( Repeat( 0, '' ), 0 );
    }
};
#
class Cancer::Ansi::Sixel::Raster v0.0.1 {
    field $Pan : param : reader : writer //= 0;
    field $Pad : param : reader : writer //= 0;
    field $Ph  : param : reader : writer //= 0;
    field $Pv  : param : reader : writer //= 0;
    method String() { Cancer::Ansi::Sixel::WriteRaster( $Pan, $Pad, $Ph, $Pv ) }
};
#
class Cancer::Ansi::Sixel::Repeat v0.0.1 {
    field $Count : param : reader //= 0;
    field $Char  : param : reader //= '';
    method String () { Cancer::Ansi::Sixel::WriteRepeat( $Count, $Char ) }
};
#
1;
