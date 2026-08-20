use v5.42;

package Cancer::Term v0.0.1 {
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[is_terminal make_raw get_state set_state restore get_size read_password can_use_term] ] );
    #
    my $backend;    # Load platform backend at compile time

    BEGIN {
        if ( $^O eq 'MSWin32' ) {
            eval { require Cancer::Term::Windows };
            $backend = 'Cancer::Term::Windows' unless $@;
        }
        else {
            eval { require Cancer::Term::Unix };
            $backend = 'Cancer::Term::Unix' unless $@;
        }
    }
    sub can_use_term { defined $backend }
    sub is_terminal ($fd)           { $backend ? $backend->is_terminal($fd)         : 0 }
    sub make_raw    ($fd)           { $backend ? $backend->make_raw($fd)            : undef }
    sub get_state   ($fd)           { $backend ? $backend->get_state($fd)           : undef }
    sub set_state   ( $fd, $state ) { $backend ? $backend->set_state( $fd, $state ) : 0 }
    sub restore     ( $fd, $state ) { $backend ? $backend->set_state( $fd, $state ) : 0 }
    sub get_size    ($fd)           { $backend ? $backend->get_size($fd)            : () }
    sub read_password($fd) { $backend ? $backend->read_password($fd) : undef }
};
#
1;
