use v5.42;
use experimental 'class';
class Cancer::CellBuf::Cell v0.0.1 {
    use Carp qw[carp];
    field $rune  : param : reader = 0;
    field $comb  : param : reader = [];
    field $width : param : reader = 0;
    field $style : param : reader //= undef;
    field $link  : param : reader //= undef;
    my $BLANK;
    my $EMPTY;

    sub BlankCell {
        $BLANK //= __PACKAGE__->new( rune => ord(' '), width => 1 );
        return $BLANK;
    }

    sub EmptyCell {
        $EMPTY //= __PACKAGE__->new();
        return $EMPTY;
    }
    method set_style ($s) { $style = $s; return $self }
    method set_link  ($l) { $link  = $l; return $self }
    method set_width ($w) { $width = $w; return $self }

    method string () {
        return '' unless $rune;
        my $s = chr($rune);
        $s .= chr($_) for @$comb;
        return $s;
    }

    method append (@runes) {
        for my $i ( 0 .. $#runes ) {
            if ( $i == 0 && $rune == 0 ) {
                $rune = $runes[$i];
            }
            else {
                push @$comb, $runes[$i];
            }
        }
        return $self;
    }

    method empty () {
        $width == 0 && $rune == 0 && !@$comb;
    }

    method clear () {
        $rune == ord(' ') && !@$comb && $width == 1 && ( !$style || $style->clear ) && ( !$link || $link->empty );
    }

    method reset () {
        $rune  = 0;
        $comb  = [];
        $width = 0;
        $style->reset if $style;
        $link->reset  if $link;
        return $self;
    }

    method clone () {
        my @c_comb  = @$comb;
        my $c_style = $style->clone if $style;
        my $c_link  = $link->clone  if $link;
        return __PACKAGE__->new( rune => $rune, comb => \@c_comb, width => $width, style => $c_style, link => $c_link );
    }

    method blank () {
        $rune  = ord(' ');
        $comb  = [];
        $width = 1;
        return $self;
    }

    method equal ($other) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $width == $other->width                   &&
            $rune == $other->rune                 &&
            _runes_equal( $comb, $other->comb )   &&
            _style_equal( $style, $other->style ) &&
            _link_equal( $link, $other->link );
    }

    sub _runes_equal ( $a, $b ) {
        return 1 if !$a && !$b;
        return 0 if !$a || !$b;
        return 0 unless @$a == @$b;
        for my $i ( 0 .. $#$a ) {
            return 0 if $a->[$i] != $b->[$i];
        }
        return 1;
    }

    sub _style_equal ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        $a->equal($b);
    }

    sub _link_equal ( $a, $b ) {
        return 1 if !defined $a && !defined $b;
        return 0 if !defined $a || !defined $b;
        $a->equal($b);
    }
} 1;
