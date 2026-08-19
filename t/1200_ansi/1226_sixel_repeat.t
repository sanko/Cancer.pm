use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi/sixel/repeat_test.go
use Cancer::Ansi::Sixel qw[Repeat WriteRepeat DecodeRepeat];
subtest WriteRepeat => sub {
    is WriteRepeat( 3,   'A' ), '!3A',   'basic repeat';
    is WriteRepeat( 5,   '#' ), '!5#',   'single digit';
    is WriteRepeat( 123, 'x' ), '!123x', 'multiple digits';
    is WriteRepeat( 0,   'B' ), '!0B',   'zero count';
};
subtest DecodeRepeat => sub {
    my @tests = (
        { name => 'basic repeat', input => '!3A', want_count => 3, want_char => 'A', want_n => 3, description => 'simple single digit repeat' },
        {   name        => 'multiple digits',
            input       => '!123x',
            want_count  => 123,
            want_char   => 'x',
            want_n      => 5,
            description => 'repeat with multiple digits'
        },
        { name => 'empty input', input => '', want_count => 0, want_char => '', want_n => 0, description => 'empty input should return zero values' },
        {   name        => 'invalid introducer',
            input       => 'X3A',
            want_count  => 0,
            want_char   => '',
            want_n      => 0,
            description => 'input without proper introducer'
        },
        {   name        => 'incomplete sequence',
            input       => '!3',
            want_count  => 0,
            want_char   => '',
            want_n      => 0,
            description => 'incomplete sequence without character'
        }
    );
    for my $tt (@tests) {
        subtest $tt->{name} => sub {
            my ( $got_repeat, $got_n ) = DecodeRepeat( $tt->{input} );
            is $got_repeat->Count, $tt->{want_count}, 'Count';
            is $got_repeat->Char,  $tt->{want_char},  'Char';
            is $got_n,             $tt->{want_n},     'read';
        }
    }
};
subtest Repeat => sub {
    is Repeat( 3,   'A' )->String, '!3A',   'basic repeat';
    is Repeat( 123, 'x' )->String, '!123x', 'multiple digits';
    is Repeat( 0,   'B' )->String, '!0B',   'zero count';
};
#
done_testing;
