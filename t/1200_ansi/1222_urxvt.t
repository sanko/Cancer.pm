use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi urxvt_test.go
use Cancer::Ansi qw(URxvtExt);
subtest 'TestUrxvtExt' => sub {
    my @tests = (
        { extension => 'foo',     params => [qw(bar baz)],      expected => "\e]777;foo;bar;baz\a", },
        { extension => 'test',    params => [],                 expected => "\e]777;test;\a", },
        { extension => 'example', params => ['param1'],         expected => "\e]777;example;param1\a", },
        { extension => 'notify',  params => [qw(message info)], expected => "\e]777;notify;message;info\a", },
    );
    for my $tt (@tests) {
        my $result = URxvtExt( $tt->{extension}, $tt->{params}->@* );
        is $result, $tt->{expected}, "URxvtExt($tt->{extension}, @{$tt->{params}})";
    }
};
done_testing;
