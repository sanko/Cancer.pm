use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# EraseDisplay constants
is EraseScreenBelow,   "\e[J",  'EraseScreenBelow constant';
is EraseScreenAbove,   "\e[1J", 'EraseScreenAbove constant';
is EraseEntireScreen,  "\e[2J", 'EraseEntireScreen constant';
is EraseEntireDisplay, "\e[3J", 'EraseEntireDisplay constant';

# EraseLine constants
is EraseLineRight,  "\e[K",  'EraseLineRight constant';
is EraseLineLeft,   "\e[1K", 'EraseLineLeft constant';
is EraseEntireLine, "\e[2K", 'EraseEntireLine constant';

# Tab constants
is HorizontalTabSet,    "\eH",    'HorizontalTabSet constant';
is SetTabEvery8Columns, "\e[?5W", 'SetTabEvery8Columns constant';

# EraseDisplay / ED
is EraseDisplay,    "\e[J",  'ED default (0)';
is EraseDisplay(0), "\e[J",  'ED(0)';
is EraseDisplay(1), "\e[1J", 'ED(1)';
is EraseDisplay(2), "\e[2J", 'ED(2)';
is EraseDisplay(3), "\e[3J", 'ED(3)';
is ED(2),           "\e[2J", 'ED alias';

# EraseLine / EL
is EraseLine,    "\e[K",  'EL default (0)';
is EraseLine(0), "\e[K",  'EL(0)';
is EraseLine(1), "\e[1K", 'EL(1)';
is EraseLine(2), "\e[2K", 'EL(2)';
is EL(1),        "\e[1K", 'EL alias';

# ScrollUp / SU
is ScrollUp,    "\e[S",  'SU default (1)';
is ScrollUp(1), "\e[S",  'SU(1)';
is ScrollUp(5), "\e[5S", 'SU(5)';
is SU(3),       "\e[3S", 'SU alias';

# ScrollDown / SD
is ScrollDown,    "\e[T",  'SD default (1)';
is ScrollDown(1), "\e[T",  'SD(1)';
is ScrollDown(4), "\e[4T", 'SD(4)';
is SD(2),         "\e[2T", 'SD alias';

# InsertLine / IL
is InsertLine,    "\e[L",  'IL default (1)';
is InsertLine(1), "\e[L",  'IL(1)';
is InsertLine(3), "\e[3L", 'IL(3)';
is IL(2),         "\e[2L", 'IL alias';

# DeleteLine / DL
is DeleteLine,    "\e[M",  'DL default (1)';
is DeleteLine(1), "\e[M",  'DL(1)';
is DeleteLine(6), "\e[6M", 'DL(6)';
is DL(4),         "\e[4M", 'DL alias';

# SetTopBottomMargins / DECSTBM
is SetTopBottomMargins,          "\e[;r",    'DECSTBM default (0,0)';
is SetTopBottomMargins( 1, 24 ), "\e[1;24r", 'DECSTBM(1,24)';
is SetTopBottomMargins( 5, 20 ), "\e[5;20r", 'DECSTBM(5,20)';
is DECSTBM( 2, 22 ),             "\e[2;22r", 'DECSTBM alias';

# SetLeftRightMargins / DECSLRM
is SetLeftRightMargins,          "\e[;s",    'DECSLRM default';
is SetLeftRightMargins( 1, 80 ), "\e[1;80s", 'DECSLRM(1,80)';
is DECSLRM( 5, 75 ),             "\e[5;75s", 'DECSLRM alias';

# InsertCharacter / ICH
is InsertCharacter,    "\e[\@",  'ICH default (1)';
is InsertCharacter(1), "\e[\@",  'ICH(1)';
is InsertCharacter(4), "\e[4\@", 'ICH(4)';
is ICH(3),             "\e[3\@", 'ICH alias';

# DeleteCharacter / DCH
is DeleteCharacter,    "\e[P",  'DCH default (1)';
is DeleteCharacter(1), "\e[P",  'DCH(1)';
is DeleteCharacter(5), "\e[5P", 'DCH(5)';
is DCH(2),             "\e[2P", 'DCH alias';

# TabClear / TBC
is TabClear,    "\e[g",  'TBC default (0)';
is TabClear(0), "\e[g",  'TBC(0)';
is TabClear(3), "\e[3g", 'TBC(3)';
is TBC(1),      "\e[1g", 'TBC alias';

# RequestPresentationStateReport / DECRQPSR
is RequestPresentationStateReport,    "\e[\$w",  'DECRQPSR default (0)';
is RequestPresentationStateReport(1), "\e[1\$w", 'DECRQPSR(1)';
is DECRQPSR(2),                       "\e[2\$w", 'DECRQPSR alias';

# TabStopReport / DECTABSR
is TabStopReport( 8, 16, 24 ), "\eP2\$u8/16/24\e\\", 'DECTABSR(8,16,24)';
is DECTABSR( 40, 80 ),         "\eP2\$u40/80\e\\",   'DECTABSR alias';

# CursorInformationReport / DECCIR
is CursorInformationReport( 1, 2, 3 ), "\eP1\$u1;2;3\e\\", 'DECCIR(1,2,3)';
is DECCIR( 10, 20 ),                   "\eP1\$u10;20\e\\", 'DECCIR alias';

# RepeatPreviousCharacter / REP
is RepeatPreviousCharacter,    "\e[b",  'REP default (1)';
is RepeatPreviousCharacter(1), "\e[b",  'REP(1)';
is RepeatPreviousCharacter(5), "\e[5b", 'REP(5)';
is REP(3),                     "\e[3b", 'REP alias';
#
done_testing;
