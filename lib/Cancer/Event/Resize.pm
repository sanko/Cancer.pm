package Cancer::Event::Resize 1.0 {
    use Moo;
    extends 'Cancer::Event';
    use Types::Standard qw[Int Num Str];
    has [qw[w h]] => ( is => 'rw', isa => Int );
};
1;
