use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[Println];
use Cancer::Lipgloss::List qw[NewList RomanEnumerator];
my $l = NewList->Items( "A", "B", "C", NewList->Items( "D", "E", "F" )->Enumerator( \&RomanEnumerator ), "G" );
Println($l);
