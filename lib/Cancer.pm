use v5.40;
use experimental 'class';

package Cancer v0.0.1 {
    use Affix;
    use Acme::Parataxis;

    # These will have better names in the future...
    class Cancer::Ansi {

        method execute( $writer, $string ) {
            my $len = 0;
            try { $len = syswrite $writer, $string; }    # Good enough for now
            catch ($e) {
                return ( $len, $e )
            }
            ( $len, () );
        }
    };

    package Cancer::Lipgloss {
    };

    package Cancer::Bubbles { };
};
1;
__END__
=encoding utf-8

=head1 NAME

Cancer - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;
    ...;

=head1 DESCRIPTION

TODO

=head1 See Also

TODO

=head1 LICENSE

This software is Copyright (c) 2020 by Sanko Robinson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson  L<https://github.com/sanko>

=begin stopwords


=end stopwords

=cut
