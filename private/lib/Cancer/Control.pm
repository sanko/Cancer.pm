use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';
use Cancer::Segment;

package Cancer::Control {
    use Exporter 'import';
    no warnings 'misc';
    our $CONTROL_ESCAPE       = { 7 => "\a", 8 => "\b", 11 => "\v", 12 => "\f", 13 => "\r" };
    our $CONTROL_CODES_FORMAT = {
        $Cancer::Segment::ControlType->{BELL}                  => sub () {"\x07"},
        $Cancer::Segment::ControlType->{CARRIAGE_RETURN}       => sub () {"\r"},
        $Cancer::Segment::ControlType->{HOME}                  => sub () {"\x1b[H"},
        $Cancer::Segment::ControlType->{CLEAR}                 => sub () {"\x1b[2J"},
        $Cancer::Segment::ControlType->{ENABLE_ALT_SCREEN}     => sub () {"\x1b[?1049h"},
        $Cancer::Segment::ControlType->{DISABLE_ALT_SCREEN}    => sub () {"\x1b[?1049l"},
        $Cancer::Segment::ControlType->{SHOW_CURSOR}           => sub () {"\x1b[?25h"},
        $Cancer::Segment::ControlType->{HIDE_CURSOR}           => sub () {"\x1b[?25l"},
        $Cancer::Segment::ControlType->{CURSOR_UP}             => sub ($param) {"\x1b[${param}A"},
        $Cancer::Segment::ControlType->{CURSOR_DOWN}           => sub ($param) {"\x1b[${param}B"},
        $Cancer::Segment::ControlType->{CURSOR_FORWARD}        => sub ($param) {"\x1b[${param}C"},
        $Cancer::Segment::ControlType->{CURSOR_BACKWARD}       => sub ($param) {"\x1b[${param}D"},
        $Cancer::Segment::ControlType->{CURSOR_MOVE_TO_COLUMN} => sub ($param) { "\x1b[" . ( $param + 1 ) . "G" },
        $Cancer::Segment::ControlType->{ERASE_IN_LINE}         => sub ($param) {"\x1b[${param}K"},
        $Cancer::Segment::ControlType->{CURSOR_MOVE_TO}        => sub ( $x, $y ) { "\x1b[" . ( $y + 1 ) . ";" . ( $x + 1 ) . "H" },
        $Cancer::Segment::ControlType->{SET_WINDOW_TITLE}      => sub ($title) {"\x1b]0;${title}\x07"}
    };
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = ( $CONTROL_ESCAPE, 'strip_control_codes', 'escape_control_codes' ) ] );
    #
    class Cancer::Control {
        field $_slots;
        field $control_codes : param(codes);
        field $_format_map = $CONTROL_CODES_FORMAT;

        #~ field $rendered_codes = join '', $_format_map{
        #~ field $segment = Cancer::Segment->new($rendered_codes, (), $control_codes);
        #
        method bell() { $Cancer::Segment::CONTROL_TYPE{BELL}->() }
        method home() { $Cancer::Segment::CONTROL_TYPE{HOME}->() }

        method move( $x //= 0, $y //= 0 ) {
            my $ret;
            $ret .= ( $x > 0 ? $Cancer::Segment::CONTROL_TYPE{CURSOR_FORWARD}->() : $Cancer::Segment::CONTROL_TYPE{CURSOR_BACKWARD}->() ) . abs($x)
                if $x;
            $ret .= ( $y > 0 ? $Cancer::Segment::CONTROL_TYPE{CURSOR_DOWN}->() : $Cancer::Segment::CONTROL_TYPE{CURSOR_UP}->() ) . abs($y) if $y;
            $ret;
        }

        method move_to_column( $x, $y //= 0 ) {
            return
                $Cancer::Segment::CONTROL_TYPE{CURSOR_MOVE_TO_COLUMN}->($x) . $y > 0 ? $Cancer::Segment::CONTROL_TYPE{CURSOR_DOWN}->( abs $y ) :
                $Cancer::Segment::CONTROL_TYPE{CURSOR_UP}->( abs $y )
                if $y;
            $Cancer::Segment::CONTROL_TYPE{CURSOR_MOVE_TO_COLUMN}->($x);
        }

        method move_to( $x, $y ) {
            $Cancer::Segment::CONTROL_TYPE{CURSOR_MOVE_TO}->( $x, $y );
        }

        method clear() {
            $Cancer::Segment::CONTROL_TYPE{CLEAR}->();
        }

        method show_cursor($show) {
            $show ? $Cancer::Segment::CONTROL_TYPE{SHOW_CURSOR}->() : $Cancer::Segment::CONTROL_TYPE{HIDE_CURSOR}->();
        }

        method alt_screen($enable) {
            $enable ? $Cancer::Segment::CONTROL_TYPE{ENABLE_ALT_SCREEN}->() . $Cancer::Segment::CONTROL_TYPE{HOME}->() :
                $Cancer::Segment::CONTROL_TYPE{DISABLE_ALT_SCREEN}->();
        }

        method title($title) {
            $Cancer::Segment::CONTROL_TYPE{SET_WINDOW_TITLE}->($title);
        }
    }

    sub strip_control_codes( $text, $translate_table //= qr[[\a\b\f\v\r]]x ) {
        $text =~ s[$translate_table][]g;
        $text;
    }

    sub escape_control_codes( $text, $translate_table //= qr[]x ) {
        $text =~ s[($translate_table)][\\$1]g;
        $text;
    }
};
1;
__END__
=encoding utf-8

=head1 NAME

Cancer::Control - I'm afraid it's terminal...

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
