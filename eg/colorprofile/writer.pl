use v5.42;
use lib '../../lib';
use Cancer::ColorProfile::Writer;

# Read from stdin and write to stdout through the profile writer.
# Pipe ANSI-colored text into this script to see it downsampled.
#
# Example:
#   echo -e '\e[38;2;107;80;255mHello\e[m' | perl writer.pl
my $w = Cancer::ColorProfile::Writer->new( forward => \*STDOUT );
local $/;
$w->write(<STDIN>);
