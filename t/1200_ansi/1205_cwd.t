use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use blib;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi cwd_test.go
use Cancer::Ansi qw[/directory/];
#
is notify_working_directory( 'localhost',   'path', 'to', 'file' ), "\e]7;file://localhost/path/to/file\a",   'local file';
is notify_working_directory( 'example.com', 'path', 'to', 'file' ), "\e]7;file://example.com/path/to/file\a", 'remote file';
#
done_testing;
