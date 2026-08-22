use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss        qw[NewStyle Color Println HiddenBorder];
use Cancer::Lipgloss::Table qw[NewTable];
my $label_style  = NewStyle->width(3)->align(1);
my $swatch_style = NewStyle->width(6);

sub make_row {
    my ( $start, $end ) = @_;
    my @row;
    for my $i ( $start .. $end ) {
        push @row, "$i", "";
    }
    push @row, "" while @row < 12;
    return \@row;
}
my @data;
for my $i ( 0, 8 ) { push @data, make_row( $i, $i + 5 ) }
push @data, make_row( 0, -1 );
for my $i ( 6, 14 ) { push @data, make_row( $i, $i + 1 ) }
push @data, make_row( 16, 15 );
for my $i ( map { 16 + $_ * 6 } 0 .. 35 ) {
    last if $i >= 231;
    push @data, make_row( $i, $i + 5 );
}
push @data, make_row( 0, -1 );
for my $i ( map { 232 + $_ * 6 } 0 .. 3 ) {
    last if $i >= 256;
    push @data, make_row( $i, $i + 5 );
}
my $t = NewTable->Border(HiddenBorder)->Rows(@data)->StyleFunc(
    sub {
        my ( $row, $col ) = @_;
        my $color = Color( $data[$row][ $col - $col % 2 ] );
        $col % 2 == 0 ? $label_style->foreground($color) : $swatch_style->background($color);
    }
);
Println($t);
