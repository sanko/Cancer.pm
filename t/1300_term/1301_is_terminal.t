use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term qw[:all];
use File::Temp   qw[tempfile];
#
{
    my ( $fh, $name ) = tempfile( UNLINK => 1 );
    my $fd = fileno($fh);
    is is_terminal($fd), F(), 'temp file is not a terminal';
    close $fh;
}
SKIP: {
    pipe( my $rd, my $wr ) or skip "pipe: $!", 1;
    my $fd = fileno($rd);
    is is_terminal($fd), F(), 'pipe is not a terminal';
    close $rd;
    close $wr;
}
{
    my $result = is_terminal(0);
    is $result, D(), 'is_terminal returns defined value';
    ok $result == 0 || $result == 1, 'is_terminal returns 0 or 1';
}
#
done_testing;
