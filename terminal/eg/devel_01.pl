use strict;
use warnings;
use lib '../lib';
use Cancer;
use Data::Dump;
use v5.36;
#
$|++;
#
#
my $cancer = Cancer->new(
    color_system => 256,
    encoding     => 'utf-8',

    #~ is_terminal  => 1,
    color_system => Cancer::ColorSystem::TRUECOLOR(),

    #~ size =>
);

=python
╭─────────────────────── <class 'rich.console.Console'> ───────────────────────╮
│ A high level console interface.                                              │
│                                                                              │
│ ╭──────────────────────────────────────────────────────────────────────────╮ │
│ │ <console width=80 ColorSystem.TRUECOLOR>                                 │ │
│ ╰──────────────────────────────────────────────────────────────────────────╯ │
│                                                                              │
│     color_system = 'truecolor'                                               │
│         encoding = 'utf-8'                                                   │
│             file = <_io.TextIOWrapper name='<stdout>' mode='w'               │
│                    encoding='utf-8'>                                         │
│           height = 25                                                        │
│    is_alt_screen = False                                                     │
│ is_dumb_terminal = False                                                     │
│   is_interactive = False                                                     │
│       is_jupyter = False                                                     │
│      is_terminal = False                                                     │
│   legacy_windows = False                                                     │
│         no_color = False                                                     │
│          options = ConsoleOptions(                                           │
│                        size=ConsoleDimensions(width=80, height=25),          │
│                        legacy_windows=False,                                 │
│                        min_width=1,                                          │
│                        max_width=80,                                         │
│                        is_terminal=False,                                    │
│                        encoding='utf-8',                                     │
│                        max_height=25,                                        │
│                        justify=None,                                         │
│                        overflow=None,                                        │
│                        no_wrap=False,                                        │
│                        highlight=None,                                       │
│                        markup=None,                                          │
│                        height=None                                           │
│                    )                                                         │
│            quiet = False                                                     │
│           record = False                                                     │
│         safe_box = True                                                      │
│             size = ConsoleDimensions(width=80, height=25)                    │
│        soft_wrap = False                                                     │
│           stderr = False                                                     │
│            style = None                                                      │
│         tab_size = 8                                                         │
│            width = 80                                                        │
╰──────────────────────────────────────────────────────────────────────────────╯
=cut

my $list = [
    Cancer::move_to( 5, 5 ),
    Cancer::bell,
    Cancer::Segment->new(
      text=>  "hi " . ":smile: 😄",
        ,style => Cancer::Style->new( blink => 1, bold => 1, color => Cancer::Color->new(color=>'#339933'), bgcolor => Cancer::Color->new(color=>'#0fc') )
    ),
    Cancer::newline(3),
    Cancer::Segment->new( text =>'hi', style=> Cancer::Style->new( italic => 1 ) ),
    Cancer::newline
];
#~ ddx $list;
print $cancer->render($list);
#~ my %hash;
#~ CORE::say sprintf '%s() {"%s"}', $_, $hash{$_} for sort keys %hash;
#~ ddx \%hash;
__END__
│ │ │   │   │   color=Color('red', ColorType.STANDARD, number=1),      │ │
│ │ │   │   │   bgcolor=Color(                                         │ │
│ │ │   │   │   │   '#ff94ff',                                         │ │
│ │ │   │   │   │   ColorType.TRUECOLOR,                               │ │
│ │ │   │   │   │   triplet=ColorTriplet(                              │ │
│ │ │   │   │   │   │   red=255,                                       │ │
│ │ │   │   │   │   │   green=148,                                     │ │
│ │ │   │   │   │   │   blue=255                                       │ │
│ │ │   │   │   │   )                                                  │ │
│ │ │   │   │   ),

https://rich.readthedocs.io/en/stable/style.html
https://github.com/Textualize/rich/blob/26152e9cc95eef9c8f363d7bf1dfda426275348d/rich/segment.py#L56


