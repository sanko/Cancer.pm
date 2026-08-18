use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use Cancer::Ansi::Parser qw(
    new_parser set_handler set_params_size parser_parse
    Final
);
subtest 'TestSosPmApcSequence' => sub {
    my @dispatched;
    my $p = new_parser();
    set_params_size( $p, 16 );
    set_handler( $p, { HandleApc => sub ($data) { push @dispatched, $data }, HandleEsc => sub ($cmd) { push @dispatched, { esc => $cmd } }, } );

    # -- apc7: "\e_Gf=24,s=10,v=20,o=z;aGVsbG8gd29ybGQ=\e\\"
    parser_parse( $p, "\e_Gf=24,s=10,v=20,o=z;aGVsbG8gd29ybGQ=\e\\" );
    is scalar(@dispatched),          2,                                      'apc7: 2 dispatches';
    is $dispatched[0],               'Gf=24,s=10,v=20,o=z;aGVsbG8gd29ybGQ=', 'apc7: data';
    is Final( $dispatched[1]{esc} ), ord('\\'),                              'apc7: esc cmd';
};
done_testing;
