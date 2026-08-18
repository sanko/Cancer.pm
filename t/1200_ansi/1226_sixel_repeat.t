use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/sixel/repeat_test.go
use Cancer::Ansi::Sixel qw(
    Repeat WriteRepeat DecodeRepeat
);
subtest 'TestWriteRepeat' => sub {
    my @tests = (
        { name => 'basic repeat',    count => 3,   char => 'A', expected => '!3A', },
        { name => 'single digit',    count => 5,   char => '#', expected => '!5#', },
        { name => 'multiple digits', count => 123, char => 'x', expected => '!123x', },
        { name => 'zero count',      count => 0,   char => 'B', expected => '!0B', },
    );
    for my $tt (@tests) {
        my $got = WriteRepeat( $tt->{count}, $tt->{char} );
        is $got, $tt->{expected}, $tt->{name};
    }
};
subtest 'TestDecodeRepeat' => sub {
    my @tests = (
        { name => 'basic repeat', input => '!3A', want_count => 3, want_char => 'A', want_n => 3, description => 'simple single digit repeat', },
        {   name        => 'multiple digits',
            input       => '!123x',
            want_count  => 123,
            want_char   => 'x',
            want_n      => 5,
            description => 'repeat with multiple digits',
        },
        {   name        => 'empty input',
            input       => '',
            want_count  => 0,
            want_char   => '',
            want_n      => 0,
            description => 'empty input should return zero values',
        },
        {   name        => 'invalid introducer',
            input       => 'X3A',
            want_count  => 0,
            want_char   => '',
            want_n      => 0,
            description => 'input without proper introducer',
        },
        {   name        => 'incomplete sequence',
            input       => '!3',
            want_count  => 0,
            want_char   => '',
            want_n      => 0,
            description => 'incomplete sequence without character',
        },
    );
    for my $tt (@tests) {
        my ( $got_repeat, $got_n ) = DecodeRepeat( $tt->{input} );
        is $got_repeat->Count, $tt->{want_count}, "$tt->{name} Count";
        is $got_repeat->Char,  $tt->{want_char},  "$tt->{name} Char";
        is $got_n,             $tt->{want_n},     "$tt->{name} read";
    }
};
subtest 'TestRepeat_String' => sub {
    my @tests = (
        { name => 'basic repeat',    repeat => Repeat( 3,   'A' ), expected => '!3A', },
        { name => 'multiple digits', repeat => Repeat( 123, 'x' ), expected => '!123x', },
        { name => 'zero count',      repeat => Repeat( 0,   'B' ), expected => '!0B', },
    );
    for my $tt (@tests) {
        my $got = $tt->{repeat}->String;
        is $got, $tt->{expected}, $tt->{name};
    }
};
done_testing;
