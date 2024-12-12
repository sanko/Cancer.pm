use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';

package Cancer::Console {

    class Cancer::ConsoleDimensions {
        field $width : param : reader;
        field $height : param : reader;
    }

    class Cancer::ConsoleOptions { }

    class Cancer::Console {
        field $style = Cancer::Style->new();    # PLACEHOLDER!!!!!!!!!!!!!!!!!!!!!!!

        method get_style( $name, $default //= () ) {
        }
    }

    class Cancer::Console::Win32 { }
    #
    class Cancer::RichCast { }

    class Cancer::ConsoleRenderable { }

    class Cancer::NewLine { }

    class Cancer::ScreenUpdate { }

    class Cancer::Console::Capture { }

    class Cancer::ThemeContext { }

    class Cancer::PagerContext { }

    class Cancer::ScreenContext { }

    class Cancer::Group { }
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

