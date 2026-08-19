use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi/iterm2_test.go
use Cancer::Ansi         qw[ITerm2];
use Cancer::Ansi::Iterm2 qw[Cells Pixels Percent Auto File MultipartFile FilePart FileEnd];
use MIME::Base64         ();
#
is ITerm2( File( {} ) ), "\e]1337;File=\a", 'empty file';
is ITerm2( File( { Name => 'test.png', Size => 1024 } ) ), "\e]1337;File=name=test.png;size=1024\a", 'basic file';
is ITerm2( File( { Name => 'test.png', Width => Pixels(100), Height => Auto } ) ), "\e]1337;File=name=test.png;width=100px;height=auto\a",
    'file with dimensions';
is ITerm2(
    File(
        { Name => 'test.png', Size => 1024, Width => Cells(100), Height => Percent(50), IgnoreAspectRatio => 1, Inline => 1, DoNotMoveCursor => 1 }
    )
    ),
    "\e]1337;File=name=test.png;size=1024;width=100;height=50%;preserveAspectRatio=0;inline=1;doNotMoveCursor=1\a", 'file with all options';
is ITerm2( File( { Name => 'test.png', Content => MIME::Base64::encode_base64( 'test-content', '' ) } ) ),
    "\e]1337;File=name=test.png:dGVzdC1jb250ZW50\a", 'file with content';
is ITerm2( MultipartFile( { Name => 'test.png', Size => 1024, Width => Pixels(100), Height => Percent(50) } ) ),
    "\e]1337;MultipartFile=name=test.png;size=1024;width=100px;height=50%\a", 'multipart file';
is ITerm2( FilePart( { Content => 'part-content' } ) ), "\e]1337;FilePart=part-content\a", 'file part';
is ITerm2( FileEnd( {} ) ),                             "\e]1337;FileEnd\a",               'file end';
#
done_testing;
