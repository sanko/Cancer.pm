package Cancer::Cell 1.0 {
    use strictures 2;
    use Moo;
    use Types::Standard qw[Any Bool];
    use experimental 'signatures';
    use feature 'unicode_strings';
    use Carp qw[croak];
    #
    has chr => (
        is   => 'rw',
        isa  => sub ($chr) { croak "'$chr' is too wide" if 1 < ( 0 + ( () = $chr =~ /\w/g ) ) },
        lazy => 1,
        predicate => 1,
        trigger   => sub ( $s, $val ) {
            $s->dirty(1);
        }
    );
    has style => (
        is  => 'ro',
        isa => Any,    # Unknown right now; I need to decide what styles look like
    );
    has dirty => ( is => 'rw', isa => Bool, default => 1 );    # Only redraw if true
    #
    sub width($s)  { 0 + ( $s->has_chr ? () = $s->chr =~ /\X/gu : 0 ) }    # Grapheme size
    sub length($s) { 0 + ( $s->has_chr ? () = $s->chr =~ /\w/gu : 0 ) }    # Display size
};
1;
