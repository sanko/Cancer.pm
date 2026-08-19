use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];

# Cursor constants
is SaveCursor,                     "\e7",    'SaveCursor constant';
is DECSC,                          "\e7",    'DECSC alias';
is RestoreCursor,                  "\e8",    'RestoreCursor constant';
is DECRC,                          "\e8",    'DECRC alias';
is CUU1,                           "\e[A",   'CUU1 constant';
is CUD1,                           "\e[B",   'CUD1 constant';
is CUF1,                           "\e[C",   'CUF1 constant';
is CUB1,                           "\e[D",   'CUB1 constant';
is CursorHomePosition,             "\e[H",   'CursorHomePosition constant';
is HorizontalVerticalHomePosition, "\e[f",   'HorizontalVerticalHomePosition constant';
is SaveCurrentCursorPosition,      "\e[s",   'SaveCurrentCursorPosition constant';
is SCOSC,                          "\e[s",   'SCOSC alias';
is RestoreCurrentCursorPosition,   "\e[u",   'RestoreCurrentCursorPosition constant';
is SCORC,                          "\e[u",   'SCORC alias';
is ReverseIndex,                   "\eM",    'ReverseIndex constant';
is Index,                          "\eD",    'Index constant';
is RequestCursorPosition,          "\e[6n",  'RequestCursorPosition constant';
is RequestExtendedCursorPosition,  "\e[?6n", 'RequestExtendedCursorPosition constant';

# CursorUp / CUU
is CursorUp,    "\e[A",  'CursorUp default (1)';
is CursorUp(1), "\e[A",  'CursorUp(1)';
is CursorUp(5), "\e[5A", 'CursorUp(5)';
is CUU(3),      "\e[3A", 'CUU alias';

# CursorDown / CUD
is CursorDown,    "\e[B",  'CursorDown default';
is CursorDown(4), "\e[4B", 'CursorDown(4)';
is CUD(2),        "\e[2B", 'CUD alias';

# CursorForward / CUF
is CursorForward,    "\e[C",  'CursorForward default';
is CursorForward(7), "\e[7C", 'CursorForward(7)';
is CUF(3),           "\e[3C", 'CUF alias';

# CursorBackward / CUB
is CursorBackward,     "\e[D",   'CursorBackward default';
is CursorBackward(10), "\e[10D", 'CursorBackward(10)';
is CUB(6),             "\e[6D",  'CUB alias';

# CursorNextLine / CNL
is CursorNextLine,    "\e[E",  'CursorNextLine default';
is CursorNextLine(3), "\e[3E", 'CursorNextLine(3)';
is CNL(2),            "\e[2E", 'CNL alias';

# CursorPreviousLine / CPL
is CursorPreviousLine,    "\e[F",  'CursorPreviousLine default';
is CursorPreviousLine(2), "\e[2F", 'CursorPreviousLine(2)';
is CPL(4),                "\e[4F", 'CPL alias';

# CursorHorizontalAbsolute / CHA
is CursorHorizontalAbsolute,     "\e[1G",  'CHA default (col=1)';
is CursorHorizontalAbsolute(10), "\e[10G", 'CHA(10)';
is CHA(5),                       "\e[5G",  'CHA alias';

# CursorPosition / CUP
is CursorPosition,           "\e[H",      'CUP default (1,1) = home';
is CursorPosition( 1, 1 ),   "\e[H",      'CUP(1,1) = home';
is CursorPosition( 5, 10 ),  "\e[10;5H",  'CUP(5,10)';
is CursorPosition( 80, 24 ), "\e[24;80H", 'CUP(80,24)';
is CUP( 3, 7 ),              "\e[7;3H",   'CUP alias';

# CursorHorizontalForwardTab / CHT
is CursorHorizontalForwardTab,    "\e[I",  'CHT default';
is CursorHorizontalForwardTab(3), "\e[3I", 'CHT(3)';
is CHT(2),                        "\e[2I", 'CHT alias';

# EraseCharacter / ECH
is EraseCharacter,    "\e[X",  'ECH default';
is EraseCharacter(5), "\e[5X", 'ECH(5)';
is ECH(3),            "\e[3X", 'ECH alias';

# CursorBackwardTab / CBT
is CursorBackwardTab,    "\e[Z",  'CBT default';
is CursorBackwardTab(2), "\e[2Z", 'CBT(2)';
is CBT(4),               "\e[4Z", 'CBT alias';

# VerticalPositionAbsolute / VPA
is VerticalPositionAbsolute,     "\e[1d",  'VPA default';
is VerticalPositionAbsolute(15), "\e[15d", 'VPA(15)';
is VPA(20),                      "\e[20d", 'VPA alias';

# VerticalPositionRelative / VPR
is VerticalPositionRelative,    "\e[e",  'VPR default';
is VerticalPositionRelative(3), "\e[3e", 'VPR(3)';
is VPR(5),                      "\e[5e", 'VPR alias';

# HorizontalVerticalPosition / HVP
is HorizontalVerticalPosition,           "\e[1;1f",   'HVP default (1,1)';
is HorizontalVerticalPosition( 10, 20 ), "\e[20;10f", 'HVP(10,20)';
is HVP( 5, 8 ),                          "\e[8;5f",   'HVP alias';

# SetCursorStyle / DECSCUSR
is SetCursorStyle,     "\e[1 q", 'SetCursorStyle default';
is SetCursorStyle( 0), "\e[0 q", 'SetCursorStyle(0) blinking block';
is SetCursorStyle( 2), "\e[2 q", 'SetCursorStyle(2) steady block';
is SetCursorStyle( 3), "\e[3 q", 'SetCursorStyle(3) blinking underline';
is SetCursorStyle( 6), "\e[6 q", 'SetCursorStyle(6) steady bar';
is SetCursorStyle(-1), "\e[0 q", 'SetCursorStyle negative clamps to 0';
is DECSCUSR(4),        "\e[4 q", 'DECSCUSR alias';

# SetPointerShape
is SetPointerShape("default"),   "\e]22;default\a",   'SetPointerShape default';
is SetPointerShape("crosshair"), "\e]22;crosshair\a", 'SetPointerShape crosshair';

# HorizontalPositionAbsolute / HPA
is HorizontalPositionAbsolute,     "\e[1`",  'HPA default';
is HorizontalPositionAbsolute(40), "\e[40`", 'HPA(40)';
is HPA(10),                        "\e[10`", 'HPA alias';

# HorizontalPositionRelative / HPR
is HorizontalPositionRelative,    "\e[1a", 'HPR default';
is HorizontalPositionRelative(5), "\e[5a", 'HPR(5)';
is HPR(3),                        "\e[3a", 'HPR alias';
#
done_testing;
