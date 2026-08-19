use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi passthrough_test.go
use Cancer::Ansi qw[ScreenPassthrough TmuxPassthrough];
#
my @passthrough_cases = (
    { name => 'empty', seq => '',          limit => 0, screen => "\x1bP\x1b\\",                                tmux => "\x1bPtmux;\x1b\\" },
    { name => 'short', seq => 'hello',     limit => 0, screen => "\x1bPhello\x1b\\",                           tmux => "\x1bPtmux;hello\x1b\\" },
    { name => 'limit', seq => 'foobarbaz', limit => 3, screen => "\x1bPfoo\x1b\\\x1bPbar\x1b\\\x1bPbaz\x1b\\", tmux => "\x1bPtmux;foobarbaz\x1b\\" },
    {   name   => 'escaped',
        seq    => "\x1b]52;c;Zm9vYmFy\x07",
        limit  => 0,
        screen => "\x1bP\x1b]52;c;Zm9vYmFy\x07\x1b\\",
        tmux   => "\x1bPtmux;\x1b\x1b]52;c;Zm9vYmFy\x07\x1b\\"
    }
);
subtest ScreenPassthrough => sub {
    for my $i ( 0 .. $#passthrough_cases ) {
        my $tt  = $passthrough_cases[$i];
        my $got = ScreenPassthrough( $tt->{seq}, $tt->{limit} );
        is $got, $tt->{screen}, 'case ' . ( $i + 1 ) . ': ' . $tt->{name};
    }
};
subtest TmuxPassthrough => sub {
    for my $i ( 0 .. $#passthrough_cases ) {
        my $tt  = $passthrough_cases[$i];
        my $got = TmuxPassthrough( $tt->{seq} );
        is $got, $tt->{tmux}, 'case ' . ( $i + 1 ) . ': ' . $tt->{name};
    }
};
#
done_testing;
