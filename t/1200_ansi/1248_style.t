use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# ResetStyle constant
is ResetStyle, "\e[m", 'ResetStyle constant';

# Underline style constants
is UnderlineNone,   0, 'UnderlineNone = 0';
is UnderlineSingle, 1, 'UnderlineSingle = 1';
is UnderlineDouble, 2, 'UnderlineDouble = 2';
is UnderlineCurly,  3, 'UnderlineCurly = 3';
is UnderlineDotted, 4, 'UnderlineDotted = 4';
is UnderlineDashed, 5, 'UnderlineDashed = 5';

# SGR with underline style codes
is SGR(4),     "\e[4m",   'SGR single underline';
is SGR("4:2"), "\e[4:2m", 'SGR double underline';
is SGR("4:3"), "\e[4:3m", 'SGR curly underline';
is SGR("4:4"), "\e[4:4m", 'SGR dotted underline';
is SGR("4:5"), "\e[4:5m", 'SGR dashed underline';

# SGR with bold + underline style
is SGR( 1, "4:3" ), "\e[1;4:3m", 'SGR bold + curly underline';
#
done_testing;
