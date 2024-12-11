use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer;
#
subtest LRU => sub {
    isa_ok my $cache = Cancer::LRU->new( capacity => 3 ), ['Cancer::LRU'];
    subtest 'set/get' => sub {
        ok $cache->set( 'a', 1 ), 'set a';
        ok $cache->set( 'b', 2 ), 'set b';
        is $cache->get('a'), 1,   'get a';
        is $cache->get('q'), U(), 'get q (undef)';
    };
    subtest eviction => sub {
        ok $cache->set( 'c', 3 ), 'set c';
        ok $cache->set( 'd', 4 ), 'set d';
        is $cache->get('b'), U(), 'b was evicted due to capacity';
        is $cache->get('c'), 3,   'c was still around';
    };
    subtest update => sub {
        ok $cache->set( 'a', 5 ), 'set a (again)';
        is $cache->get('a'), 5, 'a was updated';
    };
    subtest 'del/clear' => sub {
        ok $cache->set( 'e', 6 ), 'set e';
        ok $cache->set( 'f', 7 ), 'set f';
        ok $cache->set( 'g', 8 ), 'set g';
        is $cache->get('g'), 8, 'get g';
        ok $cache->del('g'), 'del g';
        is $cache->get('g'), U(), 'g was removed by request';
        is $cache->get('f'), 7,   'get f';
        ok $cache->clear, 'clear lru';
        is $cache->get('e'), U(), 'e was cleared';
        is $cache->get('f'), U(), 'f was cleared';
    };
};
#
done_testing;
