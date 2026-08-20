use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term qw[:all];
#
is get_size(9999), E(), 'get_size on non-terminal returns empty list';

# get_size should return two positive integers when on a real TTY.
# On Windows, GetConsoleScreenBufferInfo only works on output handles
SKIP: {
    skip 'STDOUT is not a terminal', 2 unless -t STDOUT;
    my ( $w, $h ) = get_size( fileno *STDOUT );
    is $w, number_gt 0, "width is positive ($w)";
    is $h, number_gt 0, "height is positive ($h)";
}
done_testing;
