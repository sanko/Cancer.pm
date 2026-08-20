use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term::File qw[:all];
use File::Temp         qw[tempfile];
#
is is_file_like('hello'), F(), 'string is not file-like';
is is_file_like( {} ),    F(), 'hashref is not file-like';
is is_file_like(undef),   F(), 'undef is not file-like';
my ( $fh, $name ) = tempfile( UNLINK => 1 );
is is_file_like($fh), T(), 'filehandle is file-like';
my $fd = file_fd($fh);
ok defined $fd && $fd >= 0, 'fd returns valid file descriptor';
close $fh;
#
done_testing;
