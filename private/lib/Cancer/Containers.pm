use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';

package Cancer::Containers {
    use Cancer::Text;

    class Cancer::Renderables {
        method append($renderable) { }
    };
    sub sum(@nums) { my $x = 0; $x += $_ for @nums; $x }

    class Cancer::Lines {
        field @lines : reader;
        method append($line)        { push @lines, Cancer::Text->new( text => $line ); }
        method extend(@lines)       { push @lines, Cancer::Text->new( text => $_ ) for @lines; }
        method pop( $index //= -1 ) { }

        #~ method truncate( $max_width, $overflow //= $self->overflow // $DEFAULT_OVERFLOW, $pad //= () ) {
        method justify( $console, $width, $justify //= 'left', $overflow //= 'fold' ) {
            warn $width;
            warn $justify;
            warn $overflow;
            if ( $justify eq 'left' ) {
                $_->truncate( $width, $overflow, 1 ) for $self->lines;
            }
            elsif ( $justify eq 'center' ) {
                for my $line ( $self->lines ) {
                    warn $line;
                    $line->rstrip;
                    $line->truncate( $width, $overflow );
                    $line->pad_left( int( ( $width - Cancer::Cell::cell_len( $line->plain ) ) / 2 ) );
                    $line->pad_right( $width - Cancer::Cell::cell_len( $line->plain ) );
                }
            }
            elsif ( $justify eq 'right' ) {
                for my $line ( $self->lines ) {
                    $line->rstrip;
                    $line->truncate( $width, $overflow );
                    $line->pad_left( $width - Cancer::Cell::cell_len( $line->plain ) );
                }
            }
            elsif ( $justify eq 'full' ) {
                my $index = 0;
                my @lines;
                for my $line ( $self->lines ) {
                    my @words      = map { Cancer::Text->new( text => $_ ) } split ' ', $line;
                    my $words_size = Cancer::Containers::sum( map { Cancer::Cell::cell_len($_) } @words );
                    my $num_spaces = $#words;
                    my @spaces     = map {1} 0 .. $num_spaces;
                    my $index      = 0;
                    if (@spaces) {
                        while ( ( $words_size + $num_spaces ) < $width ) {
                            $spaces[ scalar @spaces - $index - 1 ]++;
                            $num_spaces++;
                            $index = ( $index + 1 ) % scalar @spaces;
                        }
                    }
                    my @tokens;
                    for my ( $word, $next_word )(@words) {
                        push @tokens, $word;
                        if ( $index < scalar @spaces ) {
                            my $style       = $word->get_style_at_offset( $console, -1 );
                            my $next_style  = $next_word->get_style_at_offset( $console, 0 );
                            my $space_style = $style == $next_style ? $style : $line->style;
                            push @tokens, Cancer::Text->new( text => ( ' ' x $spaces[$index] ), style => $space_style );
                        }
                        warn $word;
                        warn $next_word;
                    }

                    #~ tokens: List[Text] = []
                    #~ for index, (word, next_word) in enumerate(
                    #~      zip_longest(words, words[1:])
                    #~ ):
                    #~ tokens.append(word)
                    #~ if index < len(spaces):
                    #~ style = word.get_style_at_offset(console, -1)
                    #~ next_style = next_word.get_style_at_offset(console, 0)
                    #~ space_style = style if style == next_style else line.style
                    #~ tokens.append(Text(" " * spaces[index], style=space_style))
                    #~ self[line_index] = Text("").join(tokens)
                }
            }
            else {
                use Carp;
                croak 'Unknown justification: ' . $justify;
            }
        }
    };
}
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
