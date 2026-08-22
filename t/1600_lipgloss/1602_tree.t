use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
#
use Cancer::Lipgloss::Tree qw[NewTree RootTree DefaultEnumerator RoundedEnumerator DefaultIndenter];
use Cancer::Lipgloss       qw[NewStyle string_width];
use utf8;
#
# ── Leaf ─────────────────────────────────────────────────────────────
#
subtest 'Leaf creation and accessors' => sub {
    my $leaf = Cancer::Lipgloss::Tree::Leaf->new( value => 'hello' );
    is $leaf->Value,  'hello', 'value';
    is $leaf->Hidden, 0,       'not hidden';
    is $leaf->String, 'hello', 'string';
    my @ch = @{ $leaf->Children };
    is scalar @ch, 0, 'no children';
};
#
subtest 'Leaf SetValue' => sub {
    my $leaf = Cancer::Lipgloss::Tree::Leaf->new( value => 'old' );
    $leaf->SetValue('new');
    is $leaf->Value, 'new', 'value updated';
};
#
# ── Tree basics ──────────────────────────────────────────────────────
#
subtest 'NewTree creates empty tree' => sub {
    my $t = NewTree();
    is $t->Value,  '', 'empty value';
    is $t->Hidden, 0,  'not hidden';
    my @ch = @{ $t->Children };
    is scalar @ch, 0, 'no children';
};
#
subtest 'RootTree sets root' => sub {
    my $t = RootTree('root');
    is $t->Value, 'root', 'root value';
};
#
subtest 'Tree Child adds leaves' => sub {
    my $t  = RootTree('root')->Child( 'a', 'b', 'c' );
    my @ch = @{ $t->Children };
    is scalar @ch,    3,   '3 children';
    is $ch[0]->Value, 'a', 'child 0';
    is $ch[1]->Value, 'b', 'child 1';
    is $ch[2]->Value, 'c', 'child 2';
};
#
subtest 'Tree Child adds nested trees' => sub {
    my $child = RootTree('sub')->Child('leaf');
    my $t     = RootTree('root')->Child($child);
    my @ch    = @{ $t->Children };
    is scalar @ch,    1,     '1 child tree';
    is $ch[0]->Value, 'sub', 'child tree root';
    my @gch = @{ $ch[0]->Children };
    is scalar @gch,    1,      '1 grandchild';
    is $gch[0]->Value, 'leaf', 'grandchild value';
};
#
subtest 'Tree hide/show' => sub {
    my $t = RootTree('root')->Child('a');
    $t->Hide(1);
    is $t->Hidden, 1, 'hidden';
    $t->Hide(0);
    is $t->Hidden, 0, 'shown';
};
#
# ── Rendering ────────────────────────────────────────────────────────
#
subtest 'String renders flat list' => sub {
    my $t   = RootTree('Root')->Child( 'A', 'B', 'C' );
    my $out = "$t";
    like $out, qr/Root/,                     'root present';
    like $out, qr/A/,                        'child A';
    like $out, qr/B/,                        'child B';
    like $out, qr/C/,                        'child C';
    like $out, qr/\x{251C}\x{2500}\x{2500}/, 'has branch chars';
    like $out, qr/\x{2514}\x{2500}\x{2500}/, 'has last-branch char';
};
#
subtest 'String renders nested tree' => sub {
    my $t   = RootTree('Dir')->Child( RootTree('Sub')->Child('file.txt'), 'readme.md' );
    my $out = "$t";
    like $out, qr/Dir/,        'root';
    like $out, qr/Sub/,        'sub root';
    like $out, qr/file\.txt/,  'nested file';
    like $out, qr/readme\.md/, 'sibling file';
};
#
subtest 'RoundedEnumerator' => sub {
    my $t   = RootTree('Root')->Enumerator( \&RoundedEnumerator )->Child( 'A', 'B' );
    my $out = "$t";
    like $out, qr/\x{2570}\x{2500}\x{2500}/, 'rounded last';
    like $out, qr/\x{251C}\x{2500}\x{2500}/, 'normal branch';
};
#
subtest 'EnumeratorStyle colors enumerators' => sub {
    my $t   = RootTree('Root')->EnumeratorStyle( NewStyle()->foreground( [ 255, 0, 0 ] ) )->Child('item');
    my $out = "$t";
    like $out, qr/\e\[38;2;255;0;0m/, 'colored enumerator';
};
#
subtest 'ItemStyle colors items' => sub {
    my $t   = RootTree('Root')->ItemStyle( NewStyle()->foreground( [ 0, 255, 0 ] ) )->Child('item');
    my $out = "$t";
    like $out, qr/\e\[38;2;0;255;0m/, 'colored item';
};
#
subtest 'Hidden children not rendered' => sub {
    my $leaf = Cancer::Lipgloss::Tree::Leaf->new( value => 'secret', hidden => 1 );
    my $t    = RootTree('Root')->Child('visible');
    $t->{children}[1] = $leaf;    # inject hidden
    my $out = "$t";
    like $out,   qr/visible/, 'visible child shown';
    unlike $out, qr/secret/,  'hidden child not shown';
};
#
subtest 'Offset slices children' => sub {
    my $t   = RootTree('Root')->Child( 'A', 'B', 'C', 'D', 'E' )->Offset( 1, 1 );
    my $out = "$t";
    like $out,   qr/B/,     'B visible';
    like $out,   qr/C/,     'C visible';
    like $out,   qr/D/,     'D visible';
    unlike $out, qr/\bA\b/, 'A excluded';
    unlike $out, qr/\bE\b/, 'E excluded';
};
#
# ── Empty tree ───────────────────────────────────────────────────────
#
subtest 'Empty tree renders empty string' => sub {
    my $t = NewTree();
    is "$t", '', 'empty string';
};
#
subtest 'Tree with empty root but children renders' => sub {
    my $t   = NewTree()->Child( 'a', 'b' );
    my $out = "$t";
    like $out, qr/a/, 'child a';
    like $out, qr/b/, 'child b';
};
#
done_testing;
