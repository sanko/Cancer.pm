use v5.42;

package Cancer::Term v0.0.1 {
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[is_terminal make_raw get_state set_state restore get_size read_password] ] );
    #
    my $backend;    # Load platform backend at compile time

    BEGIN {
        if ( $^O eq 'MSWin32' ) {
            require Cancer::Term::Windows;
            $backend = 'Cancer::Term::Windows';
        }
        else {
            require Cancer::Term::Unix;
            $backend = 'Cancer::Term::Unix';
        }
    }
    sub is_terminal ($fd)           { $backend->is_terminal($fd) }
    sub make_raw    ($fd)           { $backend->make_raw($fd) }
    sub get_state   ($fd)           { $backend->get_state($fd) }
    sub set_state   ( $fd, $state ) { $backend->set_state( $fd, $state ) }
    sub restore     ( $fd, $state ) { $backend->set_state( $fd, $state ) }
    sub get_size    ($fd)           { $backend->get_size($fd) }
    sub read_password($fd) { $backend->read_password($fd) }
};
#
1;
