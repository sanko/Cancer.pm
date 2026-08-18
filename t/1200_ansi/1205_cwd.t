use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi cwd_test.go
use Cancer::Ansi;
subtest 'TestNotifyWorkingDirectory_LocalFile' => sub {
    my $h = Cancer::Ansi::notify_working_directory( 'localhost', 'path', 'to', 'file' );
    is $h, "\e]7;file://localhost/path/to/file\a", 'local file';
};
subtest 'TestNotifyWorkingDirectory_RemoteFile' => sub {
    my $h = Cancer::Ansi::notify_working_directory( 'example.com', 'path', 'to', 'file' );
    is $h, "\e]7;file://example.com/path/to/file\a", 'remote file';
};
done_testing;
