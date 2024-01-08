use strict;
use warnings;
use Test2::V0               qw[is ok done_testing];
use Test2::Tools::Exception qw[dies];
use lib '../lib', 'lib';
use Cancer;
#
$|++;
#
my $terminfo = Cancer::terminfo->new();
is( $terminfo->tparm( '%d|%s', 300, 'Testing' ),     '300|Testing',     'string and int' );
is( $terminfo->tparm( '%d%% out of %d%%', 32, 100 ), '32% out of 100%', '%% formats percent' );
is( $terminfo->tparm( "%s", '1' ),                   '1',               "%s formats numbers" );
is( $terminfo->tparm( "%s", '⅑' ),                   "⅑",               "%s formats fractions" );
is( $terminfo->tparm( "%s", 'Ⅷ' ),                   'Ⅷ',               "%s formats graphemes" );
is( $terminfo->tparm( "%s", '三' ),                   '三',               "%s formats CJKV" );
#
is( $terminfo->tparm( "%?%p2%p6%|%t;3%;", 0, 0, 0, 0, 0, 0 ), "",   "%?%p2%p6%|%t;3%; | 0,0,0,0,0,0" );
is( $terminfo->tparm( "%?%p2%p6%|%t;3%;", 0, 0, 0, 0, 0, 1 ), ";3", "%?%p2%p6%|%t;3%; | 0,0,0,0,0,1" );
is( $terminfo->tparm( "%?%p2%p6%|%t;3%;", 0, 1, 0, 0, 0, 0 ), ";3", "%?%p2%p6%|%t;3%; | 0,1,0,0,0,0" );
is( $terminfo->tparm( "%p3[%d|%d|%d|%d|%d]", 0, 5, 8, 9 ), "[0|5|8|9|8]", "%p3[%d|%d|%d|%d|%d] takes vars from params | 0, 5, 8, 9" );
#
is( $terminfo->tparm( "%Pa|%ga|%s", '三' ), "||三", "%Pa sets dynamic var to pop()" );
ok( !$terminfo->tparm( "%ga%s",     '' ), "%Pa fails to get dynamic var" );
is( $terminfo->tparm( "%PA", 'Blah' ),   '',     "%PA sets static var to pop()" );
is( $terminfo->tparm("%gA%s"),           'Blah', "%gA gets static var" );
is( $terminfo->tparm( "%c", ord 'a' ),   'a',    "%c gets a single char" );
is( $terminfo->tparm( "%l|%d", 'Fun!' ), '|4',   "%l pushes string length of pop()" );
is( $terminfo->tparm("%{22}|%d"),        '|22',  "%{nn} pushes an integer constant" );
is( $terminfo->tparm("%'i'|%s"),         '|i',   "%'i' pushes a char constant" );
ok( dies { $terminfo->tparm("%'if'|%s") }, "%'if' failes to push a char constant" );
is( $terminfo->tparm( "%i|%d|%d", 4, 5 ), '|5|6', "%i adds one to the first two parameters (for ANSI terminals)" );

# Arithmetic
is( $terminfo->tparm( "%+|%d", 4,  3 ), '|7',  "%+ pushes pop() + pop()" );
is( $terminfo->tparm( "%-|%d", 10, 6 ), '|4',  "%- pushes pop() - pop()" );
is( $terminfo->tparm( "%*|%d", 3,  5 ), '|15', "%* pushes pop() * pop()" );
is( $terminfo->tparm( "%/|%d", 10, 5 ), '|2',  "%/ pushes pop() / pop()" );
is( $terminfo->tparm( "%m|%d", 5,  2 ), '|1',  "%m pushes pop() % pop()" );

# Unary ops
is( $terminfo->tparm( "%!|%d", 1 ),  '|0',   "%! pushes !pop() | 1" );
is( $terminfo->tparm( "%!|%d", 0 ),  '|1',   "%! pushes !pop() | 0" );
is( $terminfo->tparm( "%~|%d", 16 ), '|-17', "%! pushes ~pop()" );
#
is( $terminfo->tparm( "%A|%d", 1, 1 ), '|1', "%A pushes pop() && pop() | 1 && 1" );
is( $terminfo->tparm( "%A|%d", 1, 0 ), '|0', "%A pushes pop() && pop() | 1 && 0" );
is( $terminfo->tparm( "%A|%d", 0, 0 ), '|0', "%A pushes pop() && pop() | 0 && 0" );
is( $terminfo->tparm( "%O|%d", 1, 1 ), '|1', "%O pushes pop() || pop() | 1 || 1" );
is( $terminfo->tparm( "%O|%d", 1, 0 ), '|1', "%O pushes pop() || pop() | 1 || 0" );
is( $terminfo->tparm( "%O|%d", 0, 0 ), '|0', "%O pushes pop() || pop() | 0 || 0" );
#
is( $terminfo->tparm( "%&|%d", 1, 0 ), '|0', "%& pushes pop() & pop() | 1 & 0" );
is( $terminfo->tparm( "%&|%d", 1, 1 ), '|1', "%& pushes pop() & pop() | 1 & 1" );
is( $terminfo->tparm( "%&|%d", 0, 0 ), '|0', "%& pushes pop() & pop() | 0 & 0" );
is( $terminfo->tparm( "%&|%d", 1, 0 ), '|0', "%| pushes pop() | pop() | 1 | 0" );
is( $terminfo->tparm( "%&|%d", 1, 1 ), '|1', "%| pushes pop() | pop() | 1 | 1" );
is( $terminfo->tparm( "%&|%d", 0, 0 ), '|0', "%| pushes pop() | pop() | 0 | 0" );
is( $terminfo->tparm( "%^|%d", 1, 4 ), '|5', "%^ pushes pop() ^ pop() | 1 ^ 0" );
is( $terminfo->tparm( "%^|%d", 2, 7 ), '|5', "%^ pushes pop() ^ pop() | 2 ^ 7" );
is( $terminfo->tparm( "%^|%d", 1, 1 ), '|0', "%^ pushes pop() ^ pop() | 1 ^ 1" );
is( $terminfo->tparm( "%^|%d", 0, 0 ), '|0', "%^ pushes pop() ^ pop() | 0 ^ 0" );
#
is( $terminfo->tparm( "%=|%d", 1, 0 ), '|0', "%= pushes pop() == pop() | 1 == 0" );
is( $terminfo->tparm( "%=|%d", 1, 1 ), '|1', "%= pushes pop() == pop() | 1 == 1" );
is( $terminfo->tparm( "%=|%d", 0, 0 ), '|1', "%= pushes pop() == pop() | 0 == 0" );
is( $terminfo->tparm( "%>|%d", 1, 0 ), '|1', "%> pushes pop() > pop() | 1 > 0" );
is( $terminfo->tparm( "%>|%d", 1, 1 ), '|0', "%> pushes pop() > pop() | 1 > 1" );
is( $terminfo->tparm( "%>|%d", 2, 1 ), '|1', "%> pushes pop() > pop() | 2 > 1" );
is( $terminfo->tparm( "%>|%d", 0, 0 ), '|0', "%> pushes pop() > pop() | 0 > 0" );
is( $terminfo->tparm( "%<|%d", 1, 0 ), '|0', "%< pushes pop() < pop() | 1 < 0" );
is( $terminfo->tparm( "%<|%d", 1, 1 ), '|0', "%< pushes pop() < pop() | 1 < 1" );
is( $terminfo->tparm( "%<|%d", 1, 2 ), '|1', "%< pushes pop() < pop() | 1 < 2" );
is( $terminfo->tparm( "%<|%d", 0, 0 ), '|0', "%< pushes pop() < pop() | 0 < 0" );

# Conditionals
is( $terminfo->tparm( "%?%!%tYes!%;",              0 ), 'Yes!',         "%?%!%tYes!%;| 0" );
is( $terminfo->tparm( "%?%!%tYes!%;",              1 ), '',             "%?%!%tYes!%;| 1" );
is( $terminfo->tparm( "%?%!%tYes!%eNo!%;",         0 ), 'Yes!',         "%?%!%tYes!%eNo!%;| 0" );
is( $terminfo->tparm( "%?%!%tYes!%eNo!%;",         1 ), 'No!',          "%?%!%tYes!%eNo!%;| 1" );
is( $terminfo->tparm( "%?%!%tYes!%eNo!%;End",      0 ), 'Yes!End',      "%?%!%tYes!%eNo!%;End| 0" );
is( $terminfo->tparm( "%?%!%tYes!%eNo!%;End",      1 ), 'No!End',       "%?%!%tYes!%eNo!%;End| 1" );
is( $terminfo->tparm( "Start%?%!%tYes!%eNo!%;End", 0 ), 'StartYes!End', "Start%?%!%tYes!%eNo!%;End| 0" );
is( $terminfo->tparm( "Start%?%!%tYes!%eNo!%;End", 1 ), 'StartNo!End',  "Start%?%!%tYes!%eNo!%;End| 1" );
#
done_testing();
