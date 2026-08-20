use v5.42;
use Test2::V1 -ipP;
use blib;
use lib 'lib';
use Cancer::ColorProfile qw[:all];
#
subtest 'Profile constants' => sub {
    is Unknown,   0, 'Unknown is 0';
    is NoTTY,     1, 'NoTTY is 1';
    is ASCII,     2, 'ASCII is 2';
    is ANSI,      3, 'ANSI is 3';
    is ANSI256,   4, 'ANSI256 is 4';
    is TrueColor, 5, 'TrueColor is 5';
};
subtest 'Profile string' => sub {
    is Cancer::ColorProfile::Profile_String(TrueColor), 'TrueColor', 'TrueColor string';
    is Cancer::ColorProfile::Profile_String(ANSI256),   'ANSI256',   'ANSI256 string';
    is Cancer::ColorProfile::Profile_String(ANSI),      'ANSI',      'ANSI string';
    is Cancer::ColorProfile::Profile_String(ASCII),     'Ascii',     'ASCII string';
    is Cancer::ColorProfile::Profile_String(NoTTY),     'NoTTY',     'NoTTY string';
    is Cancer::ColorProfile::Profile_String(Unknown),   'Unknown',   'Unknown string';
};
#
my $red_basic = { type => 'basic', code  => 1 };
my $idx256    = { type => '256',   index => 196 };
my $rgb       = { type => 'rgb',   r     => 255, g => 0, b => 0 };
my $c256      = Cancer::ColorProfile::Convert( ANSI256, $rgb );
#
subtest 'Convert: basic colors pass through all profiles' => sub {
    is Cancer::ColorProfile::Convert( TrueColor, $red_basic ), $red_basic, 'basic passes through TrueColor';
    is Cancer::ColorProfile::Convert( ANSI256,   $red_basic ), $red_basic, 'basic passes through ANSI256';
    is Cancer::ColorProfile::Convert( ANSI,      $red_basic ), $red_basic, 'basic passes through ANSI';
};
subtest 'Convert: basic colors become undef for ASCII and NoTTY' => sub {
    is Cancer::ColorProfile::Convert( ASCII, $red_basic ), undef, 'basic is undef for ASCII';
    is Cancer::ColorProfile::Convert( NoTTY, $red_basic ), undef, 'basic is undef for NoTTY';
};
subtest 'Convert: 256 color passthrough for ANSI256' => sub {
    is Cancer::ColorProfile::Convert( ANSI256, $idx256 ), $idx256, '256 passes through ANSI256';
};
subtest 'Convert: 256 to 16 for ANSI' => sub {
    my $converted = Cancer::ColorProfile::Convert( ANSI, $idx256 );
    is ref $converted,     'HASH',  '256 to 16 returns hashref';
    is $converted->{type}, 'basic', '256 to 16 type is basic';
    ok $converted->{code} >= 0 && $converted->{code} <= 15, '256 to 16 code in range';
};
subtest 'Convert: RGB to 256' => sub {
    is ref $c256,     'HASH', 'RGB to 256 returns hashref';
    is $c256->{type}, '256',  'RGB to 256 type is 256';
    ok $c256->{index} >= 0 && $c256->{index} <= 255, 'RGB to 256 index in range';
};
is( $c256->{index}, 196, 'red RGB maps to 256 index 196' );
subtest 'Convert: RGB to 16 via ANSI' => sub {
    my $c16 = Cancer::ColorProfile::Convert( ANSI, $rgb );
    is $c16->{type}, 'basic', 'RGB to 16 type is basic';
    is $c16->{code}, 9,       'red RGB maps to basic 9 (bright red)';
};
is( Cancer::ColorProfile::Convert( TrueColor, $rgb ), $rgb, 'RGB passes through TrueColor' );
subtest 'Convert: RGB is undef for ASCII/NoTTY' => sub {
    is Cancer::ColorProfile::Convert( ASCII, $rgb ), undef, 'RGB is undef for ASCII';
    is Cancer::ColorProfile::Convert( NoTTY, $rgb ), undef, 'RGB is undef for NoTTY';
};
subtest 'Convert: green' => sub {
    my $green_rgb = { type => 'rgb', r => 0, g => 255, b => 0 };
    my $green_256 = Cancer::ColorProfile::Convert( ANSI256, $green_rgb );
    is $green_256->{index}, 46, 'green RGB maps to 256 index 46';
    my $green_16 = Cancer::ColorProfile::Convert( ANSI, $green_rgb );
    is $green_16->{code}, 10, 'green RGB maps to basic 10 (bright green)';
};
subtest 'Convert: blue' => sub {
    my $blue_rgb = { type => 'rgb', r => 0, g => 0, b => 255 };
    my $blue_256 = Cancer::ColorProfile::Convert( ANSI256, $blue_rgb );
    is $blue_256->{index}, 21, 'blue RGB maps to 256 index 21';
    my $blue_16 = Cancer::ColorProfile::Convert( ANSI, $blue_rgb );
    is $blue_16->{code}, 12, 'blue RGB maps to basic 12 (bright blue)';
};
subtest 'Convert: white' => sub {
    my $white_rgb = { type => 'rgb', r => 255, g => 255, b => 255 };
    my $white_256 = Cancer::ColorProfile::Convert( ANSI256, $white_rgb );
    is $white_256->{index}, 231, 'white RGB maps to 256 index 231';
    my $white_16 = Cancer::ColorProfile::Convert( ANSI, $white_rgb );
    is $white_16->{code}, 15, 'white RGB maps to basic 15 (bright white)';
};
subtest 'Convert: grey' => sub {
    my $grey_rgb = { type => 'rgb', r => 128, g => 128, b => 128 };
    my $grey_256 = Cancer::ColorProfile::Convert( ANSI256, $grey_rgb );
    is $grey_256->{index}, 244, 'grey RGB maps to 256 index 244';
};
subtest 'Convert: caching works' => sub {
    my $c1 = Cancer::ColorProfile::Convert( ANSI256, $rgb );
    my $c2 = Cancer::ColorProfile::Convert( ANSI256, $rgb );
    is $c1, $c2, 'cached conversion returns same reference';
};
subtest 'Env detection' => sub {
    is Cancer::ColorProfile::Env( { TERM => 'xterm-256color' } ),                     ANSI256,   'TERM=xterm-256color => ANSI256';
    is Cancer::ColorProfile::Env( { TERM => 'xterm' } ),                              ANSI,      'TERM=xterm => ANSI';
    is Cancer::ColorProfile::Env( { TERM => 'dumb' } ),                               NoTTY,     'TERM=dumb => NoTTY';
    is Cancer::ColorProfile::Env( { TERM => 'rio' } ),                                TrueColor, 'TERM=rio => TrueColor';
    is Cancer::ColorProfile::Env( { TERM => 'xterm-256color', NO_COLOR => '1' } ),    ASCII,     'NO_COLOR=1 overrides to ASCII';
    is Cancer::ColorProfile::Env( { TERM => 'xterm-256color', COLORTERM => 'yes' } ), TrueColor, 'COLORTERM=yes upgrades to TrueColor';
    is Cancer::ColorProfile::Env( { TERM => 'screen' } ),                             ANSI256,   'TERM=screen => ANSI256';
    is Cancer::ColorProfile::Env( { TERM => 'tmux-256color' } ),                      ANSI256,   'TERM=tmux-256color => ANSI256';
    is Cancer::ColorProfile::Env( { TERM => 'xterm-direct' } ),                       TrueColor, 'TERM=xterm-direct => TrueColor';
    is Cancer::ColorProfile::Env( { TERM => 'alacritty' } ),                          TrueColor, 'TERM=alacritty => TrueColor';
    is Cancer::ColorProfile::Env( { TERM => 'ghostty' } ),                            TrueColor, 'TERM=ghostty => TrueColor';
    is Cancer::ColorProfile::Env( { WT_SESSION => '1' } ), ( $^O eq 'MSWin32' ? TrueColor : NoTTY ), 'WT_SESSION detection is platform-aware';
    is Cancer::ColorProfile::Env( {} ), ( $^O eq 'MSWin32' ? TrueColor : NoTTY ), 'empty env detects platform correctly';
};
subtest 'env_no_color, cli_color, cli_color_forced' => sub {
    is Cancer::ColorProfile::env_no_color( { NO_COLOR => '1' } ),           T(), 'NO_COLOR=1 is no_color';
    is Cancer::ColorProfile::env_no_color( { NO_COLOR => 'true' } ),        T(), 'NO_COLOR=true is no_color';
    is Cancer::ColorProfile::env_no_color( {} ),                            F(), 'empty is not no_color';
    is Cancer::ColorProfile::env_no_color( { NO_COLOR => '0' } ),           F(), 'NO_COLOR=0 is not no_color';
    is Cancer::ColorProfile::cli_color( { CLICOLOR => '1' } ),              T(), 'CLICOLOR=1 is cli_color';
    is Cancer::ColorProfile::cli_color( {} ),                               F(), 'empty is not cli_color';
    is Cancer::ColorProfile::cli_color_forced( { CLICOLOR_FORCE => '1' } ), T(), 'CLICOLOR_FORCE=1';
    is Cancer::ColorProfile::cli_color_forced( {} ),                        F(), 'empty is not cli_color_forced';
};
#
done_testing;
