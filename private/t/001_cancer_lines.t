use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer;
#
#~ $lines->justify( undef, 20, 'center' );
#~ ddx map { $_->text } $lines->lines;
#~ ddx $lines->justify( undef, 20, 'right' );
#~ ddx map { $_->text } $lines->lines;
#~ ddx $lines->justify( undef, 20, 'full' );
#~ ddx map { $_->text } $lines->lines;
#
isa_ok my $console = Cancer::Console->new(), ['Cancer::Console'], 'setup console';
subtest left => sub {
    my $lines = Cancer::Lines->new();
    $lines->append('Just a test');
    $lines->append('And another test');
    $lines->justify( $console, 5, 'left' );
    is [ map { $_->text } $lines->lines ], [ 'Just…', 'And …' ], 'lines were truncated';
};
subtest right => sub {
    my $lines = Cancer::Lines->new();
    $lines->append('Just a test');
    $lines->append('And another test');
    $lines->justify( $console, 20, 'right' );
    is [ map { $_->text } $lines->lines ], [ '         Just a test', '    And another test' ], 'lines were left justified';
};
subtest center => sub {
    my $lines = Cancer::Lines->new();
    $lines->append('Just a test');
    $lines->append('And another test');
    $lines->justify( $console, 20, 'center' );
    is [ map { $_->text } $lines->lines ], [ '    Just a test     ', '  And another test  ' ], 'lines were centered';
};
subtest full => sub {
    my $lines = Cancer::Lines->new();
    $lines->append('Just a test');
    $lines->append('And another test');
    $lines->justify( $console, 20, 'full' );
    is [ map { $_->text } $lines->lines ], [ '    Just a test     ', '  And another test  ' ], 'lines were centered';
};
#
done_testing;
