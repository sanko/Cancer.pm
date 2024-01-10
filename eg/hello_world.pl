use strict;
use warnings;
use Data::Dump;
use lib '../lib';
#
use Cancer;
use Cancer::terminfo::xterm::256color;
#
my $term = Cancer->new;
ddx $term->get_win_size;
$term->cls(1);

#$term->write_at( 5, 4, 'Hello, world!' );
sub out {
    my ( $s, $string ) = @_;    # Red and blinking
    my $fg = 0xE6E6FA;
    my $bg = 0xEE82EE;
    $s->front_buffer->data( $s->front_buffer->data . "\e[38;2;" );
    $s->front_buffer->data( $s->front_buffer->data . ( $fg >> 16 & 0xFF ) );    # fg R
    $s->front_buffer->data( $s->front_buffer->data . ';' );
    $s->front_buffer->data( $s->front_buffer->data . ( $fg >> 8 & 0xFF ) );     # fg G
    $s->front_buffer->data( $s->front_buffer->data . ';' );
    $s->front_buffer->data( $s->front_buffer->data . ( $fg & 0xFF ) );          # fg B
    $s->front_buffer->data( $s->front_buffer->data . 'm' );
    $s->front_buffer->data( $s->front_buffer->data . "\e[48;2;" );
    $s->front_buffer->data( $s->front_buffer->data . ( $bg >> 16 & 0xFF ) );    # bg R
    $s->front_buffer->data( $s->front_buffer->data . ';' );
    $s->front_buffer->data( $s->front_buffer->data . ( $bg >> 8 & 0xFF ) );     # bg B
    $s->front_buffer->data( $s->front_buffer->data . ';' );
    $s->front_buffer->data( $s->front_buffer->data . ( $bg & 0xFF ) );          #bg G

    #$s->front_buffer->data( $s->front_buffer->data .  '')
    #$s->front_buffer->data( $s->front_buffer->data .  );
    #$s->front_buffer->data( $s->front_buffer->data .  );
    #$s->front_buffer->data( $s->front_buffer->data .  );
    #	// write RGB color to buffer
    #WRITE_INT(fg >> 8 & 0xFF);  // fg G
    #WRITE_LITERAL(";");
    #WRITE_INT(fg & 0xFF);       // fg B
    #WRITE_LITERAL(";48;2;");
    #WRITE_INT(bg >> 16 & 0xFF); // bg R
    #WRITE_LITERAL(";");
    #WRITE_INT(bg >> 8 & 0xFF);  // bg G
    #WRITE_LITERAL(";");
    #WRITE_INT(bg & 0xFF);       // bg B
    $s->front_buffer->data( $s->front_buffer->data . 'm' . $string . "\033[25;0m\n" );
    $s->render;
}
out( $term, 'Hello, world!' );
my $live = 10;
while ($live) {
    sleep 1;
    use Data::Dump;
    my $data = $term->read(100);
    next if !$data;
    ddx $data;
    $live--;
}
