use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::CellBuf::Cell;
use Cancer::CellBuf::Line;
use Cancer::CellBuf::Buffer;
use Cancer::CellBuf::TabStops;
#
# Test Line
subtest Line => sub {
    my $line = Cancer::CellBuf::Line->new;
    is $line->width, 0, 'empty line width';
    is $line->len,   0, 'empty line len';
    $line = Cancer::CellBuf::Line->new(
        Cancer::CellBuf::Cell->new( rune => 65, width => 1 ),
        Cancer::CellBuf::Cell->new( rune => 66, width => 1 ),
        Cancer::CellBuf::Cell->new( rune => 67, width => 1 )
    );
    is $line->width,  3,     'line width 3';
    is $line->string, 'ABC', 'line string';
    subtest 'at returns BlankCell for nil' => sub {
        my $cell = $line->at(1);
        is $cell,       D(), 'at(1) defined';
        is $cell->rune, 66,  'at(1) is B';
        $cell = $line->at(5);
        is $cell, U(), 'at(5) returns undef for out of bounds';
        $cell = $line->at(-1);
        is $cell, U(), 'at(-1) returns undef';
    };
    subtest 'set cell' => sub {
        my $d = Cancer::CellBuf::Cell->new( rune => 68, width => 1 );
        $line->set( 0, $d );
        is $line->at(0)->rune, 68, 'set cell at 0';
    };
    subtest 'wide character handling' => sub {
        my $wide_line = Cancer::CellBuf::Line->new(
            Cancer::CellBuf::Cell->new( rune => 65, width => 1 ),
            Cancer::CellBuf::Cell->new( rune => 65, width => 1 ),
            Cancer::CellBuf::Cell->new( rune => 65, width => 1 )
        );
        my $wide = Cancer::CellBuf::Cell->new( rune => 0x4E16, width => 2 );
        $wide_line->set( 0, $wide );
        is $wide_line->at(0)->rune, 0x4E16, 'wide char set at 0';
        ok $wide_line->at(1)->empty, 'wide char placeholder at 1 is empty';
    };

    # line with nil cells
    my $nil_line = Cancer::CellBuf::Line->new( undef, Cancer::CellBuf::Cell->new( rune => 65, width => 1 ), undef );
    is $nil_line->string, ' A', 'line with nil cells';
};
#
subtest Buffer => sub {
    subtest raw => sub {    # these will break if I move to classes
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        is $buf->width,  3, 'buffer width';
        is $buf->height, 2, 'buffer height';
        my $b = $buf->bounds;
        is $b->min->x, 0, 'bounds min x';
        is $b->min->y, 0, 'bounds min y';
        is $b->max->x, 3, 'bounds max x';
        is $b->max->y, 2, 'bounds max y';
    };
    subtest 'set cell' => sub {
        my $buf  = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        my $cell = Cancer::CellBuf::Cell->new( rune => 65, width => 1 );
        $buf->set_cell( 1, 1, $cell );
        my $got = $buf->cell( 1, 1 );
        is $got->rune, 65, 'set and get cell';
    };
    subtest 'out of bounds' => sub {
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        my $got = $buf->cell( 5, 5 );
        is $got, U(), 'out of bounds cell is undef';
        $got = $buf->cell( -1, 0 );
        is $got, U(), 'negative cell is undef';
    };
    subtest clear => sub {
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        $buf->set_cell( 0, 0, Cancer::CellBuf::Cell->new( rune => 66, width => 1 ) );
        $buf->set_cell( 1, 0, Cancer::CellBuf::Cell->new( rune => 67, width => 1 ) );
        $buf->clear;
        my $c00 = $buf->cell( 0, 0 );
        ok $c00->equal(Cancer::CellBuf::Cell::BlankCell), 'after clear, cell is BlankCell';
    };
    subtest resize => sub {
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        $buf->resize( 4, 3 );
        is $buf->width,  4, 'resize width';
        is $buf->height, 3, 'resize height';
        $buf->resize( 2, 1 );
        is $buf->width,  2, 'shrink width';
        is $buf->height, 1, 'shrink height';
    };
    subtest string => sub {
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 2 );
        $buf->set_cell( 0, 0, Cancer::CellBuf::Cell->new( rune => 65, width => 1 ) );
        $buf->set_cell( 1, 0, Cancer::CellBuf::Cell->new( rune => 66, width => 1 ) );
        $buf->set_cell( 2, 0, Cancer::CellBuf::Cell->new( rune => 67, width => 1 ) );
        my $str = $buf->string;
        like $str, qr/ABC/, 'buffer string contains ABC';
    };
    subtest 'insert/delete line' => sub {
        my $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 3 );
        $buf->set_cell( 0, 0, Cancer::CellBuf::Cell->new( rune => 65, width => 1 ) );
        $buf->set_cell( 0, 1, Cancer::CellBuf::Cell->new( rune => 66, width => 1 ) );
        $buf->set_cell( 0, 2, Cancer::CellBuf::Cell->new( rune => 67, width => 1 ) );
        $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 4 );
        $buf->set_cell( 0, 0, Cancer::CellBuf::Cell->new( rune => 65, width => 1 ) );
        $buf->set_cell( 0, 1, Cancer::CellBuf::Cell->new( rune => 66, width => 1 ) );
        $buf->set_cell( 0, 2, Cancer::CellBuf::Cell->new( rune => 67, width => 1 ) );
        $buf->insert_line( 1, 1 );
        ok $buf->cell( 0, 1 )->equal(Cancer::CellBuf::Cell::BlankCell), 'insert line clears new line';
        is $buf->cell( 0, 2 )->rune, 66, 'insert line shifted down';
        is $buf->cell( 0, 3 )->rune, 67, 'insert line shifted down 2';
        $buf = Cancer::CellBuf::Buffer->new( width => 3, height => 3 );
        $buf->set_cell( 0, 0, Cancer::CellBuf::Cell->new( rune => 65, width => 1 ) );
        $buf->set_cell( 0, 1, Cancer::CellBuf::Cell->new( rune => 66, width => 1 ) );
        $buf->set_cell( 0, 2, Cancer::CellBuf::Cell->new( rune => 67, width => 1 ) );
        $buf->delete_line( 0, 1 );
        is $buf->cell( 0, 0 )->rune, 66, 'delete line shifted up';
        is $buf->cell( 0, 1 )->rune, 67, 'delete line shifted up 2';
        ok $buf->cell( 0, 2 )->equal(Cancer::CellBuf::Cell::BlankCell), 'delete line cleared bottom';
    }
};
#
subtest TabStops => sub {
    my $tabs = Cancer::CellBuf::TabStops->new( width => 32 );
    subtest is_stop => sub {
        is $tabs->is_stop(0),  T(), 'tab at 0';
        is $tabs->is_stop(8),  T(), 'tab at 8';
        is $tabs->is_stop(16), T(), 'tab at 16';
        is $tabs->is_stop(24), T(), 'tab at 24';
        is $tabs->is_stop(1),  F(), 'not tab at 1';
        is $tabs->is_stop(7),  F(), 'not tab at 7';
        is $tabs->is_stop(9),  F(), 'not tab at 9';
    };
    subtest next => sub {
        is $tabs->next(0),  8,  'next tab from 0';
        is $tabs->next(5),  8,  'next tab from 5';
        is $tabs->next(8),  16, 'next tab from 8';
        is $tabs->next(31), 31, 'next tab from 31 (at boundary)';
    };
    subtest prev => sub {
        is $tabs->prev(8),  0, 'prev tab from 8';
        is $tabs->prev(10), 8, 'prev tab from 10';
        is $tabs->prev(0),  0, 'prev tab from 0 (at boundary)';
    };
    subtest find => sub {
        is $tabs->find( 0,   2 ), 16, 'find 2 tabs from 0';
        is $tabs->find( 16, -2 ), 0,  'find -2 tabs from 16';
        is $tabs->find( 5,   0 ), 5,  'find with delta 0';
    };
    subtest 'custom interval' => sub {
        my $tab4 = Cancer::CellBuf::TabStops->new( width => 32, interval => 4 );
        is $tab4->is_stop(0), T(), 'tab4 at 0';
        is $tab4->is_stop(4), T(), 'tab4 at 4';
        is $tab4->is_stop(8), T(), 'tab4 at 8';
        is $tab4->is_stop(1), F(), 'not tab4 at 1';
        is $tab4->is_stop(5), F(), 'not tab4 at 5';
    };
    subtest 'resize' => sub {
        $tabs = Cancer::CellBuf::TabStops->new( width => 16 );
        is $tabs->is_stop(8), T(), 'tabs at 8 before resize';
        $tabs->resize(32);
        is $tabs->is_stop(8),  T(), 'tabs at 8 after resize';
        is $tabs->is_stop(24), T(), 'tabs at 24 after resize';
    };
    subtest 'set/reset' => sub {
        $tabs->reset(8);
        is $tabs->is_stop(8), F(), 'reset tab at 8';
        $tabs->set(8);
        is $tabs->is_stop(8), T(), 'set tab at 8';
    };
    subtest clear => sub {
        $tabs->clear_stops;
        is $tabs->is_stop(0), F(), 'clear removes all';
        is $tabs->is_stop(8), F(), 'clear removes all 8';
    }
};
#
done_testing;
