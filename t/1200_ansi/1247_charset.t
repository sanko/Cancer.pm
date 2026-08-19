use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# Locking shift constants
is LS1R, "\e~", 'LS1R constant';
is LS2,  "\en", 'LS2 constant';
is LS2R, "\e}", 'LS2R constant';
is LS3,  "\eo", 'LS3 constant';
is LS3R, "\e|", 'LS3R constant';

# SelectCharacterSet / SCS
is SelectCharacterSet( '(', '0' ), "\e(0", 'SCS G0 = DEC Special Drawing';
is SelectCharacterSet( '(', 'B' ), "\e(B", 'SCS G0 = USASCII';
is SelectCharacterSet( ')', '0' ), "\e)0", 'SCS G1 = DEC Special Drawing';
is SelectCharacterSet( '*', 'A' ), "\e*A", 'SCS G2 = UK';
is SCS( '(', 'B' ), "\e(B", 'SCS alias';
#
done_testing;
