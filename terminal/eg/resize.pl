use strict;
use warnings;
use Data::Dump;
use lib '../lib';
#
use Cancer;
use Cancer::terminfo::xterm::256color;
use Carp::Always;
$|++;
#
my $term = Cancer->new(
    winch => sub {

        #~ use Data::Dump; ddx \@_;
        ddx shift->get_win_size;
        warn 'resize';
    }
);
ddx $term->get_win_size;
$term->cls(1);
while (1) {
    use Time::HiRes;
    sleep .01;
}
