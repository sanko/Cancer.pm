use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';

package Cancer::Markup {
    use Exporter 'import';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = ( 'escape', 'render' ) ] );
    my $RE_TAGS    = qr"((\\*)\[([a-z#/@][^[]*?)])";
    my $RE_HANDLER = qr"^([\w.]*?)(\(.*?\))?$";

    class Cancer::Markup::Tag {
        use overload '""' => sub( $s, $a, $b ) {
            $s->name . ' ' . join ' ', @{ $s->parameters };
        };
        field $name : param : reader;
        field $parameters : param : reader //= [];
        #
    };

    sub escape($markup) {
        $markup =~ s/$RE_TAGS/quotemeta($1) . '\\' . $2/gme;
        $markup .= '\\' if $markup =~ /\\[^\\]$/;
        $markup;
    }
    sub _parse($markup)                                                       { }
    sub render( $makrup, $style //= '', $emoji //= 1, $emoji_varient //= () ) { }
};
1;
__END__
=encoding utf-8

=head1 NAME

Cancer::Text - I'm afraid it's terminal...

=head1 SYNOPSIS

    use Cancer;
    ...;

=head1 DESCRIPTION

Rich console stuff

=head1 See Also

TODO

=head1 LICENSE

This software is Copyright (c) 2024 by Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=begin stopwords


=end stopwords

=cut


