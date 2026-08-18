use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi clipboard_test.go
use Cancer::Ansi;
use MIME::Base64 ();
subtest 'TestClipboardNewClipboard' => sub {
    my @cases = (
        [ 'c',    'Hello Test', "\e]52;c;" . MIME::Base64::encode_base64( 'Hello Test', '' ) . "\a" ],
        [ 'p',    'Ansi Test',  "\e]52;p;" . MIME::Base64::encode_base64( 'Ansi Test',  '' ) . "\a" ],
        [ 'c',    '',           "\e]52;c;\a" ],
        [ 'p',    '?',          "\e]52;p;" . MIME::Base64::encode_base64( '?',    '' ) . "\a" ],
        [ "\x63", 'test',       "\e]52;c;" . MIME::Base64::encode_base64( 'test', '' ) . "\a" ],
    );
    for my $tc (@cases) {
        my ( $name, $data, $expect ) = @$tc;
        my $cb = Cancer::Ansi::set_clipboard( $name, $data );
        is $cb, $expect, "SetClipboard($name, $data)";
    }
};
subtest 'TestClipboardReset' => sub {
    my $cb = Cancer::Ansi::reset_clipboard("\x70");    # 'p' = PrimaryClipboard
    is $cb, "\e]52;p;\a", 'ResetClipboard(PrimaryClipboard)';
};
subtest 'TestClipboardRequest' => sub {
    my $cb = Cancer::Ansi::request_clipboard("\x70");
    is $cb, "\e]52;p;?\a", 'RequestClipboard(PrimaryClipboard)';
};
done_testing;
