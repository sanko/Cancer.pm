use v5.42;
use Test2::V1 -ipP;
use blib;
use lib 'lib';
use IO::Handle;
use Cancer::ColorProfile qw[:all];
use Cancer::ColorProfile::Writer;

# Helper to capture writer output
sub capture ( $profile, $input ) {
    my $buf = '';
    open my $fh, '>', \$buf;
    my $w = Cancer::ColorProfile::Writer->new( forward => $fh, profile => $profile );
    $w->write($input);
    close $fh;
    return $buf;
}
#
is capture( TrueColor, "hello \e[31mworld\e[m" ),                     "hello \e[31mworld\e[m",         'TrueColor passthrough';
is capture( NoTTY,     "hello \e[31mworld\e[m" ),                     'hello world',                   'NoTTY strips ANSI';
is capture( ASCII,     "hello \e[31mworld\e[m" ),                     "hello \e[mworld\e[m",           'ASCII strips color, keeps reset';
is capture( ASCII,     "hello \e[1mworld\e[m" ),                      "hello \e[1mworld\e[m",          'ASCII keeps bold';
is capture( ASCII,     "hello \e[1;38;5;204mworld\e[m" ),             "hello \e[1mworld\e[m",          'ASCII keeps bold, strips 256 color';
is capture( ANSI256,   "hello \e[38;5;196mworld\e[m" ),               "hello \e[38;5;196mworld\e[m",   'ANSI256 keeps 256 color';
is capture( ANSI256,   "hello \e[38;2;255;0;0mworld\e[m" ),           "hello \e[38;5;196mworld\e[m",   'ANSI256 downsample RGB to 256';
is capture( ANSI,      "hello \e[38;5;196mworld\e[m" ),               "hello \e[91mworld\e[m",         'ANSI downsample 256 to 16 (bright red)';
is capture( ANSI,      "hello \e[38;2;255;133;55mworld\e[m" ),        "hello \e[91mworld\e[m",         'ANSI downsample RGB to 16';
is capture( ANSI256,   "hello \e[48;2;255;133;55mworld\e[m" ),        "hello \e[48;5;209mworld\e[m",   'ANSI256 downsample RGB bg to 256';
is capture( ANSI,      "\e[48;5;196mhello world\e[m" ),               "\e[101mhello world\e[m",        'ANSI downsample 256 bg to 16';
is capture( ANSI256,   "hello \e[31mworld\e[m" ),                     "hello \e[31mworld\e[m",         'ANSI256 keeps basic ANSI color';
is capture( ANSI256,   "\e[91;102mhello world\e[m" ),                 "\e[91;102mhello world\e[m",     'ANSI256 keeps bright ANSI colors';
is capture( ANSI,      "\e[31mhello \e[39mworld\e[m" ),               "\e[31mhello \e[39mworld\e[m",   'ANSI keeps basic red, keep default fg';
is capture( ANSI256,   "hello \e[1mworld\e[m" ),                      "hello \e[1mworld\e[m",          'ANSI256 keeps bold';
is capture( ANSI256,   '' ),                                          '',                              'empty input';
is capture( ANSI,      'hello world' ),                               'hello world',                   'no styles passes through';
is capture( ANSI256,   "hello \e[38:2::255:133:55mworld\e[m" ),       "hello \e[38;5;209mworld\e[m",   'ANSI256 downsample colon-separated RGB';
is capture( ANSI,      "\e[1;38;5;204mhello \e[38;5;204mworld\e[m" ), "\e[1;91mhello \e[91mworld\e[m", 'ANSI keeps bold, downsample 256 color';
is capture( ASCII,     "\e[91;102mhello world\e[m" ),                 "\e[mhello world\e[m",           'ASCII strips bright ANSI colors';
is capture( ANSI,      "\e[31;42mhello world\e[m" ),                  "\e[31;42mhello world\e[m",      'ANSI keeps basic fg and bg';
subtest 'Writer profile accessor' => sub {
    my $buf = '';
    open my $fh, '>', \$buf;
    my $w = Cancer::ColorProfile::Writer->new( forward => $fh, profile => ANSI256 );
    is $w->profile, ANSI256, 'profile accessor';
    is $w->forward, $fh,     'forward accessor';
    close $fh;
};
subtest 'Writer Detect from environ' => sub {
    my $buf = '';
    open my $fh, '>', \$buf;
    my $w = Cancer::ColorProfile::Writer->new( forward => $fh, environ => { TERM => 'xterm-256color' } );
    is $w->profile, NoTTY, 'Writer detects NoTTY for non-TTY forward';
    close $fh;
};
subtest 'Writer with explicit profile' => sub {
    my $buf = '';
    open my $fh, '>', \$buf;
    my $w = Cancer::ColorProfile::Writer->new( forward => $fh, profile => ANSI256 );
    is $w->profile, ANSI256, 'Writer accepts explicit profile';
    close $fh;
};
#
done_testing;
