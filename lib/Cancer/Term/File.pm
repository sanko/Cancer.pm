use v5.42;

package Cancer::Term::File v0.0.1 {
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[ is_file_like file_fd ] ] );
    use Carp         qw[croak];
    use Scalar::Util qw[openhandle];
    #
    sub is_file_like ($thing) { openhandle $thing }
    sub file_fd      ($thing) { fileno $thing }
}
1;
