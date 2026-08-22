use v5.42;
use lib 'lib';
use blib;
use utf8;
use Cancer::Lipgloss qw[
    NewStyle Color Println
    NormalBorder RoundedBorder
    JoinHorizontal JoinVertical Place
    WithWhitespaceChars WithWhitespaceStyle
    has_dark_background LightDark
    blend_1d
    NewLayer NewCompositor
    Left Center Right Top Bottom
    width
];
use constant { WIDTH => 96, COLUMN_WIDTH => 30 };
my $has_dark_bg = 1;
my $light_dark  = LightDark($has_dark_bg);

# General
my $subtle    = $light_dark->( Color("#D9DCCF"), Color("#383838") );
my $highlight = $light_dark->( Color("#874BFD"), Color("#7D56F4") );
my $special   = $light_dark->( Color("#43BF6D"), Color("#73F59F") );
my $divider   = NewStyle->set_string("\x{2022}")->padding( 0, 1 )->foreground($subtle)->render;

sub url ($text) {
    return NewStyle->foreground($special)->render($text);
}

# Tabs
my $active_tab_border = NormalBorder;
$active_tab_border->{top}          = "\x{2500}";
$active_tab_border->{bottom}       = " ";
$active_tab_border->{left}         = "\x{2502}";
$active_tab_border->{right}        = "\x{2502}";
$active_tab_border->{top_left}     = "\x{256D}";
$active_tab_border->{top_right}    = "\x{256E}";
$active_tab_border->{bottom_left}  = "\x{2518}";
$active_tab_border->{bottom_right} = "\x{2514}";
my $tab_border = NormalBorder;
$tab_border->{top}          = "\x{2500}";
$tab_border->{bottom}       = "\x{2500}";
$tab_border->{left}         = "\x{2502}";
$tab_border->{right}        = "\x{2502}";
$tab_border->{top_left}     = "\x{256D}";
$tab_border->{top_right}    = "\x{256E}";
$tab_border->{bottom_left}  = "\x{2534}";
$tab_border->{bottom_right} = "\x{2534}";
my $tab        = NewStyle->border($tab_border)->border_foreground($highlight)->padding( 0, 1 );
my $active_tab = $tab->border($active_tab_border);
my $tab_gap    = $tab->border_top(0)->border_left(0)->border_right(0);

# Title
my $title_style = NewStyle->margin_left(1)->margin_right(5)->padding( 0, 1 )->italic(1)->foreground( Color("#FFF7DB") )->set_string("Lip Gloss");
my $desc_style  = NewStyle->margin_top(1);
my $info_style  = NewStyle->border_style(NormalBorder)->border_top(1)->border_foreground($subtle);

# Dialog
my $dialog_box_style
    = NewStyle->border(RoundedBorder)
    ->border_foreground( Color("#874BFD") )
    ->padding( 1, 0 )
    ->border_top(1)
    ->border_left(1)
    ->border_right(1)
    ->border_bottom(1);
my $button_style        = NewStyle->foreground( Color("#FFF7DB") )->background( Color("#888B7E") )->padding( 0, 3 )->margin_top(1);
my $active_button_style = $button_style->foreground( Color("#FFF7DB") )->background( Color("#F25D94") )->margin_right(2)->underline(1);

# List
my $list        = NewStyle->border( NormalBorder, 0, 1, 0, 0 )->border_foreground($subtle)->margin_right(1)->height(8)->width( WIDTH / 3 );
my $list_header = NewStyle->border_style(NormalBorder)->border_bottom(1)->border_foreground($subtle)->margin_right(2);
sub list_header { return $list_header->render(shift) }
my $list_item = NewStyle->padding_left(2);
sub list_item { return $list_item->render(shift) }
my $check_mark = NewStyle->set_string("\x{2713}")->foreground($special)->padding_right(1)->render;

sub list_done {
    my ($s) = @_;
    return $check_mark . NewStyle->strikethrough(1)->foreground( $light_dark->( Color("#969B86"), Color("#696969") ) )->render($s);
}

# Paragraphs/History
my $history_style
    = NewStyle->align(Left)
    ->foreground( Color("#FAFAFA") )
    ->background($highlight)
    ->margin( 1, 3, 0, 0 )
    ->padding( 1, 2 )
    ->height(19)
    ->width(COLUMN_WIDTH);

# Status Bar
my $status_nugget = NewStyle->foreground( Color("#FFFDF5") )->padding( 0, 1 );
my $status_bar_style
    = NewStyle->foreground( $light_dark->( Color("#343433"), Color("#C1C6B2") ) )->background( $light_dark->( Color("#D9DCCF"), Color("#353533") ) );
my $status_style
    = NewStyle->inherit($status_bar_style)->foreground( Color("#FFFDF5") )->background( Color("#FF5F87") )->padding( 0, 1 )->margin_right(1);
my $encoding_style  = $status_nugget->background( Color("#A550DF") )->align(Right);
my $status_text     = NewStyle->inherit($status_bar_style);
my $fish_cake_style = $status_nugget->background( Color("#6124DF") );

# Floating thing
my $floating_style = NewStyle->italic(1)->foreground( Color("#FFF7DB") )->background( Color("#F25D94") )->padding( 1, 6 )->align(Center);

# Page
my $doc_style = NewStyle->padding( 1, 2, 1, 2 );

# ---- Helpers ----
sub color_grid {
    my ( $x_steps, $y_steps ) = @_;
    my @left_colors  = @{ blend_1d( $y_steps, Color("#F25D94"), Color("#643AFF") ) };
    my @right_colors = @{ blend_1d( $y_steps, Color("#EDFF82"), Color("#14F9D5") ) };
    my @grid;
    for my $y ( 0 .. $y_steps - 1 ) {
        my @row = @{ blend_1d( $x_steps, $left_colors[$y], $right_colors[$y] ) };
        push @grid, \@row;
    }
    return \@grid;
}

sub apply_gradient {
    my ( $base, $input, $from, $to ) = @_;
    my @chars    = Cancer::Lipgloss::_graphemes($input);
    my @gradient = @{ blend_1d( scalar @chars, $from, $to ) };
    my $output   = '';
    for my $i ( 0 .. $#chars ) {
        $output .= $base->foreground( $gradient[$i] )->render( $chars[$i] );
    }
    return $output;
}

# ---- Build document ----
my $doc = '';

# Tabs
{
    my $row = JoinHorizontal(
        Top,
        $active_tab->render("Lip Gloss"),
        $tab->render("Blush"),
        $tab->render("Eye Shadow"),
        $tab->render("Mascara"),
        $tab->render("Foundation")
    );
    my $gap = $tab_gap->render( " " x ( WIDTH - width($row) - 2 > 0 ? WIDTH - width($row) - 2 : 0 ) );
    $row = JoinHorizontal( Bottom, $row, $gap );
    $doc .= $row . "\n\n";
}

# Title
{
    my $colors = color_grid( 1, 5 );
    my $title  = '';
    for my $i ( 0 .. $#$colors ) {
        my $offset = 2;
        $title .= $title_style->margin_left( $i * $offset )->background( $colors->[$i][0] )->render;
        $title .= "\n" if $i < $#$colors;
    }
    my $desc = JoinVertical(
        Left,
        $desc_style->render("Style Definitions for Nice Terminal Layouts"),
        $info_style->render( "From Charm" . $divider . url("https://github.com/charmbracelet/lipgloss") )
    );
    my $row = JoinHorizontal( Top, $title, $desc );
    $doc .= $row . "\n\n";
}

# Dialog
{
    my $ok_button     = $active_button_style->render("Yes");
    my $cancel_button = $button_style->render("Maybe");
    my $grad          = apply_gradient( NewStyle, "Are you sure you want to eat marmalade?", Color("#EDFF82"), Color("#F25D94") );
    my $question      = NewStyle->width(50)->align(Center)->render($grad);
    my $buttons       = JoinHorizontal( Top, $ok_button, $cancel_button );
    my $ui            = JoinVertical( Center, $question, $buttons );
    my $dialog        = Place(
        WIDTH, 9, Center, Center,
        $dialog_box_style->render($ui),
        WithWhitespaceChars("\x{732B}\x{54AA}"),
        WithWhitespaceStyle( NewStyle->foreground($subtle) )
    );
    $doc .= $dialog . "\n\n";
}

# Color grid
my $colors = sub {
    my $grid = color_grid( 14, 8 );
    my $b    = '';
    for my $row (@$grid) {
        for my $c (@$row) {
            $b .= NewStyle->set_string("  ")->background($c)->render;
        }
        $b .= "\n";
    }
    return $b;
    }
    ->();
my $lists = JoinHorizontal(
    Top,
    $list->render(
        JoinVertical(
            Left, list_header("Citrus Fruits to Try"), list_done("Grapefruit"), list_done("Yuzu"),
            list_item("Citron"), list_item("Kumquat"), list_item("Pomelo")
        )
    ),
    $list->render(
        JoinVertical(
            Left,             list_header("Actual Lip Gloss Vendors"), list_item("Glossier"), list_item("Claire\x{2018}s Boutique"),
            list_done("Nyx"), list_item("Mac"), list_done("Milk")
        )
    )
);
$doc .= JoinHorizontal( Top, $lists, NewStyle->margin_left(1)->render($colors) );

# Marmalade history
{
    my $history_a
        = 'The Romans learned from the Greeks that quinces slowly cooked with honey would “set” when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos.';
    my $history_b
        = 'Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac.';
    my $history_c
        = 'In 1524, Henry VIII, King of England, received a “box of marmalade” from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting.';
    $doc .= JoinHorizontal(
        Top,
        $history_style->align(Right)->render($history_a),
        $history_style->align(Center)->render($history_b),
        $history_style->margin_right(0)->render($history_c)
    );
    $doc .= "\n\n";
}

# Status bar
{
    my $light_dark_state = $has_dark_bg ? "Dark" : "Light";
    my $status_key       = $status_style->render("STATUS");
    my $encoding         = $encoding_style->render("UTF-8");
    my $fish_cake        = $fish_cake_style->render("\x{1F365} Fish Cake");
    my $status_val       = $status_text->width( WIDTH - width($status_key) - width($encoding) - width($fish_cake) )
        ->render( "Ravishingly " . $light_dark_state . "!" );
    my $bar = JoinHorizontal( Top, $status_key, $status_val, $encoding, $fish_cake );
    $doc .= $status_bar_style->width(WIDTH)->render($bar);
}

# Render the document
my $document = $doc_style->render($doc);

# Composite the floating modal on top
my $modal  = $floating_style->render("Now with Compositing!");
my @layers = ( NewLayer($document), NewLayer($modal)->X(58)->Y(44) );
my $comp   = NewCompositor(@layers);
Println( $comp->render );
