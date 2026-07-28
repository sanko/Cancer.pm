use Test2::V0;
use lib '../lib';
use Cancer;
#
#~ use Data::Dump;
my $cancer = Cancer->new();

#~ ddx $cancer;
my $text = "[bold red]easy[/bold red] [bold green on red]This text.[/bold green on red]between

tags [italic]More text.[/][Test]Last bit\[escaped] not in a tag\[/escaped] of [text[bold]Bold[/bold]";
my @tokens = $cancer->parse($text);

#~ ddx \@tokens;
print $cancer->render( \@tokens );
#
done_testing;
