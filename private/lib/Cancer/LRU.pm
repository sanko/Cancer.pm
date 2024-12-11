use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';

class Cancer::LRU {
    field $capacity : param : reader //= 128;
    field %cache : reader;
    field @order : reader;

    method set( $key, $value ) {
        if ( exists $cache{$key} ) {
            @order = ( $key, grep { $_ ne $key } @order );
            return $cache{$key} = $value;
        }
        delete $cache{ pop @order } if scalar @order >= $capacity;
        @order = ( $key, grep { $_ ne $key } @order );
        $cache{$key} = $value;
    }

    method get($key) {
        return () unless exists $cache{$key};
        @order = ( $key, grep { $_ ne $key } @order );
        $cache{$key};
    }

    method del($key) {
        return () unless delete $cache{$key} // ();
        @order = grep { $_ ne $key } @order;
    }
    method clear() { @order = %cache = (); 1 }
};
1;
__END__
=encoding utf-8

=head1 NAME

Cancer::LRU - I'm afraid it's terminal...

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
