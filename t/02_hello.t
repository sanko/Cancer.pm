#!perl
use strict;
use warnings;
use Test2::V0               qw[plan is ok done_testing diag];
use Test2::Tools::Exception qw[dies];
use lib '../lib', 'lib';
END { done_testing(); }
$|++;
use Cancer;
my $term = eval { Cancer->new };
plan skip_all => 'Need interactive stdin, stderr' unless $term;
diag $term->term;
$term->cls;
diag 'clear';
$term->write_at( 5, 4, 'Hello, world!' );

sub out {
    diag 'out';
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
    diag 'render';
    1;
}
ok out( $term, 'Hello, world!' );
