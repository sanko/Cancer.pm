use Test2::V1 -ipP;
use blib;
use Cancer::Ansi qw[/^Attr/ SGR];
#
my @tests = (
    { name => 'no attributes',                     args => [],                                                              want => "\e[m" },
    { name => 'single basic attribute',            args => [AttrBold],                                                      want => "\e[1m" },
    { name => 'multiple basic attributes',         args => [ AttrBold, AttrItalic, AttrUnderline ],                         want => "\e[1;3;4m" },
    { name => 'foreground colors',                 args => [ AttrRedForegroundColor, AttrBold ],                            want => "\e[31;1m" },
    { name => 'background colors',                 args => [ AttrBlueBackgroundColor, AttrBold ],                           want => "\e[44;1m" },
    { name => 'bright colors',                     args => [ AttrBrightRedForegroundColor, AttrBrightBlueBackgroundColor ], want => "\e[91;104m" },
    { name => 'reset attributes',                  args => [AttrReset],                                                     want => "\e[0m" },
    { name => 'negative attribute value',          args => [-1],                                                            want => "\e[0m" },
    { name => 'custom attribute value',            args => [99],                                                            want => "\e[99m" },
    { name => 'mixed known and custom attributes', args => [ AttrBold, 99, AttrItalic ],                                    want => "\e[1;99;3m" },
    {   name => 'all text decorations',
        args => [ AttrBold, AttrFaint, AttrItalic, AttrUnderline, AttrBlink, AttrReverse, AttrConceal, AttrStrikethrough ],
        want => "\e[1;2;3;4;5;7;8;9m"
    },
    {   name => 'all color reset attributes',
        args => [ AttrDefaultForegroundColor, AttrDefaultBackgroundColor, AttrDefaultUnderlineColor ],
        want => "\e[39;49;59m"
    },
    {   name => 'extended color attributes',
        args => [ AttrExtendedForegroundColor, AttrExtendedBackgroundColor, AttrExtendedUnderlineColor ],
        want => "\e[38;48;58m"
    }
);
is SGR( $_->{args}->@* ), $_->{want}, $_->{name} for @tests;
#
subtest Addition => sub {
    my @tests = ( { args => [] }, { args => [AttrBold] }, { args => [ AttrBold, AttrRedForegroundColor, AttrBlueBackgroundColor ] } );
    for my $t (@tests) {
        is SGR( $t->{args}->@* ), SGR( $t->{args}->@* ), join( ', ', map { '[' . $_ . ']' } $t->{args}->@* );
    }
};
#
done_testing;
