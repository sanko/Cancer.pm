use v5.42;

package Cancer::CellBuf::Geom v0.0.1 {
    use experimental 'class';
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[Pos Rect] ] );
    #
    class Cancer::CellBuf::Position {
        field $x : param : reader //= 0;
        field $y : param : reader //= 0;
    };

    class Cancer::CellBuf::Rectangle {
        field $x      : reader : param //= 0;
        field $y      : reader : param //= 0;
        field $width  : reader : param //= 0;
        field $height : reader : param //= 0;
        #
        field $min : reader = Cancer::CellBuf::Geom::Pos( $x,          $y );
        field $max : reader = Cancer::CellBuf::Geom::Pos( $x + $width, $y + $height );
        #
        field $min_x : reader = $x;
        field $min_y : reader = $y;
        field $max_x : reader = $x + $width;
        field $max_y : reader = $y + $height;
        #
        field $dx : reader = $max_x - $min_x;
        field $dy : reader = $max_y - $min_y;
        method in ($p) { $p->x >= $min_x && $p->x < $max_x && $p->y >= $min_y && $p->y < $max_y }
    };
    #
    sub Pos  ( $x, $y )                  { Cancer::CellBuf::Position->new( x => $x, y => $y ) }
    sub Rect ( $x, $y, $width, $height ) { Cancer::CellBuf::Rectangle->new( x => $x, y => $y, width => $width, height => $height ) }
};
#
1;
