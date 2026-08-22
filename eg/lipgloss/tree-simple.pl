use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[Println];
use Cancer::Lipgloss::Tree qw[RootTree NewTree];
my $t = RootTree(".")->Child(
    "macOS",
    NewTree->Root("Linux")->Child( "NixOS", "Arch Linux (btw)", "Void Linux" ),
    NewTree->Root("BSD")->Child( "FreeBSD", "OpenBSD" )
);
Println($t);
