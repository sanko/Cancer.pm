use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi graphics_test.go
use Cancer::Ansi;
subtest 'TestKittyGraphics' => sub {
    my @tests = (
        [ 'empty payload no options',           '',     [],                       "\e_G\e\\" ],
        [ 'with payload no options',            'test', [],                       "\e_G;test\e\\" ],
        [ 'with payload and options',           'test', [ 'a=t', 'f=100' ],       "\e_Ga=t,f=100;test\e\\" ],
        [ 'multiple options no payload',        '',     [ 'q=2', 'C=1', 'f=24' ], "\e_Gq=2,C=1,f=24\e\\" ],
        [ 'with special characters in payload', "\e_G", ['a=t'],                  "\e_Ga=t;\e_G\e\\" ],
    );
    for my $tc (@tests) {
        my ( $name, $payload, $opts, $want ) = @$tc;
        my $got = Cancer::Ansi::kitty_graphics( $payload, @$opts );
        is $got, $want, $name;
    }
};
done_testing;
