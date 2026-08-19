use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi qw[:all];
#
{
    no strict 'subs';

    # Window operation constants
    is ResizeWindowWinOp,      4,  'ResizeWindowWinOp = 4';
    is RequestWindowSizeWinOp, 14, 'RequestWindowSizeWinOp = 14';
    is RequestCellSizeWinOp,   16, 'RequestCellSizeWinOp = 16';
}

# WindowOp / XTWINOPS
is WindowOp(1),              "\e[1t",          'WindowOp(1) deiconify';
is WindowOp(2),              "\e[2t",          'WindowOp(2) iconify';
is WindowOp( 4, 800, 600 ),  "\e[4;800;600t",  'WindowOp(4,800,600) resize';
is WindowOp( 8, 24, 80 ),    "\e[8;24;80t",    'WindowOp(8,24,80) resize chars';
is WindowOp(14),             "\e[14t",         'WindowOp(14) query pixel size';
is WindowOp(16),             "\e[16t",         'WindowOp(16) query cell size';
is WindowOp(0),              '',               'WindowOp(0) returns empty';
is XTWINOPS( 4, 1024, 768 ), "\e[4;1024;768t", 'XTWINOPS alias';
#
done_testing;
