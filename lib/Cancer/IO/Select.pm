package Cancer::IO::Select 0.01 {    # Internal, Pure Perl event loop
    use strict;
    use warnings;
    use Moo::Role;
    use Types::Standard qw[InstanceOf];
    use IO::Select;
    use experimental 'signatures';
    #
    has select => (
        is       => 'ro',
        isa      => InstanceOf ['IO::Select'],
        required => 1,
        lazy     => 1,
        builder  => sub { IO::Select->new() }
    );
    sub add_fh ( $s, $fh ) { $s->select->add( $s->tty ) }

    sub peek_event ( $s, $timeout = .1 ) {

        # Try to empty the queue first
        my $event = $s->_parseEventsFromInput();
        #
        if ( my @ready = $s->select->can_read($timeout) ) {    # Only one fh...
            for my $fh (@ready) {
                sysread $fh, my ($retval), 1024;
                $s->_unused_data( $s->_unused_data . $retval ) if defined $retval;

                #$s->write_at( 10, 11, 'w: ' . length( $s->_unused_data() ) . '              ' );
            }
        }
        return $event if $event;
    }
}
1;
