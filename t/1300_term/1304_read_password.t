use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Term qw[:all];
#
is read_password(9999), U(), 'read_password on non-terminal returns undef';
#
done_testing;
