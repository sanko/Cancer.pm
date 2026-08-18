use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi notification_test.go
use Cancer::Ansi;
subtest 'TestNotify' => sub {
    my @tests = (
        [ 'basic',              'Hello, World!',        "\e]9;Hello, World!\a" ],
        [ 'empty',              '',                     "\e]9;\a" ],
        [ 'special characters', "Line1\nLine2\tTabbed", "\e]9;Line1\nLine2\tTabbed\a" ],
    );
    for my $tc (@tests) {
        my ( $name, $s, $want ) = @$tc;
        my $got = Cancer::Ansi::notify($s);
        is $got, $want, $name;
    }
};
subtest 'TestDesktopNotification' => sub {
    my @tests = (
        [ 'basic',         'Task Completed', [],                   "\e]99;;Task Completed\a" ],
        [ 'with metadata', 'New Message',    [ 'i=1', 'a=focus' ], "\e]99;i=1:a=focus;New Message\a" ],
        [ 'empty payload', '',               ['i=2'],              "\e]99;i=2;\a" ],
    );
    for my $tc (@tests) {
        my ( $name, $payload, $metadata, $want ) = @$tc;
        my $got = Cancer::Ansi::desktop_notification( $payload, @$metadata );
        is $got, $want, $name;
    }
};
done_testing;
