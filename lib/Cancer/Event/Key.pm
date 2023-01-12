package Cancer::Event::Key 0.01 {
    use Moo;
    extends 'Cancer::Event';
    use Types::Standard qw[Int Num Str];
    has glyph => ( is => 'ro', isa => Str, required => 1 );
    has mod   => ( is => 'ro', isa => Int, default  => 0 );
};
1;
