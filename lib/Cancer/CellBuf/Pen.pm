use v5.42;

package Cancer::CellBuf::Pen v0.0.1 {
    use Cancer::Ansi qw[ResetStyle set_hyperlink reset_hyperlink];
    use Cancer::CellBuf::Style;
    use Cancer::CellBuf::Link;

    sub new ( $class, $writer ) {
        bless { w => $writer, style => Cancer::CellBuf::Style->new, link => Cancer::CellBuf::Link->new }, $class;
    }
    sub style ($self) { $self->{style} }
    sub link  ($self) { $self->{link} }

    sub write ( $self, $data ) {
        my $out = '';
        for my $byte ( split //, $data ) {
            if ( $byte eq "\n" ) {
                if ( !$self->{style}->empty ) {
                    $out .= ResetStyle();
                }
                if ( !$self->{link}->empty ) {
                    $out .= reset_hyperlink();
                }
            }
            $out .= $byte;
            if ( $byte eq "\n" ) {
                if ( !$self->{link}->empty ) {
                    $out .= set_hyperlink( $self->{link}->url, $self->{link}->params );
                }
                if ( !$self->{style}->empty ) {
                    $out .= $self->{style}->sequence;
                }
            }
        }
        $self->{w}->print($out) if $self->{w};
        return length $data;
    }

    sub close ($self) {
        if ( !$self->{style}->empty ) {
            $self->{w}->print( ResetStyle() ) if $self->{w};
        }
        if ( !$self->{link}->empty ) {
            $self->{w}->print( reset_hyperlink() ) if $self->{w};
        }
        $self;
    }
}
1;
