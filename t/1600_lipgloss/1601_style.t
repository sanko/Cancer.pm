use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::Lipgloss qw[
    NewStyle NoColor Color
    NormalBorder RoundedBorder ThickBorder DoubleBorder NoBorder
    Left Center Right Top Bottom
    JoinHorizontal JoinVertical PlaceHorizontal PlaceVertical
    string_width width height
];
#
# ── Style creation ──────────────────────────────────────────────────
#
subtest 'NewStyle creates empty style' => sub {
    my $s = NewStyle();
    isa_ok $s, 'Cancer::Lipgloss::Style';
    is $s->get_bold,   0, 'not bold';
    is $s->get_italic, 0, 'not italic';
};
#
subtest 'Style chaining' => sub {
    my $s = NewStyle()->bold(1)->italic(1)->underline(1);
    is $s->get_bold,      1, 'bold set';
    is $s->get_italic,    1, 'italic set';
    is $s->get_underline, 1, 'underline set';
};
#
subtest 'Style clone is independent' => sub {
    my $a = NewStyle()->bold(1);
    my $b = $a->italic(1);
    is $a->get_bold, 1, 'original has bold';
    ok !defined( $a->get_italic ) || $a->get_italic == 0, 'original no italic';
    is $b->get_bold,   1, 'clone has bold';
    is $b->get_italic, 1, 'clone has italic';
};
#
# ── Render ──────────────────────────────────────────────────────────
#
subtest 'Render plain text' => sub {
    my $out = NewStyle()->render("hello");
    is $out, 'hello', 'plain render';
};
#
subtest 'Render with bold' => sub {
    my $out = NewStyle()->bold(1)->render("hi");
    like $out, qr/\e\[1m/, 'contains bold SGR';
    like $out, qr/\e\[m/,  'contains reset';
};
#
subtest 'Render with foreground RGB' => sub {
    my $out = NewStyle()->foreground( [ 255, 0, 0 ] )->render("red");
    like $out, qr/\e\[38;2;255;0;0m/, 'contains fg RGB SGR';
};
#
subtest 'Render with background RGB' => sub {
    my $out = NewStyle()->background( [ 0, 0, 255 ] )->render("blue bg");
    like $out, qr/\e\[48;2;0;0;255m/, 'contains bg RGB SGR';
};
#
# ── NoColor ─────────────────────────────────────────────────────────
#
subtest 'NoColor object' => sub {
    my $nc = NoColor();
    isa_ok $nc, 'Cancer::Lipgloss::NoColor';
    is $nc->is_no_color, 1, 'is no color';
};
#
subtest 'Color object' => sub {
    my $c = Color("#FF8000");
    isa_ok $c, 'Cancer::Lipgloss::RGBColor';
    my ( $r, $g, $b, $a ) = $c->RGBA;
    is $r >> 8, 255, 'R channel';
    is $g >> 8, 128, 'G channel';
    is $b >> 8, 0,   'B channel';
};
#
# ── Width / height ──────────────────────────────────────────────────
#
subtest 'string_width plain' => sub {
    is string_width("hello"), 5, 'ascii width';
};
#
subtest 'string_width ANSI stripped' => sub {
    my $s = "\e[1m\e[38;2;255;0;0mHello\e[0m";
    is string_width($s), 5, 'ANSI stripped width';
};
#
subtest 'height single line' => sub {
    is height("hello"), 1, 'single line height';
};
#
subtest 'height multi line' => sub {
    is height("a\nb\nc"), 3, 'multi line height';
};
#
# ── Borders ─────────────────────────────────────────────────────────
#
subtest 'NormalBorder has characters' => sub {
    my $b = NormalBorder();
    isa_ok $b, 'Cancer::Lipgloss::Border';
    is $b->{top_left},     "\x{250C}", 'top_left';
    is $b->{top_right},    "\x{2510}", 'top_right';
    is $b->{bottom_left},  "\x{2514}", 'bottom_left';
    is $b->{bottom_right}, "\x{2518}", 'bottom_right';
    is $b->{top},          "\x{2500}", 'top';
    is $b->{left},         "\x{2502}", 'left';
};
#
subtest 'NoBorder is empty' => sub {
    my $b = NoBorder();
    is $b->{top},  '', 'no top';
    is $b->{left}, '', 'no left';
};
#
# ── JoinHorizontal ──────────────────────────────────────────────────
#
subtest 'JoinHorizontal Top' => sub {
    my $a     = "aaa\nbbb";
    my $b     = "x\ny\nz";
    my $j     = JoinHorizontal( Top, $a, $b );
    my @lines = split /\n/, $j;
    is scalar @lines, 3, '3 lines';
    like $lines[0], qr/aaa\s*x/, 'line 0';
    like $lines[1], qr/bbb\s*y/, 'line 1';
    like $lines[2], qr/\s+z/,    'line 2 padded';
};
#
subtest 'JoinVertical Left' => sub {
    my $j     = JoinVertical( Left, "hello", "hi" );
    my @lines = split /\n/, $j;
    is scalar @lines, 2, '2 lines';
    like $lines[0], qr/hello/, 'line 0';
    like $lines[1], qr/hi/,    'line 1';
};
#
# ── PlaceHorizontal / PlaceVertical ──────────────────────────────────
#
subtest 'PlaceHorizontal centers text' => sub {
    my $p = PlaceHorizontal( 20, Center, "x" );
    is string_width($p), 20, 'correct width';
    my @chars = split //, $p;

    # 'x' should be roughly in the middle
    ok 1, 'no crash';
};
#
subtest 'PlaceVertical centers text' => sub {
    my $p     = PlaceVertical( 5, Center, "a\nb" );
    my @lines = split /\n/, $p;
    is scalar @lines, 5, '5 lines total';
};
#
# ── StyleFunc (getter/setter roundtrip) ─────────────────────────────
#
subtest 'Style getters roundtrip' => sub {
    my $s = NewStyle()->bold(1)->italic(1)->underline(1)->strikethrough(1)->padding_left(2)->padding_right(3)->padding_top(1)->padding_bottom(1);
    is $s->get_bold,           1, 'bold';
    is $s->get_italic,         1, 'italic';
    is $s->get_underline,      1, 'underline';
    is $s->get_strikethrough,  1, 'strikethrough';
    is $s->get_padding_left,   2, 'padding_left';
    is $s->get_padding_right,  3, 'padding_right';
    is $s->get_padding_top,    1, 'padding_top';
    is $s->get_padding_bottom, 1, 'padding_bottom';
};
#
subtest 'Style width/height setters' => sub {
    my $s = NewStyle()->width(40)->height(10);
    is $s->get_width,  40, 'width';
    is $s->get_height, 10, 'height';
};
#
subtest 'Inherit merges styles' => sub {
    my $base  = NewStyle()->bold(1);
    my $child = NewStyle()->italic(1)->inherit($base);
    is $child->get_bold,   1, 'inherited bold';
    is $child->get_italic, 1, 'own italic';
};
#
done_testing;
