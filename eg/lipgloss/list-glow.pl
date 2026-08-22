use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss       qw[NewStyle Color Println];
use Cancer::Lipgloss::List qw[NewList];
my @docs = (
    { name => "README.md",  time => "2 minutes ago" },
    { name => "Example.md", time => "1 hour ago" },
    { name => "secrets.md", time => "1 week ago" }
);
my $selected        = 1;
my $base_style      = NewStyle->margin_bottom(1)->margin_left(1);
my $dim_color       = Color("250");
my $highlight_color = Color("#EE6FF8");
my $faint           = NewStyle->faint(1);
my $l
    = NewList->Enumerator( sub { $selected == $_[1] ? "\x{2502}\n\x{2502}" : " " } )
    ->EnumeratorStyleFunc( sub { NewStyle->foreground( $_[1] == $selected ? $highlight_color : $dim_color ) } )
    ->ItemStyleFunc( sub { $base_style->foreground( $_[1] == $selected    ? $highlight_color : $dim_color ) } );

for my $d (@docs) {
    $l->Item( $d->{name} . "\n" . $faint->render( $d->{time} ) );
}
Println( "\n", $l, "\n" );
