use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/iterm2/file_test.go
use Cancer::Ansi::Iterm2 qw(
    Cells Pixels Percent Auto
    FileOpts File MultipartFile FilePart FileEnd
);
use MIME::Base64 ();
subtest 'TestCells' => sub {
    my @tests = ( { input => 0, want => "0" }, { input => 10, want => "10" }, { input => -5, want => "-5" }, { input => 100, want => "100" }, );
    for my $tt (@tests) {
        is Cells( $tt->{input} ), $tt->{want}, "Cells($tt->{input})";
    }
};
subtest 'TestPixels' => sub {
    my @tests
        = ( { input => 0, want => "0px" }, { input => 10, want => "10px" }, { input => -5, want => "-5px" }, { input => 100, want => "100px" }, );
    for my $tt (@tests) {
        is Pixels( $tt->{input} ), $tt->{want}, "Pixels($tt->{input})";
    }
};
subtest 'TestPercent' => sub {
    my @tests = ( { input => 0, want => "0%" }, { input => 10, want => "10%" }, { input => -5, want => "-5%" }, { input => 100, want => "100%" }, );
    for my $tt (@tests) {
        is Percent( $tt->{input} ), $tt->{want}, "Percent($tt->{input})";
    }
};
subtest 'TestFile_String' => sub {
    my @tests = (
        { name => 'empty file', file => {},                                   want => '', },
        { name => 'basic file', file => { Name => 'test.png', Size => 1024 }, want => 'name=test.png;size=1024', },
        {   name => 'file with dimensions',
            file => { Name => 'test.png', Width => '100px', Height => 'auto' },
            want => 'name=test.png;width=100px;height=auto',
        },
        {   name => 'file with all options',
            file =>
                { Name => 'test.png', Size => 1024, Width => '100px', Height => '50%', IgnoreAspectRatio => 1, Inline => 1, DoNotMoveCursor => 1, },
            want => 'name=test.png;size=1024;width=100px;height=50%;' . 'preserveAspectRatio=0;inline=1;doNotMoveCursor=1',
        },
    );
    for my $tt (@tests) {
        is FileOpts( $tt->{file} ), $tt->{want}, $tt->{name};
    }
};
subtest 'TestFile_String_WithContent' => sub {
    my $sample_content  = 'test-content';
    my $encoded_content = MIME::Base64::encode_base64( $sample_content, '' );
    my $f               = { Name => 'test.png', Content => $encoded_content, };
    my $want            = "File=name=test.png:$encoded_content";
    is File($f), $want, 'File.String() with content';
};
subtest 'TestMultipartFile_String' => sub {
    my $f    = { Name => 'test.png', Size => 1024, Width => '100px', Height => '50%', };
    my $want = 'MultipartFile=name=test.png;size=1024;width=100px;height=50%';
    is MultipartFile($f), $want, 'MultipartFile.String()';
};
subtest 'TestFilePart_String' => sub {
    my $sample_content = 'test-content';
    my $f              = { Content => $sample_content };
    my $want           = 'FilePart=test-content';
    is FilePart($f), $want, 'FilePart.String()';
};
subtest 'TestFileEnd_String' => sub {
    is FileEnd( {} ), 'FileEnd', 'FileEnd.String()';
};
subtest 'TestAuto_Constant' => sub {
    is Auto, 'auto', 'Auto constant';
};
done_testing;
