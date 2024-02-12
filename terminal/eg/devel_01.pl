use strict;
use warnings;
use lib '../lib';
use Cancer;
my $list = [
    Cancer::Segment->new(
        'hi', Cancer::Style->new( blink => 1, bold => 1, color => Cancer::Color->new('#339933'), bgcolor => Cancer::Color->new('#0fc') )
    ),
    Cancer::Segment->new(' '),
    Cancer::Segment->new( 'hi', Cancer::Style->new( italic => 1 ) ),
    Cancer::Segment->new("\n")
];
ddx $list;
print join '', map { $_->render } @$list;
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
