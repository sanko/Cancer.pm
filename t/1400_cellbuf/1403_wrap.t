use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::CellBuf::Wrap qw[wrap_text];
#
my $RST = "\e[m";
#
sub sgr     (@codes)              { @codes ? "\e[" . join( ';', @codes ) . 'm' : $RST }
sub has_seq ( $str, $seq, $desc ) { like( $str, qr/\Q$seq\E/, $desc ) }
#
subtest 'Basic wrapping (no ANSI)' => sub {
    is wrap_text( '',              10 ), '',                  'empty string';
    is wrap_text( 'hello',         0 ),  'hello',             'zero limit returns as-is';
    is wrap_text( 'hello',         -1 ), 'hello',             'negative limit returns as-is';
    is wrap_text( 'hello world',   11 ), 'hello world',       'no wrap needed';
    is wrap_text( 'hello world',   5 ),  "hello\nworld",      'wrap at limit';
    is wrap_text( 'a b c d',       3 ),  "a b\nc d",          'wrap multi-word';
    is wrap_text( 'longword',      4 ),  "long\nword",        'hard wrap long word';
    is wrap_text( 'one-two-three', 5 ),  "one-\ntwo-\nthree", 'hyphen breakpoint';
    is wrap_text( 'a b c', 1, ' ' ), "a\nb\nc", 'limit 1 wraps each word';
};
subtest 'Whitespace handling' => sub {
    is wrap_text( '  hello', 10 ), '  hello', 'leading space preserved';
    is wrap_text( '   ',     5 ),  '   ',     'only spaces preserved';
};
subtest 'Breakpoints (custom breakpoints fall through to word handling when they do not fit)' => sub {
    is wrap_text( 'a.b.c', 3, '.' ), "a.\nb.c", 'dot breakpoint wraps correctly';
    is wrap_text( 'a|b|c', 3, '|' ), "a|\nb|c", 'pipe breakpoint wraps correctly';
    is wrap_text( 'a.b.c', 5, '.' ), "a.b.c",   'dot breakpoint no wrap needed';
};
subtest 'ANSI-aware wrapping' => sub {
    my $bold = sgr(1);
    my $red  = sgr(31);

    # Basic ANSI passthrough
    is wrap_text( $bold . 'hello' . $RST . ' world', 11 ), $bold . 'hello' . $RST . ' world', 'ANSI sequences preserved when no wrap';

    # ANSI with wrapping
    my $result = wrap_text( $red . 'hello world' . $RST, 5 );
    has_seq $result, $red, 'red ANSI preserved across wrap';
    has_seq $result, $RST, 'reset ANSI preserved across wrap';
    has_seq $result, "\n", 'newline inserted at wrap';

    # Style resets at newline, re-applied after
    my $styled = wrap_text( $bold . 'ab cd' . $RST, 3 );
    has_seq $styled, $bold, 'bold present in output';
    like $styled, qr/\e\[m.*\n.*\e\[1m/s, 'bold reset at newline, re-applied';

    # Tab is width-0 control, added to word buffer
    $result = wrap_text( "hello\tworld", 10 );
    like $result, qr/hello.*world/s, 'tab input produces hello-world output';

    # Newline in input
    $result = wrap_text( "line1\nline2", 20 );
    like $result, qr/^line1\nline2$/, 'input newline preserved';

    # Empty styled segments
    $result = wrap_text( $bold . $RST . 'hello', 10 );
    has_seq $result, 'hello', 'empty styled segment passes through';

    # Long styled word gets hard-wrapped
    $result = wrap_text( $red . 'abcdefghij' . $RST, 4 );
    has_seq $result, $red, 'red present after hard wrap';
};
subtest 'Hyperlink handling' => sub {
    use Cancer::Ansi qw[set_hyperlink reset_hyperlink];
    my $link_start = set_hyperlink( 'https://example.com', '' );
    my $link_end   = reset_hyperlink();
    my $result     = wrap_text( $link_start . 'click here please' . $link_end, 6 );
    has_seq $result, $link_start, 'hyperlink start preserved';
    has_seq $result, $link_end,   'hyperlink end preserved';
};
#
done_testing;
