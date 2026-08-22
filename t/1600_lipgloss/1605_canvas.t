use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use blib;
use Cancer::Lipgloss qw[
    NewStyle NewCanvas NewLayer NewCompositor
    Print Println Printf Fprint Fprintln Fprintf Sprint Sprintln Sprintf
    WithWhitespaceStyle WithWhitespaceChars Place
    OuterHalfBlockBorder InnerHalfBlockBorder
    Black Red Green Yellow Blue Magenta Cyan White
    BrightBlack BrightRed BrightGreen BrightYellow BrightBlue BrightMagenta BrightCyan BrightWhite
    UnderlineNone UnderlineSingle UnderlineDouble UnderlineCurly UnderlineDotted UnderlineDashed
    NoTabConversion
    NBSP string_width width height
    NormalBorder RoundedBorder ThickBorder DoubleBorder
    Left Center Right Top Bottom
];

# ============================================================
# Canvas tests
# ============================================================
subtest 'Canvas creation and basic ops' => sub {
    my $c = NewCanvas( width => 5, height => 3 );
    is( $c->width,  5, 'width' );
    is( $c->height, 3, 'height' );
    ok( $c->bounds, 'bounds not undef' );
    is( $c->bounds->dx, 5, 'bounds dx' );
    is( $c->bounds->dy, 3, 'bounds dy' );
};
subtest 'Canvas cell manipulation' => sub {
    my $c    = NewCanvas( width => 3, height => 2 );
    my $cell = Cancer::CellBuf::Cell->new( rune => ord('X'), width => 1 );
    $c->set_cell( 1, 0, $cell );
    my $got = $c->cell_at( 1, 0 );
    ok( defined $got, 'cell set and retrieved' );
};
subtest 'Canvas render' => sub {
    my $c = NewCanvas( width => 5, height => 3 );
    for my $y ( 0 .. 2 ) {
        for my $x ( 0 .. 4 ) {
            my $cell = Cancer::CellBuf::Cell->new( rune => ord('.'), width => 1 );
            $c->set_cell( $x, $y, $cell );
        }
    }
    my $r = $c->render;
    like( $r, qr/\Q...\E/, 'render contains dots' );
};
subtest 'Canvas clear' => sub {
    my $c    = NewCanvas( width => 2, height => 2 );
    my $cell = Cancer::CellBuf::Cell->new( rune => ord('A'), width => 1 );
    $c->set_cell( 0, 0, $cell );
    $c->clear;
    my $got = $c->cell_at( 0, 0 );
    ok( !defined $got || $got->rune == ord(' '), 'cell cleared to blank' );
};
subtest 'Canvas resize' => sub {
    my $c = NewCanvas( width => 2, height => 2 );
    $c->resize( 4, 4 );
    is( $c->width,  4, 'resized width' );
    is( $c->height, 4, 'resized height' );
};

# ============================================================
# Layer tests
# ============================================================
subtest 'Layer creation and accessors' => sub {
    my $l = NewLayer("hello");
    is( $l->content, "hello", 'content' );
    is( $l->width,   5,       'width computed' );
    is( $l->height,  1,       'height computed' );
};
subtest 'Layer positioning' => sub {
    my $l = NewLayer("world");
    $l->set_x(3)->set_y(2)->set_z(1);
    is( $l->get_x, 3, 'x' );
    is( $l->get_y, 2, 'y' );
    is( $l->get_z, 1, 'z' );
};
subtest 'Layer ID' => sub {
    my $l = NewLayer("test");
    $l->set_id("my-layer");
    is( $l->get_id, "my-layer", 'id set' );
};
subtest 'Layer children' => sub {
    my $child  = NewLayer("child");
    my $parent = NewLayer("parent");
    $parent->add_layers($child);
    is( scalar $parent->layers, 1, 'one child' );
    is( $parent->width,         6, 'parent width includes child' );
};
subtest 'Layer get_layer by ID' => sub {
    my $child = NewLayer("child");
    $child->set_id("c1");
    my $root = NewLayer("root");
    $root->add_layers($child);
    my $found = $root->get_layer("c1");
    ok( defined $found, 'found child by id' );
    is( $found->get_id, "c1", 'correct id' );
};
subtest 'Layer max_z' => sub {
    my $a = NewLayer("a");
    $a->set_z(2);
    my $b = NewLayer("b");
    $b->set_z(5);
    my $root = NewLayer("root");
    $root->add_layers( $a, $b );
    is( $root->max_z, 5, 'max z' );
};
subtest 'Layer multiline content' => sub {
    my $l = NewLayer("line1\nline2\nline3");
    is( $l->height, 3, '3 lines' );
    is( $l->width,  5, 'width of widest line' );
};

# ============================================================
# Compositor tests
# ============================================================
subtest 'Compositor creation' => sub {
    my $comp = NewCompositor();
    ok( $comp,         'created' );
    ok( $comp->bounds, 'has bounds' );
};
subtest 'Compositor with layers' => sub {
    my $a = NewLayer("AAA");
    my $b = NewLayer("BBB");
    $b->set_x(0)->set_y(1);
    my $comp = NewCompositor( $a, $b );
    my $bnd  = $comp->bounds;
    ok( $bnd, 'bounds exist' );
    is( $bnd->dx, 3, 'bounds dx' );
};
subtest 'Compositor render' => sub {
    my $a = NewLayer("AAA");
    my $b = NewLayer("BBB");
    $b->set_x(0)->set_y(1);
    my $comp   = NewCompositor( $a, $b );
    my $result = $comp->render;
    like( $result, qr/AAA/, 'contains AAA' );
    like( $result, qr/BBB/, 'contains BBB' );
};
subtest 'Compositor hit test' => sub {
    my $a = NewLayer("AAA");
    $a->set_id("layer-a");
    my $b = NewLayer("BBB");
    $b->set_y(1);
    $b->set_id("layer-b");
    my $comp = NewCompositor( $a, $b );
    my $hit  = $comp->hit( 1, 0 );
    ok( !$hit->empty, 'hit at (1,0)' );
    is( $hit->id, "layer-a", 'hit layer-a' );
    my $hit2 = $comp->hit( 1, 1 );
    ok( !$hit2->empty, 'hit at (1,1)' );
    is( $hit2->id, "layer-b", 'hit layer-b' );
};
subtest 'Compositor get_layer' => sub {
    my $a = NewLayer("AAA");
    $a->set_id("alpha");
    my $comp  = NewCompositor($a);
    my $found = $comp->get_layer("alpha");
    ok( defined $found, 'found layer' );
    is( $found->get_id, "alpha", 'correct layer' );
};
subtest 'Compositor z-order rendering' => sub {
    my $back = NewLayer("BACK");
    $back->set_z(0)->set_y(0);
    my $front = NewLayer("FRONT");
    $front->set_z(10)->set_y(1);
    my $comp   = NewCompositor( $front, $back );
    my $result = $comp->render;
    like( $result, qr/BACK/,  'has back' );
    like( $result, qr/FRONT/, 'has front' );
};
subtest 'Compositor LayerHit empty' => sub {
    my $comp = NewCompositor();
    my $hit  = $comp->hit( 0, 0 );
    ok( $hit->empty, 'no hit returns empty' );
};

# ============================================================
# Constants tests
# ============================================================
subtest 'Basic color constants' => sub {
    is( Black,         0,  'Black' );
    is( Red,           1,  'Red' );
    is( Green,         2,  'Green' );
    is( Yellow,        3,  'Yellow' );
    is( Blue,          4,  'Blue' );
    is( Magenta,       5,  'Magenta' );
    is( Cyan,          6,  'Cyan' );
    is( White,         7,  'White' );
    is( BrightBlack,   8,  'BrightBlack' );
    is( BrightRed,     9,  'BrightRed' );
    is( BrightGreen,   10, 'BrightGreen' );
    is( BrightYellow,  11, 'BrightYellow' );
    is( BrightBlue,    12, 'BrightBlue' );
    is( BrightMagenta, 13, 'BrightMagenta' );
    is( BrightCyan,    14, 'BrightCyan' );
    is( BrightWhite,   15, 'BrightWhite' );
};
subtest 'Underline style constants' => sub {
    is( UnderlineNone,   0, 'None' );
    is( UnderlineSingle, 1, 'Single' );
    is( UnderlineDouble, 2, 'Double' );
    is( UnderlineCurly,  3, 'Curly' );
    is( UnderlineDotted, 4, 'Dotted' );
    is( UnderlineDashed, 5, 'Dashed' );
};
subtest 'NoTabConversion constant' => sub {
    is( NoTabConversion, -1, 'NoTabConversion' );
};

# ============================================================
# Bug fix tests
# ============================================================
subtest 'Strikethrough uses SGR 9' => sub {
    my $s = NewStyle->bold(1)->strikethrough(1)->render("test");
    like( $s, qr/;9m/, 'strikethrough is SGR 9' );
    unlike( $s, qr/\e\[4:2m/, 'not double-underline' );
};
subtest 'Inline setter respects argument' => sub {
    my $s1 = NewStyle->inline(1);
    ok( $s1->get_inline, 'inline(1) sets' );
    my $s2 = $s1->inline(0);
    ok( !$s2->get_inline, 'inline(0) unsets' );
};
subtest 'Color_whitespace setter respects argument' => sub {
    my $s1 = NewStyle->color_whitespace(1);
    ok( $s1->get_color_whitespace, 'color_whitespace(1) sets' );
    my $s2 = $s1->color_whitespace(0);
    ok( !$s2->get_color_whitespace, 'color_whitespace(0) unsets' );
};
subtest 'Border side setters respect arguments' => sub {
    my $s = NewStyle;
    $s = $s->border_top(1);
    ok( $s->get_border_top, 'border_top(1) sets' );
    $s = $s->border_top(0);
    ok( !$s->get_border_top, 'border_top(0) unsets' );
    $s = $s->border_right(1);
    ok( $s->get_border_right, 'border_right(1) sets' );
    $s = $s->border_right(0);
    ok( !$s->get_border_right, 'border_right(0) unsets' );
};

# ============================================================
# Missing getters tests
# ============================================================
subtest 'get_underline_spaces' => sub {
    my $s = NewStyle->underline_spaces(1);
    ok( $s->get_underline_spaces, 'set' );
    my $s2 = $s->underline_spaces(0);
    ok( !$s2->get_underline_spaces, 'unset' );
};
subtest 'get_strikethrough_spaces' => sub {
    my $s = NewStyle->strikethrough_spaces(1);
    ok( $s->get_strikethrough_spaces, 'set' );
};
subtest 'get_align' => sub {
    my $s = NewStyle->align_horizontal(Center);
    is( $s->get_align, Center, 'get_align returns horizontal' );
};
subtest 'get_frame_size' => sub {
    my $s = NewStyle->padding( 2, 3 );
    my ( $h, $v ) = $s->get_frame_size;
    ok( defined $h, 'horizontal frame defined' );
    ok( defined $v, 'vertical frame defined' );
};
subtest 'get_border_top/bottom/left/right' => sub {
    my $s = NewStyle->border_top(1)->border_left(1);
    ok( $s->get_border_top,     'top set' );
    ok( !$s->get_border_right,  'right unset' );
    ok( !$s->get_border_bottom, 'bottom unset' );
    ok( $s->get_border_left,    'left set' );
};
subtest 'get_border_*_size' => sub {
    my $s = NewStyle->border(NormalBorder)->border_top(1)->border_left(1);
    is( $s->get_border_top_size,    1, 'top size' );
    is( $s->get_border_left_size,   1, 'left size' );
    is( $s->get_border_right_size,  1, 'right size (set via border(NormalBorder))' );
    is( $s->get_border_bottom_size, 1, 'bottom size (set via border(NormalBorder))' );
};

# ============================================================
# Missing unsetters tests
# ============================================================
subtest 'unset_padding_char' => sub {
    my $s = NewStyle->padding_char('*');
    $s = $s->unset_padding_char;
    is( $s->get_padding_char, ord(' '), 'padding char reset to space' );
};
subtest 'unset_underline_spaces' => sub {
    my $s = NewStyle->underline_spaces(1);
    $s = $s->unset_underline_spaces;
    ok( !$s->get_underline_spaces, 'unset underline_spaces' );
};
subtest 'unset_hyperlink' => sub {
    my $s = NewStyle->hyperlink("https://example.com");
    $s = $s->unset_hyperlink;
    my ( $url, $params ) = $s->get_hyperlink;
    is( $url, '', 'url cleared' );
};
subtest 'unset_string' => sub {
    my $s = NewStyle->set_string("hello");
    $s = $s->unset_string;
    is( $s->value, '', 'string cleared' );
};
subtest 'unset_border_foreground' => sub {
    my $s = NewStyle->border_foreground( Cancer::Lipgloss::Color("#FF0000") );
    $s = $s->unset_border_foreground;
    ok( $s->get_border_top_fg->is_no_color, 'top fg cleared' );
};
subtest 'unset_border_background' => sub {
    my $s = NewStyle->border_background( Cancer::Lipgloss::Color("#00FF00") );
    $s = $s->unset_border_background;
    ok( $s->get_border_top_bg->is_no_color, 'top bg cleared' );
};

# ============================================================
# Border preset tests
# ============================================================
subtest 'OuterHalfBlockBorder' => sub {
    my $b = OuterHalfBlockBorder;
    ok( defined $b->{top},  'has top' );
    ok( defined $b->{left}, 'has left' );
};
subtest 'InnerHalfBlockBorder' => sub {
    my $b = InnerHalfBlockBorder;
    ok( defined $b->{top},  'has top' );
    ok( defined $b->{left}, 'has left' );
};

# ============================================================
# Print/Sprint family tests
# ============================================================
subtest 'Sprint returns string' => sub {
    my $s      = NewStyle->bold(1)->foreground( Cancer::Lipgloss::Color("#FF0000") )->render("hi");
    my $result = Sprint( "test ", $s );
    like( $result, qr/test/, 'Sprint contains text' );
};
subtest 'Sprintln adds newline' => sub {
    my $result = Sprintln("hello");
    like( $result, qr/hello\n$/, 'Sprintln ends with newline' );
};
subtest 'Sprintf formats and downsamples' => sub {
    my $result = Sprintf( "value: %d", 42 );
    is( $result, "value: 42", 'Sprintf formats correctly' );
};

# ============================================================
# WhitespaceOptions tests
# ============================================================
subtest 'Place with whitespace chars' => sub {
    my $result = Place( 10, 3, Center, Center, "hi", WithWhitespaceChars("*") );
    like( $result, qr/\*/, 'contains whitespace char' );
};
done_testing;
