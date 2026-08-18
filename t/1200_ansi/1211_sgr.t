use Test2::V1 -ipP;
use Cancer::Ansi qw(
    SelectGraphicRendition SGR
    BoldAttr FaintAttr ItalicAttr UnderlineAttr SlowBlinkAttr
    ReverseAttr ConcealAttr StrikethroughAttr ResetAttr
    RedForegroundColorAttr BlueBackgroundColorAttr
    BrightRedForegroundColorAttr BrightBlueBackgroundColorAttr
    DefaultForegroundColorAttr DefaultBackgroundColorAttr
    DefaultUnderlineColorAttr
    ExtendedForegroundColorAttr ExtendedBackgroundColorAttr
    ExtendedUnderlineColorAttr
);
subtest 'TestSelectGraphicRendition' => sub {
    my @tests = (
        { name => 'no attributes',             args => [],                                                              want => "\e[m", },
        { name => 'single basic attribute',    args => [BoldAttr],                                                      want => "\e[1m", },
        { name => 'multiple basic attributes', args => [ BoldAttr, ItalicAttr, UnderlineAttr ],                         want => "\e[1;3;4m", },
        { name => 'foreground colors',         args => [ RedForegroundColorAttr, BoldAttr ],                            want => "\e[31;1m", },
        { name => 'background colors',         args => [ BlueBackgroundColorAttr, BoldAttr ],                           want => "\e[44;1m", },
        { name => 'bright colors',             args => [ BrightRedForegroundColorAttr, BrightBlueBackgroundColorAttr ], want => "\e[91;104m", },
        { name => 'reset attributes',          args => [ResetAttr],                                                     want => "\e[0m", },
        { name => 'negative attribute value',  args => [-1],                                                            want => "\e[0m", },
        { name => 'custom attribute value',    args => [99],                                                            want => "\e[99m", },
        { name => 'mixed known and custom attributes', args => [ BoldAttr, 99, ItalicAttr ],                            want => "\e[1;99;3m", },
        {   name => 'all text decorations',
            args => [ BoldAttr, FaintAttr, ItalicAttr, UnderlineAttr, SlowBlinkAttr, ReverseAttr, ConcealAttr, StrikethroughAttr, ],
            want => "\e[1;2;3;4;5;7;8;9m",
        },
        {   name => 'all color reset attributes',
            args => [ DefaultForegroundColorAttr, DefaultBackgroundColorAttr, DefaultUnderlineColorAttr, ],
            want => "\e[39;49;59m",
        },
        {   name => 'extended color attributes',
            args => [ ExtendedForegroundColorAttr, ExtendedBackgroundColorAttr, ExtendedUnderlineColorAttr, ],
            want => "\e[38;48;58m",
        },
    );
    for my $t (@tests) {
        is SelectGraphicRendition( $t->{args}->@* ), $t->{want}, $t->{name};
    }
};
subtest 'TestSGR' => sub {
    my @tests = ( { args => [] }, { args => [BoldAttr] }, { args => [ BoldAttr, RedForegroundColorAttr, BlueBackgroundColorAttr ] }, );
    for my $t (@tests) {
        is SGR( $t->{args}->@* ), SelectGraphicRendition( $t->{args}->@* ), join( ', ', map {"[$_]"} $t->{args}->@* );
    }
};
done_testing;
