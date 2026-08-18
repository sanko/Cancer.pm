use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/iterm2_test.go
use Cancer::Ansi         qw(ITerm2);
use Cancer::Ansi::Iterm2 qw(
    Cells Pixels Percent Auto
    File MultipartFile FilePart FileEnd
);
use MIME::Base64 ();
subtest 'TestITerm2' => sub {
    my @tests = (
        { name => 'empty file', data => File( {} ),                                   want => "\e]1337;File=\a", },
        { name => 'basic file', data => File( { Name => 'test.png', Size => 1024 } ), want => "\e]1337;File=name=test.png;size=1024\a", },
        {   name => 'file with dimensions',
            data => File( { Name => 'test.png', Width => Pixels(100), Height => Auto, } ),
            want => "\e]1337;File=name=test.png;width=100px;height=auto\a",
        },
        {   name => 'file with all options',
            data => File(
                {   Name              => 'test.png',
                    Size              => 1024,
                    Width             => Cells(100),
                    Height            => Percent(50),
                    IgnoreAspectRatio => 1,
                    Inline            => 1,
                    DoNotMoveCursor   => 1,
                }
            ),
            want => "\e]1337;File=name=test.png;size=1024;width=100;" . "height=50%;preserveAspectRatio=0;inline=1;" . "doNotMoveCursor=1\a",
        },
        {   name => 'file with content',
            data => File( { Name => 'test.png', Content => MIME::Base64::encode_base64( 'test-content', '' ), } ),
            want => "\e]1337;File=name=test.png:dGVzdC1jb250ZW50\a",
        },
        {   name => 'multipart file',
            data => MultipartFile( { Name => 'test.png', Size => 1024, Width => Pixels(100), Height => Percent(50), } ),
            want => "\e]1337;MultipartFile=name=test.png;size=1024;" . "width=100px;height=50%\a",
        },
        { name => 'file part', data => FilePart( { Content => 'part-content' } ), want => "\e]1337;FilePart=part-content\a", },
        { name => 'file end',  data => FileEnd( {} ),                             want => "\e]1337;FileEnd\a", },
    );
    for my $tt (@tests) {
        my $got = ITerm2( $tt->{data} );
        is $got, $tt->{want}, $tt->{name};
    }
};
done_testing;
