use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::Tree qw[RootTree NewTree];
my $dark_bg           = NewStyle->background( Color("0") )->padding( 0, 1 );
my $header_item_style = NewStyle->background( Color("#ee6ff8") )->foreground( Color("#ecfe65") )->bold(1)->padding( 0, 1 );
my $item_style        = $header_item_style->background( Color("0") );
my $t
    = RootTree("# Table of Contents")
    ->RootStyle($item_style)
    ->ItemStyle($item_style)
    ->EnumeratorStyle($dark_bg)
    ->IndenterStyle($dark_bg)
    ->Child( RootTree("## Chapter 1")->Child( "Chapter 1.1", "Chapter 1.2" ), RootTree("## Chapter 2")->Child( "Chapter 2.1", "Chapter 2.2" ) );
Println($t);
