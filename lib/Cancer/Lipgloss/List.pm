use v5.42;

package Cancer::Lipgloss::List v0.0.1 {
    use Exporter qw[import];
    our @EXPORT_OK = qw[
        NewList BulletEnumerator DashEnumerator
        AsteriskEnumerator ArabicEnumerator AlphabetEnumerator RomanEnumerator
    ];
    use Cancer::Lipgloss qw[NewStyle string_width];
    use Cancer::Lipgloss::Tree;
    use utf8;

    sub new_list {
        my (@items) = @_;
        my $t       = Cancer::Lipgloss::Tree::new_tree('Cancer::Lipgloss::Tree');
        my $self    = bless { tree => $t }, 'Cancer::Lipgloss::List';
        $self->_apply_defaults;
        $self->Items(@items) if @items;
        return $self;
    }
    sub NewList { new_list(@_) }

    sub Item {
        my ( $self, $item ) = @_;
        if ( ref $item && ref $item eq 'Cancer::Lipgloss::List' ) {
            $self->{tree}->Child( $item->{tree} );
        }
        else {
            $self->{tree}->Child($item);
        }
        return $self;
    }

    sub Items {
        my ( $self, @items ) = @_;
        $self->Item($_) for @items;
        return $self;
    }
    sub Value    { return $_[0]->{tree}->Value }
    sub Hidden   { return $_[0]->{tree}->Hidden }
    sub String   { return $_[0]->{tree}->String }
    sub Children { return $_[0]->{tree}->Children }

    sub Hide {
        $_[0]->{tree}->Hide( $_[1] );
        return $_[0];
    }

    sub SetHidden {
        $_[0]->{tree}->SetHidden( $_[1] );
    }

    sub Offset {
        my ( $self, $start, $end ) = @_;
        $self->{tree}->Offset( $start, $end );
        return $self;
    }

    sub Enumerator {
        my ( $self, $enum ) = @_;

        # List enumerators take (Items, index) — wrap for tree's (Children, index)
        $self->{tree}->Enumerator( sub { return $enum->( $_[0], $_[1] ) } );
        return $self;
    }

    sub Indenter {
        my ( $self, $indent ) = @_;
        $self->{tree}->Indenter( sub { return $indent->( $_[0], $_[1] ) } );
        return $self;
    }

    sub EnumeratorStyle {
        my ( $self, $style ) = @_;
        $self->{tree}->EnumeratorStyle($style);
        return $self;
    }

    sub EnumeratorStyleFunc {
        my ( $self, $fn ) = @_;
        $self->{tree}->EnumeratorStyleFunc( sub { return $fn->( $_[0], $_[1] ) } );
        return $self;
    }

    sub IndenterStyle {
        my ( $self, $style ) = @_;
        $self->{tree}->IndenterStyle($style);
        return $self;
    }

    sub IndenterStyleFunc {
        my ( $self, $fn ) = @_;
        $self->{tree}->IndenterStyleFunc( sub { return $fn->( $_[0], $_[1] ) } );
        return $self;
    }

    sub ItemStyle {
        my ( $self, $style ) = @_;
        $self->{tree}->ItemStyle($style);
        return $self;
    }

    sub ItemStyleFunc {
        my ( $self, $fn ) = @_;
        $self->{tree}->ItemStyleFunc( sub { return $fn->( $_[0], $_[1] ) } );
        return $self;
    }

    sub RootStyle {
        my ( $self, $style ) = @_;
        $self->{tree}->RootStyle($style);
        return $self;
    }

    # Set default enumerator and indenter on construction
    sub _apply_defaults {
        my $self = shift;
        $self->Enumerator( \&BulletEnumerator );
        $self->Indenter( sub { return ' ' } );
        $self->EnumeratorStyle( NewStyle->padding_right(1) );
        return $self;
    }

    # ── Built-in Enumerators ──────────────────────────────────────────
    sub BulletEnumerator   { return "\x{2022}" }
    sub AsteriskEnumerator { return '*' }
    sub DashEnumerator     { return '-' }

    sub ArabicEnumerator {
        my ( undef, $i ) = @_;
        return ( $i + 1 ) . ".";
    }

    sub AlphabetEnumerator {
        my ( undef, $i ) = @_;
        my $base = 'A';
        my $code = ord($base) + ( $i % 26 );
        if ( $i >= 26 * 27 ) {
            my $c3 = chr( ord($base) + int( $i / ( 26 * 26 ) ) - 1 );
            my $c2 = chr( ord($base) + int( ( $i % ( 26 * 26 ) ) / 26 ) - 1 );
            my $c1 = chr( ord($base) + ( $i % 26 ) );
            return "$c3$c2$c1.";
        }
        elsif ( $i >= 26 ) {
            my $c2 = chr( ord($base) + int( $i / 26 ) - 1 );
            my $c1 = chr( ord($base) + ( $i % 26 ) );
            return "$c2$c1.";
        }
        return chr($code) . ".";
    }
    my @ROMAN_ONES  = ( '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX' );
    my @ROMAN_TENS  = ( '', 'X', 'XX', 'XXX', 'XL', 'L', 'LX', 'LXX', 'LXXX', 'XC' );
    my @ROMAN_HUNDS = ( '', 'C', 'CC', 'CCC', 'CD', 'D', 'DC', 'DCC', 'DCCC', 'CM' );
    my @ROMAN_THOUS = ( '', 'M', 'MM', 'MMM' );

    sub RomanEnumerator {
        my ( undef, $i ) = @_;
        my $n = $i + 1;
        my $r = '';
        $r .= $ROMAN_THOUS[ int( $n / 1000 ) ] if $n >= 1000;
        $n %= 1000;
        $r .= $ROMAN_HUNDS[ int( $n / 100 ) ] if $n >= 100;
        $n %= 100;
        $r .= $ROMAN_TENS[ int( $n / 10 ) ] if $n >= 10;
        $n %= 10;
        $r .= $ROMAN_ONES[$n];
        return "$r.";
    }

    # Overload stringification
    use overload '""' => 'String';
}
1;
