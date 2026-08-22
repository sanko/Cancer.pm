use v5.42;
use experimental 'class';
use utf8;
use blib;
use Test2::V1 -ipP;
use Cancer::Util     qw[string_width truncate truncate_left wrap hardwrap visual_truncate ansi_cut];
use Cancer::Lipgloss qw[NewStyle StyleRunes];

# Regression tests for extended-grapheme-cluster (\X) handling: emoji ZWJ
# sequences, combining marks, and regional-indicator pairs must never be torn
# apart by width math, truncation, or wrapping.
my $family = "\x{1F469}\x{200D}\x{1F469}\x{200D}\x{1F467}\x{200D}\x{1F466}"    # women+girl+boy ZWJ chain
    ;
my $comb = "e\x{0301}";                                                        # e + combining acute
my $flag = "\x{1F1FA}\x{1F1F8}";                                               # US regional indicators
subtest 'StringWidth clusters' => sub {
    is string_width($family),       2, 'ZWJ family emoji is one cluster of width 2';
    is string_width($comb),         1, 'base + combining mark is one cell';
    is string_width($flag),         2, 'regional indicator pair is width 2';
    is string_width("a${family}b"), 4, 'family between ASCII stays 2 cells';
};
subtest 'Truncate keeps clusters whole' => sub {
    my $t = truncate( $family . '!', 2, '' );
    is $t,               $family, 'truncate at exact cluster width emits whole emoji';
    is string_width($t), 2,       'emitted emoji measures 2 cells';
    my $t2 = truncate( "ab${comb}c", 3, '' );
    is index( $t2, "\x{0301}" ) > index( $t2, 'e' ), !!1, 'combining mark stays glued to base';
};
subtest 'TruncateLeft keeps clusters whole' => sub {
    my $s = "ab${family}";
    my $l = truncate_left( $s, 3, '' );
    ok index( $l, "\x{200D}" ) >= 1, 'left-truncated output contains intact ZWJ chain';
    is string_width($l) <= 4, !!1, 'width bounded';
};
subtest 'Hardwrap / Wrap keep flags intact' => sub {
    my $w     = wrap( "${flag}${flag}${flag}", 4, '' );
    my @lines = split /\n/, $w, -1;
    my @bad   = grep { $_ ne '' && string_width($_) == 1 } @lines;
    is scalar(@bad), 0, 'no torn half-flags on wrapped lines';
    my $hw   = hardwrap( "${flag}${flag}${flag}", 4, 0 );
    my @hl   = split /\n/, $hw, -1;
    my @hbad = grep { $_ ne '' && string_width($_) == 1 } @hl;
    is scalar(@hbad), 0, 'no torn half-flags from hardwrap';
};
subtest 'VisualTruncate and Cut with ANSI + clusters' => sub {
    my $vt = visual_truncate( "\e[31mab${family}cd\e[m", 5 );
    like $vt, qr/^\e\[31m/, 'ANSI prefix preserved';
    ok string_width($vt) <= 5, 'cluster widths respected';
    my $cut = ansi_cut( "a${family}b", 3 );
    is $cut, "a${family}", 'cut keeps whole emoji at boundary' or note $cut;
};
subtest 'StyleRunes indices address graphemes' => sub {
    my $plain = NewStyle();
    my $hi    = NewStyle()->foreground('#FF0000');
    my $out   = StyleRunes( $family . 'x', [0], $hi, $plain );
    ok index( $out, $family ) >= 0, 'emoji survives styling intact';
};
subtest 'Style clone deep-copies mutable refs' => sub {
    my $border = { top => '-', bottom => '-', left => '|', right => '|', top_left => '+', top_right => '+', bottom_left => '+', bottom_right => '+' };
    my $base   = NewStyle()->border($border);
    my $c      = $base->clone;
    $c->{border}{top} = 'MUTATED';
    is $base->{border}{top}, '-', 'cloned border hashref is independent';
    $base->{border_blend_fg} = ['only'];
    my $c2 = $base->clone;
    push @{ $c2->{border_blend_fg} }, 'extra';
    is scalar @{ $base->{border_blend_fg} }, 1, 'cloned blend arrayref is independent';

    # Rendering a partial border must not corrupt the shared border table
    my $top_only = NewStyle()->border($border)->border_top(1)->foreground('#FFFFFF');
    $top_only->render('hello');
    is $border->{bottom}, '-', 'shared border constant not mutated by render';
};
done_testing;
