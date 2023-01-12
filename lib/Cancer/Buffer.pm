package Cancer::Buffer 0.01 {
    use strict;
    use warnings;
    use Moo;
    use Types::Standard qw[Int Str];
    #
    has [qw[width height]] => ( is => 'ro', isa => Int, required => 1 );
    has data               => ( is => 'rw', isa => Str, default  => '' );
};
1;
