use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi notification_test.go
use Cancer::Ansi qw[/notif/];
#
subtest notify => sub {
    is notify('Hello, World!'),           "\e]9;Hello, World!\a",        'basic';
    is notify(''),                        "\e]9;\a",                     'empty';
    is notify( "Line1\nLine2\tTabbed", ), "\e]9;Line1\nLine2\tTabbed\a", 'special characters';
};
subtest desktop_notification => sub {
    is desktop_notification('Task Completed'),                  "\e]99;;Task Completed\a",         'basic';
    is desktop_notification( 'New Message', 'i=1', 'a=focus' ), "\e]99;i=1:a=focus;New Message\a", 'with metadata';
    is desktop_notification( '', 'i=2' ),                       "\e]99;i=2;\a",                    'empty payload';
};
#
done_testing;
