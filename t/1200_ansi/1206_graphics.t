use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi graphics_test.go
use Cancer::Ansi qw[/kitty/];
#
is kitty_graphics(''),                         "\e_G\e\\",               'empty payload no options';
is kitty_graphics('test'),                     "\e_G;test\e\\",          'with payload no options';
is kitty_graphics( 'test', 'a=t', 'f=100' ),   "\e_Ga=t,f=100;test\e\\", 'with payload and options';
is kitty_graphics( '', 'q=2', 'C=1', 'f=24' ), "\e_Gq=2,C=1,f=24\e\\",   'multiple options no payload';
is kitty_graphics( "\e_G", 'a=t' ),            "\e_Ga=t;\e_G\e\\",       'with special characters in payload';
#
done_testing;
