use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/input parse_test.go TestParseSequence_Events
use Cancer::Input qw[new_parser MOD_SHIFT MOD_ALT MOD_CTRL];
my $P = new_parser('Cancer::Input');

# ansi.AltScreenSaveCursorMode == 1049, ansi.ModeReset == 2
# ansi.InsertReplaceMode == 4,      ansi.ModeSet   == 1
my $input = "\e\e[Ztest\x00\e]10;rgb:1234/1234/1234\a\e[27;2;27~\e[?1049;2\$y\e[4;1\$y";
my @want  = (
    { class => 'KeyPressEvent',        code => ord "\t", mod => MOD_SHIFT | MOD_ALT, text => '',  shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'KeyPressEvent',        code => ord 't',  mod => 0,                   text => 't', shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'KeyPressEvent',        code => ord 'e',  mod => 0,                   text => 'e', shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'KeyPressEvent',        code => ord 's',  mod => 0,                   text => 's', shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'KeyPressEvent',        code => ord 't',  mod => 0,                   text => 't', shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'KeyPressEvent',        code => ord ' ',  mod => MOD_CTRL,            text => '',  shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'ForegroundColorEvent', color => [ 0x12, 0x12, 0x12, 0xff ] },
    { class => 'KeyPressEvent',        code  => 0x1b, mod   => MOD_SHIFT, text => '', shifted_code => 0, base_code => 0, is_repeat => 0 },
    { class => 'ModeReportEvent',      mode  => 1049, value => 2,         dec  => 1 },
    { class => 'ModeReportEvent',      mode  => 4,    value => 1,         dec  => 0 }
);

sub snap ($e) {
    my $c = ref $e;
    if ( $c eq 'Cancer::Input::KeyPressEvent' || $c eq 'Cancer::Input::KeyReleaseEvent' ) {
        return {
            class        => ( $c =~ s/^Cancer::Input:://r ),
            code         => $e->code         // 0,
            mod          => $e->mod          // 0,
            text         => $e->text         // '',
            shifted_code => $e->shifted_code // 0,
            base_code    => $e->base_code    // 0,
            is_repeat    => $e->is_repeat ? 1 : 0
        };
    }
    elsif ( $c eq 'Cancer::Input::ForegroundColorEvent' || $c eq 'Cancer::Input::BackgroundColorEvent' || $c eq 'Cancer::Input::CursorColorEvent' ) {
        return { class => ( $c =~ s/^Cancer::Input:://r ), color => [ @{ $e->color } ] };
    }
    elsif ( $c eq 'Cancer::Input::ModeReportEvent' ) {
        return { class => 'ModeReportEvent', mode => $e->mode, value => $e->value, dec => $e->dec ? 1 : 0 };
    }
    die "unhandled event class: $c";
}
my @got;
while ( length $input ) {
    my $i = scalar @got;
    bail_out('reached end of want events') if $i >= @want;
    my ( $n, $ev ) = $P->parse_sequence($input);
    push @got, snap($ev);
    last unless $n;
    substr( $input, 0, $n, '' );
}
#
is \@got, \@want, 'event stream matches Go TestParseSequence_Events';
#
done_testing;
