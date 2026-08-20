use v5.42;
use experimental 'class';
class Cancer::CellBuf::Pen v0.0.1 {
    use Cancer::Ansi qw[ResetStyle set_hyperlink reset_hyperlink];
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;
    field $writer : param;
    field $style = Cancer::CellBuf::Style->new;
    field $link  = Cancer::CellBuf::Link->new;
    method style () {$style}
    method link ()  {$link}

    method write ($data) {
        my $out = '';
        for my $byte ( split //, $data ) {
            if ( $byte eq "\n" ) {
                if ( !$style->empty ) {
                    $out .= ResetStyle();
                }
                if ( !$link->empty ) {
                    $out .= reset_hyperlink();
                }
            }
            $out .= $byte;
            if ( $byte eq "\n" ) {
                if ( !$link->empty ) {
                    $out .= set_hyperlink( $link->url, $link->params );
                }
                if ( !$style->empty ) {
                    $out .= $style->sequence;
                }
            }
        }
        $writer->print($out) if $writer;
        return length $data;
    }

    method close () {
        if ( !$style->empty ) {
            $writer->print( ResetStyle() ) if $writer;
        }
        if ( !$link->empty ) {
            $writer->print( reset_hyperlink() ) if $writer;
        }
        return $self;
    }
} 1;
