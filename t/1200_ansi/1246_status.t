use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# Status report constants
is RequestCursorPositionReport,         "\e[6n",    'RequestCursorPositionReport';
is RequestExtendedCursorPositionReport, "\e[?6n",   'RequestExtendedCursorPositionReport';
is RequestLightDarkReport,              "\e[?996n", 'RequestLightDarkReport';

# CursorPositionReport / CPR
is CursorPositionReport( 1,  1 ),  "\e[1;1R",   'CPR(1,1)';
is CursorPositionReport( 10, 20 ), "\e[10;20R", 'CPR(10,20)';
is CursorPositionReport( 0,  0 ),  "\e[1;1R",   'CPR(0,0) clamps to 1,1';
is CPR( 5, 8 ), "\e[5;8R", 'CPR alias';

# ExtendedCursorPositionReport / DECXCPR
is ExtendedCursorPositionReport( 1,  1,   1 ), "\e[?1;1;1R",   'DECXCPR(1,1,1)';
is ExtendedCursorPositionReport( 10, 20,  3 ), "\e[?10;20;3R", 'DECXCPR(10,20,3)';
is ExtendedCursorPositionReport( 5,  8,   0 ), "\e[?5;8R",     'DECXCPR(5,8,0) no page';
is ExtendedCursorPositionReport( 5,  8,  -1 ), "\e[?5;8R",     'DECXCPR negative page omitted';
is DECXCPR( 2, 3, 1 ), "\e[?2;3;1R", 'DECXCPR alias';

# LightDarkReport
is LightDarkReport(1), "\e[?997;1n", 'LightDarkReport dark';
is LightDarkReport(0), "\e[?997;2n", 'LightDarkReport light';

# DeviceStatusReport / DSR (simplified - without Go's StatusReport interface)
is DeviceStatusReport(6),              "\e[6n",  'DSR ANSI format';
is DeviceStatusReport( [ DEC => 6 ] ), "\e[?6n", 'DSR DEC format';
is DSR(6),                             "\e[6n",  'DSR alias';
#
done_testing;
