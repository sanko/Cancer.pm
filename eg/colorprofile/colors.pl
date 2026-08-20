use v5.42;
use lib '../../lib';
use Cancer::Ansi qw[NewStyle ansi_to_rgb];
#
sub print_block ( $idx, $fg ) {
    my ( $r, $g, $b ) = ansi_to_rgb($idx);
    my $hex   = sprintf( '#%02X%02X%02X', $r, $g, $b );
    my $block = NewStyle()->background_color($idx)->foreground_color($fg);
    my $fmt   = $idx < 16 ? ' %2d  %s ' : ' %3d  %s ';
    print $block->styled( sprintf $fmt, $idx, $hex );
}
#
say NewStyle()->bold->styled('Basic ANSI colors');
for my $i ( 0 .. 15 ) {
    my $fg = $i == 0 ? 15 : 0;
    print_block( $i, $fg );
    print "\n" if $i == 7;
}
print "\n\n";
say NewStyle()->bold->styled('256 ANSI colors');
for my $i ( 16 .. 231 ) {
    print_block( $i, 0 );
    print "\n" if ( $i - 15 ) % 6 == 0;
}
print "\n\n";
say NewStyle()->bold->styled('256 ANSI grayscale colors');
for my $i ( 232 .. 255 ) {
    print_block( $i, 15 );
    print "\n" if ( $i - 231 ) % 6 == 0;
}
print "\n";
