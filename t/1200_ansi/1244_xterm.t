use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# Xterm constants
is SetModifyOtherKeys1,  "\e[>4;1m", 'SetModifyOtherKeys1 constant';
is SetModifyOtherKeys2,  "\e[>4;2m", 'SetModifyOtherKeys2 constant';
is ResetModifyOtherKeys, "\e[>4m",   'ResetModifyOtherKeys constant';
is QueryModifyOtherKeys, "\e[?4m",   'QueryModifyOtherKeys constant';

# KeyModifierOptions / XTMODKEYS
is KeyModifierOptions(1),      "\e[>1m",   'XTMODKEYS reset resource 1';
is KeyModifierOptions( 4, 1 ), "\e[>4;1m", 'XTMODKEYS set resource 4 value 1';
is KeyModifierOptions( 4, 2 ), "\e[>4;2m", 'XTMODKEYS set resource 4 value 2';
is KeyModifierOptions(0),      "\e[>0m",   'XTMODKEYS resource 0';
is XTMODKEYS(1),               "\e[>1m",   'XTMODKEYS alias';

# SetKeyModifierOptions
is SetKeyModifierOptions( 4, 1 ), "\e[>4;1m", 'SetKeyModifierOptions(4,1)';
is SetKeyModifierOptions( 4, 2 ), "\e[>4;2m", 'SetKeyModifierOptions(4,2)';

# ResetKeyModifierOptions
is ResetKeyModifierOptions(4), "\e[>4m", 'ResetKeyModifierOptions(4)';
is ResetKeyModifierOptions(1), "\e[>1m", 'ResetKeyModifierOptions(1)';

# QueryKeyModifierOptions / XTQMODKEYS
is QueryKeyModifierOptions(4), "\e[?4m", 'QueryKeyModifierOptions(4)';
is QueryKeyModifierOptions(1), "\e[?1m", 'QueryKeyModifierOptions(1)';
is XTQMODKEYS(4),              "\e[?4m", 'XTQMODKEYS alias';

# ModifyOtherKeys
is ModifyOtherKeys(0), "\e[>4;0m", 'ModifyOtherKeys(0) disable';
is ModifyOtherKeys(1), "\e[>4;1m", 'ModifyOtherKeys(1) mode 1';
is ModifyOtherKeys(2), "\e[>4;2m", 'ModifyOtherKeys(2) mode 2';
#
done_testing;
