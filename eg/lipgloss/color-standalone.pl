use v5.42;
use lib 'lib';
use blib;
binmode STDOUT, ':unix:utf8';
use Cancer::Lipgloss qw[
    NewStyle Color LightDark Println JoinVertical
    RoundedBorder has_dark_background
];
my $has_dark_bg = has_dark_background();
my $light_dark  = LightDark($has_dark_bg);
my $frame_style
    = NewStyle->border(RoundedBorder)->border_foreground( $light_dark->( Color("#C5ADF9"), Color("#864EFF") ) )->padding( 1, 3 )->margin( 1, 3 );
my $paragraph_style = NewStyle->width(40)->margin_bottom(1)->align(1);
my $text_style      = NewStyle->foreground( $light_dark->( Color("#696969"), Color("#bdbdbd") ) );
my $keyword_style   = NewStyle->foreground( $light_dark->( Color("#37CD96"), Color("#22C78A") ) )->bold(1);
my $active_button   = NewStyle->padding( 0, 3 )->background( Color("#FF6AD2") )->foreground( Color("#FFFCC2") );
my $inactive_button = $active_button->background( $light_dark->( Color("#988F95"), Color("#978692") ) )
    ->foreground( $light_dark->( Color("#FDFCE3"), Color("#FBFAE7") ) );
my $text = $paragraph_style->render(
    $text_style->render("Are you sure you want to eat that ") . $keyword_style->render("moderatly ripe") . $text_style->render(" banana?") );
my $buttons = $active_button->render("Yes") . "  " . $inactive_button->render("No");
my $block   = $frame_style->render( JoinVertical( 1, $text, $buttons ) );
Println($block);
