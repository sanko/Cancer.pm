use v5.42;
use lib 'lib';
use blib;
use utf8;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss        qw[NewStyle Color Println NormalBorder JoinHorizontal JoinVertical Center Right];
use Cancer::Lipgloss::Table qw[NewTable];
my $label_style = NewStyle->foreground( Color("241") );
my @board       = (
    [ "♜", "♞", "♝", "♛", "♚", "♝", "♞", "♜" ],
    [ "♟", "♟", "♟", "♟", "♟", "♟", "♟", "♟" ],
    [ " ", " ", " ", " ", " ", " ", " ", " " ],
    [ " ", " ", " ", " ", " ", " ", " ", " " ],
    [ " ", " ", " ", " ", " ", " ", " ", " " ],
    [ " ", " ", " ", " ", " ", " ", " ", " " ],
    [ "♙", "♙", "♙", "♙", "♙", "♙", "♙", "♙" ],
    [ "♖", "♘", "♗", "♕", "♔", "♗", "♘", "♖" ]
);
my $t     = NewTable->Border(NormalBorder)->BorderRow(1)->BorderColumn(1)->Rows(@board)->StyleFunc( sub { NewStyle->padding( 0, 1 ) } );
my $ranks = $label_style->render( join( "   ",   " A", "B", "C", "D", "E", "F", "G", "H  " ) );
my $files = $label_style->render( join( "\n\n ", " 1", "2", "3", "4", "5", "6", "7", "8 " ) );
Println( JoinVertical( Right, JoinHorizontal( Center, $files, $t->String ), $ranks ) . "\n" );
