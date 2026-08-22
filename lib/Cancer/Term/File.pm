use v5.42;

package Cancer::Term::File v0.0.1 {
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[ is_file_like file_fd ] ] );
    use Carp         qw[croak];
    use Scalar::Util qw[openhandle blessed];
    #
    sub is_file_like ($thing) { openhandle $thing }

    sub file_fd ($thing) {
        my $h = openhandle($thing);
        return undef unless defined $h;
        my $fd = fileno($h);

        # Tied or otherwise fake handles can report no descriptor; callers must
        # never hand an undefined fd to syscall/ioctl.
        return undef unless defined $fd && $fd >= 0;
        return $fd;
    }
}
1;
