use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi/iterm2/file_test.go
use Cancer::Ansi::Iterm2 qw[Cells Pixels Percent Auto FileOpts File MultipartFile FilePart FileEnd];
use MIME::Base64         ();
#
subtest Cells => sub {
    is Cells( 0),  '0',   'Cells(0)';
    is Cells( 10), '10',  'Cells(10)';
    is Cells(-5),  '-5',  'Cells(-5)';
    is Cells(100), '100', 'Cells(100)';
};
subtest Pixels => sub {
    is Pixels( 0),  '0px',   'Pixels(0)';
    is Pixels( 10), '10px',  'Pixels(10)';
    is Pixels(-5),  '-5px',  'Pixels(-5)';
    is Pixels(100), '100px', 'Pixels(100)';
};
subtest Percent => sub {
    is Percent( 0),  '0%',   'Percent(0)';
    is Percent( 10), '10%',  'Percent(10)';
    is Percent(-5),  '-5%',  'Percent(-5)';
    is Percent(100), '100%', 'Percent(100)';
};
subtest 'File.String' => sub {
    is FileOpts( {} ),                                                         '',                                      'empty file';
    is FileOpts( { Name => 'test.png', Size => 1024 } ),                       'name=test.png;size=1024',               'basic file';
    is FileOpts( { Height => 'auto', Name => 'test.png', Width => '100px' } ), 'name=test.png;width=100px;height=auto', 'file with dimensions';
    is FileOpts( { DoNotMoveCursor => 1, Height => '50%', IgnoreAspectRatio => 1, Inline => 1, Name => 'test.png', Size => 1024, Width => '100px' } ),
        'name=test.png;size=1024;width=100px;height=50%;preserveAspectRatio=0;inline=1;doNotMoveCursor=1', 'file with all options';
};
subtest 'File.String with content' => sub {
    my $sample_content  = 'test-content';
    my $encoded_content = MIME::Base64::encode_base64( $sample_content, '' );
    my $f               = { Name => 'test.png', Content => $encoded_content };
    my $want            = 'File=name=test.png:' . $encoded_content;
    is File($f), $want, 'File.String() with content';
};
is MultipartFile( { Name => 'test.png', Size => 1024, Width => '100px', Height => '50%' } ),
    'MultipartFile=name=test.png;size=1024;width=100px;height=50%', 'MultipartFile.String()';
subtest 'FilePart.String' => sub {
    my $sample_content = 'test-content';
    my $f              = { Content => $sample_content };
    my $want           = 'FilePart=test-content';
    is FilePart($f), $want, 'FilePart.String()';
};
is FileEnd( {} ), 'FileEnd', 'FileEnd.String()';
is Auto,          'auto',    'Auto constant';
#
done_testing;
