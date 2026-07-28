use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer::Cell;
#
subtest 'cell width' => sub {
    is Cancer::Cell::_is_single_cell_widths('Test'),   T(), '"Test" is all single width cells';
    is Cancer::Cell::_is_single_cell_widths('नमस्ते'), F(), '"नमस्ते" contains wide cells';
    is Cancer::Cell::_is_single_cell_widths('😽'),      T(), '"😽" is all single width cells';
    #
    is Cancer::Cell::cell_len('Test'),   4, '"Test" if 4 columns wide';
    is Cancer::Cell::cell_len('नमस्ते'), 4, '"नमस्ते" if 4 columns wide';
    is Cancer::Cell::cell_len('😽'),      1, '😽 is one column';
};
subtest 'set cell size' => sub {

    # Test single-cell width strings
    is Cancer::Cell::set_cell_size( 'abc',     5 ), 'abc  ', 'Single-cell width, pad';
    is Cancer::Cell::set_cell_size( 'abcdefg', 3 ), 'abc',   'Single-cell width, truncate';

    # Test double-width characters
    is Cancer::Cell::set_cell_size( 'あいうえお', 3 ), 'あいう',    'Double-width characters, truncate';
    is Cancer::Cell::set_cell_size( 'あいうえ ', 5 ), 'あいうえ ',  'Double-width characters, exact fit';
    is Cancer::Cell::set_cell_size( 'あいうえお', 6 ), 'あいうえお ', 'Double-width characters, pad';

    # Test edge cases
    is Cancer::Cell::set_cell_size( 'abc',    0 ), '', 'Zero cell size';
    is Cancer::Cell::set_cell_size( 'あいうえお', -1 ), '', 'Negative cell size';

    # Test binary search
    is Cancer::Cell::set_cell_size( 'あいうえおかきくけこ',      8 ),  'あいうえおかきく',   'Binary search, truncate and pad';
    is Cancer::Cell::set_cell_size( 'あいうえおかきくけこさしすせそ', 10 ), 'あいうえおかきくけこ', 'Binary search, truncate';
};
subtest 'chop_cells' => sub {
    is Cancer::Cell::chop_cells( 'abcdefghij', 3 ), [ 'abc', 'def', 'ghi', 'j' ], 'Basic chopping';
    is Cancer::Cell::chop_cells( '',           3 ), [''],                         'Empty string';
    is Cancer::Cell::chop_cells( 'abcdefghij', 1 ), [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j' ], 'Single-character lines';
    is Cancer::Cell::chop_cells( 'supercalifragilisticexpialidocious', 5 ), [ 'super', 'calif', 'ragil', 'istic', 'expia', 'lidoc', 'ious' ],
        'Long words';
    is Cancer::Cell::chop_cells( 'あいうえおかきくけこさしすせそ', 3 ), [ 'あいう', 'えおか', 'きくけ', 'こさし', 'すせそ' ], 'Mixed characters';
};
for ( 1 .. 32, -1 ) {
    diag Cancer::Cell::set_cell_size( "这是对亚洲语言支持的测试。面对模棱两可的想法，拒绝猜测的诱惑。", $_ ) . '|';
}
#
done_testing;
