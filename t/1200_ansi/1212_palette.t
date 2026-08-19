use Test2::V1 -ipP;
use blib;
use Cancer::Ansi qw[set_palette];
#
is set_palette( -1, 255, 0,   0 ),   '',              'set_palette(-1, 255, 0, 0)';
is set_palette(  0, 255, 0,   0 ),   "\e]P0ff0000\a", 'set_palette(0, 255, 0, 0)';
is set_palette(  1, 0,   255, 0 ),   "\e]P100ff00\a", 'set_palette(1, 0, 255, 0)';
is set_palette(  2, 0,   0,   255 ), "\e]P20000ff\a", 'set_palette(2, 0, 0, 255)';
is set_palette(  3, 255, 255, 0 ),   "\e]P3ffff00\a", 'set_palette(3, 255, 255, 0)';
is set_palette(  4, 255, 0,   255 ), "\e]P4ff00ff\a", 'set_palette(4, 255, 0, 255)';
is set_palette(  5, 0,   255, 255 ), "\e]P500ffff\a", 'set_palette(5, 0, 255, 255)';
is set_palette(  6, 192, 192, 192 ), "\e]P6c0c0c0\a", 'set_palette(6, 192, 192, 192)';
is set_palette(  7, 128, 128, 128 ), "\e]P7808080\a", 'set_palette(7, 128, 128, 128)';
is set_palette(  8, 255, 128, 128 ), "\e]P8ff8080\a", 'set_palette(8, 255, 128, 128)';
is set_palette(  9, 128, 255, 128 ), "\e]P980ff80\a", 'set_palette(9, 128, 255, 128)';
is set_palette( 10, 128, 128, 255 ), "\e]Pa8080ff\a", 'set_palette(10, 128, 128, 255)';
is set_palette( 11, 255, 255, 128 ), "\e]Pbffff80\a", 'set_palette(11, 255, 255, 128)';
is set_palette( 12, 255, 128, 255 ), "\e]Pcff80ff\a", 'set_palette(12, 255, 128, 255)';
is set_palette( 13, 128, 255, 255 ), "\e]Pd80ffff\a", 'set_palette(13, 128, 255, 255)';
is set_palette( 14, 192, 192, 192 ), "\e]Pec0c0c0\a", 'set_palette(14, 192, 192, 192)';
is set_palette( 15, 0,   0,   0 ),   "\e]Pf000000\a", 'set_palette(15, 0, 0, 0)';
is set_palette( 16, 255, 0,   0 ),   '',              'set_palette(16, 255, 0, 0)';
#
done_testing;
