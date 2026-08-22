use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input key_test.go TestKeyString
use Cancer::Input qw[KEY_SPACE MOD_ALT MOD_SHIFT];
#
subtest alt_space => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => KEY_SPACE, mod => MOD_ALT );
    is $k->string, 'alt+space', q[expected a "alt+space"];
};
#
subtest runes => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => ord('a'), text => 'a' );
    is $k->string, 'a', q[expected an "a"];
};
#
subtest invalid => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => 99999 );
    is $k->string, chr(99999), 'unknown rune stringifies as the rune itself';
};
#
subtest space => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => KEY_SPACE, text => ' ' );
    is $k->string, 'space', q[expected a "space"];
};
#
subtest shift_space => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => KEY_SPACE, mod => MOD_SHIFT );
    is $k->string, 'shift+space', q[expected a "shift+space"];
};
#
subtest question_mark => sub {
    my $k = Cancer::Input::KeyPressEvent->new( code => ord('/'), mod => MOD_SHIFT, text => '?' );
    is $k->string, '?', q[expected a "?"];
};
#
done_testing;
