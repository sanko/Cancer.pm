use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::CellBuf::Geom qw[Pos Rect];
use Cancer::CellBuf::Style;
use Cancer::CellBuf::Link;
use Cancer::CellBuf::Cell;
#
# This subtest will fail if I ever switch to classes
subtest Geom => sub {
    my $p = Pos( 3, 5 );
    is $p->x, 3, 'Pos x';
    is $p->y, 5, 'Pos y';
    my $r = Rect( 1, 2, 10, 20 );
    is $r->min->x, 1,  'Rect min x';
    is $r->min->y, 2,  'Rect min y';
    is $r->max->x, 11, 'Rect max x';
    is $r->max->y, 22, 'Rect max y';
};
#
subtest Style => sub {
    my $style = Cancer::CellBuf::Style->new;
    is $style->empty, T(), 'new style is empty';
    is $style->clear, T(), 'new style is clear';
    $style->set_bold(1);
    is $style->contains(Cancer::CellBuf::Style::BOLD_ATTR), T(), 'style contains bold';
    is $style->empty,                                       F(), 'style with bold is not empty';
    my $seq = $style->sequence;
    like $seq, qr/\e\[1m/, 'bold sequence';
    $style->set_bold(0);
    is $style->empty, T(), 'style after unbold is empty';

    # test colors
    my $fg = Cancer::CellBuf::Style->new( fg => { type => 'basic', code => 1 } );
    is $fg->empty, F(), 'style with fg is not empty';
    like $fg->sequence, qr/\e\[31m/, 'red foreground sequence';

    # test diff
    my $old = Cancer::CellBuf::Style->new;
    my $new = Cancer::CellBuf::Style->new( fg => { type => 'basic', code => 1 } );
    like $new->diff_sequence($old), qr/\e\[31m/, 'diff adds red fg';

    # test equal
    my $s2 = Cancer::CellBuf::Style->new( fg => { type => 'basic', code => 1 } );
    is $fg->equal($s2),  T(), 'equal styles';
    is $fg->equal($old), F(), 'unequal styles';
};
#
subtest Link => sub {
    my $link = Cancer::CellBuf::Link->new;
    ok $link->empty, 'new link is empty';
    $link = Cancer::CellBuf::Link->new( url => 'https://example.com', params => 'id=1' );
    ok !$link->empty, 'link with url is not empty';
    is $link->url,    'https://example.com', 'link url';
    is $link->params, 'id=1',                'link params';
    my $l2 = Cancer::CellBuf::Link->new( url => 'https://example.com', params => 'id=1' );
    ok $link->equal($l2), 'equal links';
    $l2 = Cancer::CellBuf::Link->new( url => 'https://other.com' );
    is $link->equal($l2), F(), 'unequal links';
    $link->reset;
    is $link->empty, T(), 'link reset';
};
#
subtest Cell => sub {
    my $cell = Cancer::CellBuf::Cell->new;
    ok $cell->empty, 'new cell is empty';
    is $cell->width, 0, 'empty cell width';
    $cell = Cancer::CellBuf::Cell->new( rune => 65, width => 1 );
    is $cell->empty,  F(), 'cell with content is not empty';
    is $cell->rune,   65,  'cell rune';
    is $cell->width,  1,   'cell width';
    is $cell->string, 'A', 'cell string';
    my $blank = Cancer::CellBuf::Cell::BlankCell;
    is $blank->rune,  32, 'blank cell is space';
    is $blank->width, 1,  'blank cell width 1';
    my $c2 = Cancer::CellBuf::Cell->new( rune => 65, width => 1 );
    ok $cell->equal($c2), 'equal cells';
    $c2 = Cancer::CellBuf::Cell->new( rune => 66, width => 1 );
    ok !$cell->equal($c2), 'different rune cells';
    my $c3 = $cell->clone;
    ok $cell->equal($c3), 'cloned cell equal';
    my $wide = Cancer::CellBuf::Cell->new( rune => 0x4E16, width => 2 );
    is $wide->width, 2, 'wide cell width';
    my $comb = Cancer::CellBuf::Cell->new( rune => 101, width => 1 );
    $comb->append(0x0301);
    is $comb->string, "e\x{0301}", 'cell with combining mark';
};
#
done_testing;
