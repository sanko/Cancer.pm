use v5.42;

package Cancer::CellBuf::Cell v0.0.1 {
    use Carp qw[carp];
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

    sub new ( $class, %args ) {
        bless {
            rune  => $args{rune}  // 0,
            comb  => $args{comb}  // [],
            width => $args{width} // 0,
            style => $args{style} // undef,
            link  => $args{link}  // undef
        }, $class;
    }
    sub rune      ($self)       { $self->{rune} }
    sub comb      ($self)       { $self->{comb} }
    sub width     ($self)       { $self->{width} }
    sub style     ($self)       { $self->{style} }
    sub link      ($self)       { $self->{link} }
    sub set_style ( $self, $s ) { $self->{style} = $s; $self }
    sub set_link  ( $self, $l ) { $self->{link}  = $l; $self }

    sub string ($self) {
        return '' unless $self->{rune};
        my $s = chr( $self->{rune} );
        $s .= chr($_) for @{ $self->{comb} };
        return $s;
    }

    sub append ( $self, @runes ) {
        for my $i ( 0 .. $#runes ) {
            if ( $i == 0 && $self->{rune} == 0 ) {
                $self->{rune} = $runes[$i];
            }
            else {
                push @{ $self->{comb} }, $runes[$i];
            }
        }
        $self;
    }

    sub empty ($self) {
        $self->{width} == 0 && $self->{rune} == 0 && !@{ $self->{comb} };
    }

    sub clear ($self) {
        $self->{rune} == ord(' ')                        &&
            !@{ $self->{comb} }                          &&
            $self->{width} == 1                          &&
            ( !$self->{style} || $self->{style}->clear ) &&
            ( !$self->{link} || $self->{link}->empty );
    }

    sub reset ($self) {
        $self->{rune}  = 0;
        $self->{comb}  = [];
        $self->{width} = 0;
        $self->{style}->reset if $self->{style};
        $self->{link}->reset  if $self->{link};
        $self;
    }

    sub clone ($self) {
        my $clone = {%$self};
        $clone->{comb}  = [ @{ $self->{comb} } ] if @{ $self->{comb} };
        $clone->{style} = $self->{style}->clone  if $self->{style};
        $clone->{link}  = $self->{link}->clone   if $self->{link};
        bless $clone, ref $self;
    }

    sub blank ($self) {
        $self->{rune}  = ord(' ');
        $self->{comb}  = [];
        $self->{width} = 1;
        $self;
    }

    sub equal ( $self, $other ) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $self->{width} == $other->{width}                   &&
            $self->{rune} == $other->{rune}                 &&
            _runes_equal( $self->{comb}, $other->{comb} )   &&
            _style_equal( $self->{style}, $other->{style} ) &&
            _link_equal( $self->{link}, $other->{link} );
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
}
1;
