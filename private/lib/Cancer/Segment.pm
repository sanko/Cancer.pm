use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';

package Cancer::Segment {
    use Exporter 'import';
    our $ControlType = {
        BELL                  => 1,
        CARRIAGE_RETURN       => 2,
        HOME                  => 3,
        CLEAR                 => 4,
        SHOW_CURSOR           => 5,
        HIDE_CURSOR           => 6,
        ENABLE_ALT_SCREEN     => 7,
        DISABLE_ALT_SCREEN    => 8,
        CURSOR_UP             => 9,
        CURSOR_DOWN           => 10,
        CURSOR_FORWARD        => 11,
        CURSOR_BACKWARD       => 12,
        CURSOR_MOVE_TO_COLUMN => 13,
        CURSOR_MOVE_TO        => 14,
        ERASE_IN_LINE         => 15,
        SET_WINDOW_TITLE      => 16
    };
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = [$ControlType] ] );
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


