package Cancer::Event::Mouse 0.01 {
    use Moo;
    extends 'Cancer::Event';
    use Types::Standard qw[Int Num Str];
    has [qw[button mod x y]] => ( is => 'rw', isa => Int );
};
1;
