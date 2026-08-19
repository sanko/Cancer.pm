use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Ansi::Kitty qw[
    KittyDisambiguateEscapeCodes KittyReportEventTypes KittyReportAlternateKeys
    KittyReportAllKeysAsEscapeCodes KittyReportAssociatedKeys KittyAllFlags
    RequestKittyKeyboard DisableKittyKeyboard
    KittyKeyboard PushKittyKeyboard PopKittyKeyboard
];

# Kitty keyboard protocol constants
is KittyDisambiguateEscapeCodes,    1,       'KittyDisambiguateEscapeCodes = 1';
is KittyReportEventTypes,           2,       'KittyReportEventTypes = 2';
is KittyReportAlternateKeys,        4,       'KittyReportAlternateKeys = 4';
is KittyReportAllKeysAsEscapeCodes, 8,       'KittyReportAllKeysAsEscapeCodes = 8';
is KittyReportAssociatedKeys,       16,      'KittyReportAssociatedKeys = 16';
is KittyAllFlags,                   31,      'KittyAllFlags = 1|2|4|8|16';
is RequestKittyKeyboard,            "\e[?u", 'RequestKittyKeyboard constant';
is DisableKittyKeyboard,            "\e[>u", 'DisableKittyKeyboard constant';

# KittyKeyboard
is KittyKeyboard( 1,  1 ), "\e[=1;1u",  'KittyKeyboard(1,1) set disambiguate';
is KittyKeyboard( 31, 1 ), "\e[=31;1u", 'KittyKeyboard(31,1) set all';
is KittyKeyboard( 0,  3 ), "\e[=0;3u",  'KittyKeyboard(0,3) unset all';
is KittyKeyboard( 5,  2 ), "\e[=5;2u",  'KittyKeyboard(5,2) set+keep';

# PushKittyKeyboard
is PushKittyKeyboard,     "\e[>u",   'PushKittyKeyboard default (0)';
is PushKittyKeyboard(0),  "\e[>u",   'PushKittyKeyboard(0)';
is PushKittyKeyboard(1),  "\e[>1u",  'PushKittyKeyboard(1) disambiguate';
is PushKittyKeyboard(31), "\e[>31u", 'PushKittyKeyboard(31) all flags';

# PopKittyKeyboard
is PopKittyKeyboard,    "\e[<u",  'PopKittyKeyboard default (0)';
is PopKittyKeyboard(0), "\e[<u",  'PopKittyKeyboard(0)';
is PopKittyKeyboard(1), "\e[<1u", 'PopKittyKeyboard(1)';
is PopKittyKeyboard(3), "\e[<3u", 'PopKittyKeyboard(3)';
#
done_testing;
