use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::Lipgloss::List qw[
    NewList BulletEnumerator DashEnumerator
    AsteriskEnumerator ArabicEnumerator AlphabetEnumerator RomanEnumerator
];
use Cancer::Lipgloss qw[NewStyle];
use utf8;
#
# ── Basic list ───────────────────────────────────────────────────────
#
subtest 'NewList creates empty list' => sub {
    my $l = NewList();
    is $l->Value,  '', 'empty value';
    is $l->Hidden, 0,  'not hidden';
};
#
subtest 'List Item and Items' => sub {
    my $l   = NewList()->Item('A')->Item('B')->Items( 'C', 'D' );
    my $out = "$l";
    like $out, qr/A/, 'item A';
    like $out, qr/B/, 'item B';
    like $out, qr/C/, 'item C';
    like $out, qr/D/, 'item D';
};
#
# ── Default enumerator ───────────────────────────────────────────────
#
subtest 'Default bullet enumerator' => sub {
    my $l   = NewList()->Item('X');
    my $out = "$l";
    like $out, qr/\x{2022}/, 'bullet char';
    like $out, qr/X/,        'item text';
};
#
# ── Built-in enumerators ─────────────────────────────────────────────
#
subtest 'Arabic enumerator' => sub {
    my $l   = NewList()->Enumerator( \&ArabicEnumerator )->Items( 'First', 'Second', 'Third' );
    my $out = "$l";
    like $out, qr/1\. First/,  'arabic 1';
    like $out, qr/2\. Second/, 'arabic 2';
    like $out, qr/3\. Third/,  'arabic 3';
};
#
subtest 'Alphabet enumerator' => sub {
    my $l   = NewList()->Enumerator( \&AlphabetEnumerator )->Items( 'Alpha', 'Beta', 'Gamma' );
    my $out = "$l";
    like $out, qr/A\. Alpha/, 'alpha A';
    like $out, qr/B\. Beta/,  'alpha B';
    like $out, qr/C\. Gamma/, 'alpha C';
};
#
subtest 'Roman enumerator' => sub {
    my $l   = NewList()->Enumerator( \&RomanEnumerator )->Items( 'I', 'II', 'III', 'IV' );
    my $out = "$l";
    like $out, qr/I\. I\b/,     'roman I';
    like $out, qr/II\. II\b/,   'roman II';
    like $out, qr/III\. III\b/, 'roman III';
    like $out, qr/IV\. IV\b/,   'roman IV';
};
#
subtest 'Dash enumerator' => sub {
    my $l   = NewList()->Enumerator( \&DashEnumerator )->Items( 'one', 'two' );
    my $out = "$l";
    like $out, qr/- one/, 'dash one';
    like $out, qr/- two/, 'dash two';
};
#
subtest 'Asterisk enumerator' => sub {
    my $l   = NewList()->Enumerator( \&AsteriskEnumerator )->Items( 'x', 'y' );
    my $out = "$l";
    like $out, qr/\* x/, 'asterisk x';
    like $out, qr/\* y/, 'asterisk y';
};
#
# ── Nested lists ─────────────────────────────────────────────────────
#
subtest 'Nested list renders children' => sub {
    my $inner = NewList()->Item('milk')->Item('eggs');
    my $outer = NewList()->Item('Groceries')->Item($inner)->Item('Clothes');
    my $out   = "$outer";
    like $out, qr/Groceries/, 'outer item';
    like $out, qr/milk/,      'inner milk';
    like $out, qr/eggs/,      'inner eggs';
    like $out, qr/Clothes/,   'outer after nested';
};
#
# ── Item styling ─────────────────────────────────────────────────────
#
subtest 'ItemStyle applies style to items' => sub {
    my $l   = NewList()->ItemStyle( NewStyle()->bold(1) )->Item('hello');
    my $out = "$l";
    like $out, qr/\e\[1m/, 'bold applied';
    like $out, qr/hello/,  'item text present';
};
#
# ── Hide ──────────────────────────────────────────────────────────────
#
subtest 'Hidden list renders empty' => sub {
    my $l = NewList()->Item('secret')->Hide(1);
    is "$l", '', 'hidden list empty';
};
#
# ── Enumerator style ─────────────────────────────────────────────────
#
subtest 'EnumeratorStyle colors enumerator' => sub {
    my $l   = NewList()->EnumeratorStyle( NewStyle()->foreground( [ 255, 0, 0 ] ) )->Item('red bullet');
    my $out = "$l";
    like $out, qr/\e\[38;2;255;0;0m/, 'colored enumerator';
};
#
done_testing;
