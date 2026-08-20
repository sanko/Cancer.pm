use v5.42;
use Test2::V1 -ipP;
use experimental 'class';
use lib 'lib';
use blib;
use Cancer::CellBuf::Screen;
use Cancer::CellBuf::Cell;
use Cancer::CellBuf::Style;
use Cancer::CellBuf::Link;
use Cancer::CellBuf::Buffer;
use Cancer::CellBuf::Geom qw[Rect];
#
class    #
    CaptureWriter {
    field $buf : param : reader(contents) //= '';
    method print ($txt) { $buf .= $txt }
    method clear        { $buf = '' }
}

sub make_screen (%args) {
    my $w      = CaptureWriter->new;
    my $screen = Cancer::CellBuf::Screen->new( writer => $w, width => $args{width} // 10, height => $args{height} // 5, opts => $args{opts} // {} );
    return ( $screen, $w );
}
#
my $cell_A = Cancer::CellBuf::Cell->new( rune => ord('A'), width => 1 );
my $cell_B = Cancer::CellBuf::Cell->new( rune => ord('B'), width => 1 );
my $cell_X = Cancer::CellBuf::Cell->new( rune => ord('X'), width => 1 );
#
subtest 'Basic construction' => sub {
    my ( $s, $w ) = make_screen( width => 20, height => 10 );
    is $s->width,  20, 'screen width';
    is $s->height, 10, 'screen height';
};
subtest bounds => sub {
    my ( $s, $w ) = make_screen( width => 10, height => 5 );
    my $b = $s->bounds;
    is $b->min->x, 0,  'bounds min x';
    is $b->min->y, 0,  'bounds min y';
    is $b->max->x, 10, 'bounds max x';
    is $b->max->y, 5,  'bounds max y';
};
subtest 'cell accessor' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 3 );
    my $c = $s->cell( 2, 1 );
    is $c, D(), 'cell accessor returns defined for valid coords';
};
subtest 'set_cell + flush: first render clears then writes cell content' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->set_cell( 0, 0, $cell_A );
    $s->flush;
    my $buf = $w->contents;
    like $buf, qr/A/, 'set_cell + flush writes cell A';
};
subtest 'fill + flush' => sub {
    my ( $s, $w ) = make_screen( width => 4, height => 2 );
    $s->fill($cell_X);
    $s->flush;
    my $buf = $w->contents;
    like $buf, qr/X/, 'fill renders X cells';
};
subtest 'clear + flush' => sub {
    my ( $s, $w ) = make_screen( width => 3, height => 2 );
    $s->fill($cell_A);
    $s->flush;
    $w->clear;
    $s->clear;
    $s->flush;
    is $w->contents, L(), 'clear produces output';
};
subtest '_needs_render: no render when nothing changed' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->flush;
    $w->clear;
    $s->flush;
    is $w->contents, '', 'no render when nothing changed';
};
subtest 'redraw forces full repaint' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->set_cell( 0, 0, $cell_A );
    $s->flush;
    $w->clear;
    $s->redraw;
    $s->flush;
    like $w->contents, qr/A/, 'redraw produces output with A';
};
subtest 'cursor visibility toggle' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->hide_cursor;
    $s->flush;
    like $w->contents, qr/\e\[\?25l/, 'hide_cursor emits CSI ?25l';
    $w->clear;
    $s->show_cursor;
    $s->flush;

    # Render only emits HideCursor, not ShowCursor (matches Go)
    # show_cursor just updates the internal state; ShowCursor is emitted on close()
    # I'm not sure what would even be a valid test at this point
};
subtest 'alt screen mode' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->enter_alt_screen;
    $s->flush;
    like $w->contents, qr/\e\[\?1049h/, 'enter alt screen emits mode set';
    $w->clear;
    $s->exit_alt_screen;
    $s->flush;
    like $w->contents, qr/\e\[\?1049l/, 'exit alt screen emits mode reset';
};
subtest 'resize' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 3 );
    $s->resize( 8, 5 );
    is $s->width,  8, 'resize width';
    is $s->height, 5, 'resize height';
};
subtest insert_above => sub {
    my ( $s, $w ) = make_screen( width => 10, height => 3, opts => { alt_screen => 0 } );
    $s->insert_above("line one");
    $s->flush;
    like $w->contents, qr/line one/, 'insert_above queues text';
};
subtest 'insert_above skipped in alt screen' => sub {
    my ( $s, $w ) = make_screen( width => 10, height => 3, opts => { alt_screen => 1 } );
    $s->enter_alt_screen;
    $s->insert_above('should not appear');
    $s->flush;
    unlike $w->contents, qr/should not appear/, 'insert_above skipped in alt screen';
};
subtest 'close restores state' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->enter_alt_screen;
    $s->hide_cursor;
    $s->flush;
    $w->clear;
    $s->close;
    like $w->contents, qr/\e\[\?1049l/, 'close resets alt screen';
    like $w->contents, qr/\e\[\?25h/,   'close restores cursor';
};
subtest 'Staged rendering: set cells then flush' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->set_cell( 0, 0, $cell_A );
    $s->set_cell( 1, 0, $cell_B );
    $s->flush;
    like $w->contents, qr/A/, 'staged render has A';
    like $w->contents, qr/B/, 'staged render has B';
};
subtest 'Incremental update: flush, change one cell, flush again' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    $s->set_cell( 0, 0, $cell_A );
    $s->flush;
    $w->clear;
    my $cell_C = Cancer::CellBuf::Cell->new( rune => ord('C'), width => 1 );
    $s->set_cell( 2, 1, $cell_C );
    $s->flush;
    like $w->contents, qr/C/, 'incremental render writes C';
};
subtest 'Style rendering: styled cell emits SGR' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 2 );
    my $style = Cancer::CellBuf::Style->new;
    $style->set_bold(1);
    $style->set_fg( { type => 'basic', code => 1 } );
    my $cell = Cancer::CellBuf::Cell->new( rune => ord('S'), width => 1, style => $style );
    $s->set_cell( 0, 0, $cell );
    $s->flush;
    like $w->contents, qr/S/,       'styled cell contains S';
    like $w->contents, qr/\e\[.*m/, 'styled cell emits SGR sequence';
};
subtest 'Hyperlink rendering' => sub {
    my ( $s, $w ) = make_screen( width => 10, height => 2 );
    my $link = Cancer::CellBuf::Link->new( url  => 'https://example.com' );
    my $cell = Cancer::CellBuf::Cell->new( rune => ord('L'), width => 1, link => $link );
    $s->set_cell( 0, 0, $cell );
    $s->flush;
    like $w->contents, qr/L/, 'hyperlink cell contains L';
};
subtest '_hash produces consistent values' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 3 );
    my $blank = Cancer::CellBuf::Cell::BlankCell;
    my $line1 = Cancer::CellBuf::Line->new( ($blank) x 5 );
    my $line2 = Cancer::CellBuf::Line->new( ($blank) x 5 );
    my $h1    = $s->_hash($line1);
    my $h2    = $s->_hash($line2);
    is $h1, $h2, 'identical lines produce same hash';
    my $cell  = Cancer::CellBuf::Cell->new( rune => ord('X'), width => 1 );
    my $line3 = Cancer::CellBuf::Line->new( ($blank) x 2, $cell, ($blank) x 2 );
    my $h3    = $s->_hash($line3);
    isnt $h1, $h3, 'different lines produce different hash';
};
subtest '_touch_line marks lines as touched' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 3 );
    $s->_touch_line( 5, 3, 1, 2, 1 );
    my $touch = $s->touch;
    is exists $touch->{1}, T(), 'touch_line marks line 1';
    is exists $touch->{2}, T(), 'touch_line marks line 2';
    is exists $touch->{0}, F(), 'touch_line does not mark line 0';
};
subtest '_touch_line clears touch' => sub {
    my ( $s, $w ) = make_screen( width => 5, height => 3 );
    $s->_touch_line( 5, 3, 1, 2, 1 );
    my $touch = $s->touch;
    is $touch->{1}, E(), 'touch_line sets touch';
    $s->_touch_line( 5, 3, 1, 2, 0 );
    $touch = $s->touch;
    is $touch->{1}, E(), 'touch_line clears touch';
};
subtest '_cell_equal helper' => sub {
    is Cancer::CellBuf::Screen::_cell_equal( undef,   undef ),   T(), 'both undef is equal';
    is Cancer::CellBuf::Screen::_cell_equal( $cell_A, $cell_A ), T(), 'same cell is equal';
    is Cancer::CellBuf::Screen::_cell_equal( $cell_A, $cell_B ), F(), 'different cells not equal';
};
subtest '_style_equal helper' => sub {
    is Cancer::CellBuf::Screen::_style_equal( undef, undef ),                       T(), 'both undef styles equal';
    is Cancer::CellBuf::Screen::_style_equal( undef, Cancer::CellBuf::Style->new ), F(), 'undef vs new not equal';
    my $s1 = Cancer::CellBuf::Style->new;
    my $s2 = Cancer::CellBuf::Style->new;
    ok Cancer::CellBuf::Screen::_style_equal( $s1, $s2 ), 'empty styles equal';
};
subtest '_link_equal helper' => sub {
    is Cancer::CellBuf::Screen::_link_equal( undef, undef ),                      T(), 'both undef links equal';
    is Cancer::CellBuf::Screen::_link_equal( undef, Cancer::CellBuf::Link->new ), F(), 'undef vs new not equal';
};
subtest '_max / _min' => sub {
    is Cancer::CellBuf::Screen::_max( 3, 5 ), 5, '_max returns larger';
    is Cancer::CellBuf::Screen::_max( 5, 3 ), 5, '_max first arg';
    is Cancer::CellBuf::Screen::_min( 3, 5 ), 3, '_min returns smaller';
    is Cancer::CellBuf::Screen::_min( 5, 3 ), 3, '_min first arg';
};
#
done_testing;
