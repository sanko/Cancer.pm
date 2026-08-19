use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi clipboard_test.go
use Cancer::Ansi qw[/clipboard/];
use MIME::Base64 ();
#
my @cases = (
    [ 'c',    'Hello Test', "\e]52;c;" . MIME::Base64::encode_base64( 'Hello Test', '' ) . "\a" ],
    [ 'p',    'Ansi Test',  "\e]52;p;" . MIME::Base64::encode_base64( 'Ansi Test',  '' ) . "\a" ],
    [ 'c',    '',           "\e]52;c;\a" ],
    [ 'p',    '?',          "\e]52;p;" . MIME::Base64::encode_base64( '?',    '' ) . "\a" ],
    [ "\x63", 'test',       "\e]52;c;" . MIME::Base64::encode_base64( 'test', '' ) . "\a" ]
);
for my $tc (@cases) {
    my ( $name, $data, $expect ) = @$tc;
    is set_clipboard( $name, $data ), $expect, "SetClipboard($name, $data)";
}
#
diag 'p = primary clipboard';
is reset_clipboard('p'),   "\e]52;p;\a",  'reset_clipboard("p")';
is request_clipboard('p'), "\e]52;p;?\a", 'request_lipboard("p")';
#
done_testing;
