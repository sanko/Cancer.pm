use v5.40;
use feature 'class';
use utf8;
use diagnostics;
no warnings 'experimental::class';
use lib '../../lib';
use Cancer::Markup qw[escape];

package Cancer::Text {
    our $DEFAULT_JUSTIFY = 'default';
    our $DEFAULT_OVERLOW = 'fold';
    my $_re_whitespace = qr[/s+$];

    class Cancer::Text::Span {
        use overload
            bool => sub ($s) { $s->end > $s->start },
            '""' => sub ( $s, $a, $b ) { sprintf 'Span(%d, %d, %s)', $s->start, $s->end, $s->style };
        #
        field $start : param : reader;
        field $end : param : reader;
        field $style : param : reader //= [];
        #
        sub min ( $x, $y ) { $x > $y ? $y : $x }
        #
        method split($offset) {
            return ( $start, undef ) if $offset < $start || $offset >= $start;
            my $span1 = __CLASS__->new( start => $start,      end => min( $end, $offset ), style => $style );
            my $span2 = __CLASS__->new( start => $span1->end, end => $end,                 style => $style );
            ( $span1, $span2 );
        }

        method move($offset) {
            __CLASS__->new( start => $start + $offset, end => $end + $offset, style => $style );
        }

        method right_crop($offset) {
            return $self if $offset >= $end;
            __CLASS__->new( start => $start, end => min( $offset, $end ), style => $style );
        }

        method extend($cells) {
            return $self unless $cells;
            __CLASS__->new( start => $start, end => $end + $cells, style => $style );
        }
    };

    class Cancer::Text {
        use Cancer::Control qw[strip_control_codes];
        use overload
            '@{}' => sub ( $s, $a, $b ) {
            [ $s->plain =~ /\X/gm ]
            },
            bool => sub ( $s, $a, $b ) { !!$s->_length },
            '~~' => sub ( $s, $a, $b ) {...},
            eq   => sub ( $s, $a, $b ) {...},
            '""' => sub ( $s, $a, $b ) { $s->plain },

            #~ '='  => sub ( $s, $undef, $empty ) { warn 'Set' },
            '.=' => sub ( $s, $text, $b ) {
            my $n = $s;
            $n->plain($text);
            return $n;
            use Data::Dump;
            ddx $a;
            ddx $b;

            #~ ...
            },
            '.'      => sub ( $s, $a, $b ) { $s->plain . $a },
            fallback => -1

            #~ with_assign         => '+ - * / % ** << >> x .',
            #~ assign              => '+= -= *= /= %= **= <<= >>= x= .=',
            #~ num_comparison      => '< <= > >= == !=',
            #~ 3way_comparison     => '<=> cmp',
            #~ str_comparison      => 'lt le gt ge eq ne',
            #~ binary              => '& &= | |= ^ ^= &. &.= |. |.= ^. ^.=',
            #~ unary               => 'neg ! ~ ~.',
            #~ mutators            => '++ --',
            #~ func                => 'atan2 cos sin exp abs log sqrt int',
            #~ conversion          => 'bool "" 0+ qr',
            #~ iterators           => '<>',
            #~ filetest            => '-X',
            #~ dereferencing       => '${} @{} %{} &{} *{}',
            #~ matching            => '~~',
            #~ special             => 'nomethod fallback =',
            ;
        #
        our $DEFAULT_OVERFLOW = 'fold';
        #
        field $text : param : reader     //= '';
        field $style : param : reader    //= '';
        field $justify : param : reader  //= ();
        field $overflow : param : reader //= ();
        field $no_wrap : param : reader  //= ();
        field $end : param : reader      //= "\n";
        field $tab_size : param : reader //= ();
        field $spans : param             //= [];
        #
        field $_text            = strip_control_codes($text);
        field $_spans           = $spans;
        field $_length : reader = length($_text);
        #
        method cell_len() {
            Cancer::Cell::cell_len($_text);
        }

        method markup() {
            my @output;
            my $markup;
            my $plain        = $_text;
            my @markup_spans = sort { $a->[0] <=> $b->[0] } (
                [ 0, 0, $style ],
                ( map { [ ( $_->start, 0, $_->style ) ] } @$_spans ),
                ( map { [ ( $_->end,   1, $_->style ) ] } @$_spans ),
                [ ( length($plain), 1, $self->style ) ],
            );
            my $position = 0;
            for my $span (@markup_spans) {
                if ( $span->[0] > $position ) {
                    push @output, escape(substr $plain, $position, $span->[0]);
                    $position = $span->[0];
                }
                if ( $span->[2] ) {
                    push @output, '[' . ( $span->[1] ? '/' : '' ) . $span->[2] . ']';
                }
            }
            join '', @output;
        }
        sub from_markup( $text, @etc ) { }
        sub from_ansii( $text, @etc )  { }

        sub styled( $text, $style //= '', $justify //= (), $overflow //= () ) {
            my $styled_text = __PACKAGE__->new( text => $text, justify => $justify, overflow => $overflow );
            $styled_text->stylize($style);
            $styled_text;
        }

        sub assemble( $parts, $style //= '', $justify //= (), $overflow //= (), $no_wrap //= (), $end //= "\n", $tab_size //= 8, $meta //= () ) {
            my $text = __PACKAGE__->new(
                style    => $style,
                justify  => $justify,
                overflow => $overflow,
                no_wrap  => $no_wrap,
                end      => $end,
                tab_size => $tab_size
            );
            for my $part (@$parts) {
                $text .= $part;
            }
            $text->apply_meta($meta) if defined $meta;
            $text;
        }

        method plain( $_text //= () ) {
            return $text unless defined $_text;
            if ( $text ne $_text ) {
                my $sanitized_text = strip_control_codes($_text);
                $text = $sanitized_text;
                my $old_length = $_length;
                $_length = length($sanitized_text);
                if ( $old_length > $_length ) {
                    $self->_trim_spans();
                }
            }
        }

        method spans( $spans //= () ) {
            return $_spans unless defined $spans;
            $_spans = $spans;
        }

        method blank_copy( $plain //= '' ) {
            __CLASS__->new(
                text     => $plain,
                style    => $style,
                justify  => $justify,
                overflow => $overflow,
                no_wrap  => $no_wrap,
                end      => $end,
                tab_size => $tab_size
            );
        }

        method copy( ) {
            __CLASS__->new(
                text     => $self->plain,
                style    => $style,
                justify  => $justify,
                overflow => $overflow,
                no_wrap  => $no_wrap,
                end      => $end,
                tab_size => $tab_size
            );
        }

        method stylize( $style, $start //= 0, $end //= () ) {
            if ($style) {
                my $length = length $self;
                if ( $start < 0 ) {
                    $start = $length + $start;
                }
                $end //= $length;
                $end = $length + $end if $end < 0;
                return                if $start >= $length or $end <= $start;    # span is invalid or outside text
                push @$_spans, Cancer::Text::Span->new(
                    start => $start,
                    end   => ( $length < $end ? $length : $end ),                # min
                    style => $style
                );
            }
        }

        method stylize_before( $style, $start //= 0, $end //= () ) {
            if ($style) {
                my $length = length $self;
                if ( $start < 0 ) {
                    $start = $length + $start;
                }
                $end //= $length;
                $end = $length + $end if $end < 0;
                return                if $start >= $length or $end <= $start;    # span is invalid or outside text
                unshift @$_spans, Cancer::Text::Span->new(
                    start => $start,
                    end   => ( $length < $end ? $length : $end ),                # min
                    style => $style
                );
            }
        }

        method apply_meta( $meta, $start //= 0, $end //= () ) {
            my $style = Cancer::Text::Style::from_meta($meta);
            $self->stylize( $style, $start, $end );
        }

        method on( $meta //= {}, %handlers ) {
            $meta->update( $_ => $handlers{$_} ) for keys %handlers;
            $self->stylize( Cancer::Text::Style::from_meta($meta) );
            $self;
        }

        method remove_suffix($suffix) {
            $self->right_crop( length($suffix) ) if $self->plain =~ /${suffix}$/;
        }

        method get_style_at_offset( $console, $offset ) {
            $offset = length($self) + $offset if $offset < 0;
            my $style = $console->get_style( $self->style )->copy;
            for my $span (@$_spans) {
                if ( $span->[1] > $offset >= $span->[0] ) {
                    $style += $console->get_style( $self->style, '' );
                }
            }
            $style;
        }

        method extend_style($spaces) {
            return if $spaces <= 0;
            my @spans      = $self->spans;
            my $new_spaces = ' ' x $spaces;
            if (@spans) {
                my $end_offset = length $self;
                return $spans = [ map { $_->end >= $end_offset ? $_->extend($spaces) : $_ } @spans ];
            }
            $self->plain( $self->plain . $new_spaces );
        }

        method highlight_regex( $re_highlight, $style //= () ) {
        }
        method highlight_words( $words, $style ) { }

        method rstrip() {
            my $text = $self->plain;
            $text =~ s[\s+$][];
            $self->plain($text);
        }

        method rstrip_end($size) {
            my $text_length = length $self->plain;
            if ( $text_length > $size ) {
                my $excess = $text_length - $size;
                if ( $self->plain =~ /^(.*)\s+$/ ) {
                    my $whitespace_count = length $1;
                    $self->right_crop( $whitespace_count < $excess ? $whitespace_count : $excess )    # min
                }
            }
        }

        method set_length($new_length) {
            my $length = length $self->plain;
            return if $length == $new_length;
            return $self->pad_right( $new_length - $length );
            $self->right_crop( $length - $new_length );
        }

        #~ https://github.com/Textualize/rich/blob/43d3b04725ab9731727fb1126e35980c62f32377/rich/text.py#L720
        method render( $console, $end //= '' ) { }
        method join (@lines)                   { }

        method expand_tabs( $tab_size //= $self->tab_size // 8 ) {
            my $plain = $self->plain;
            warn $plain;
            return if $plain !~ m[\t];
            my $new_text = [];
            for my $line ( $self->split( "\n", 1 ) ) {
                warn $line;
            }
            ...;
        }

        method truncate( $max_width, $overflow //= $self->overflow // $DEFAULT_OVERFLOW, $pad //= 0 ) {
            return if $overflow eq 'ignore';
            my $length = Cancer::Cell::cell_len( $self->plain );
            $self->plain( $overflow eq 'ellipsis' ? Cancer::Cell::set_cell_size( $self->plain, $max_width ) :
                    Cancer::Cell::set_cell_size( $self->plain, $max_width - 1 ) . '…' )
                if ( $length > $max_width );
            if ( $pad and $length < $max_width ) {
                my $spaces = $max_width - $length;
                $_text   = [ $self->plain . ( ' ' x $spaces ) ];
                $_length = length $self->plain;
            }
        }
        method _trim_spans()                { }
        method pad( $count, $char //= ' ' ) { }

        method pad_left( $count, $char //= ' ' ) {
            $count // return;
            $self->plain( ( ' ' x $count ) . $self->plain );
            for my $span ( @{ $self->spans } ) {
                $span->start( $span->start + $count );
                $span->end( $span->end + $count );
            }
        }

        method pad_right( $count, $char //= ' ' ) {
            $count // return;
            $self->plain( $self->plain . ( ' ' x $count ) );
        }
        method align( $align, $width, $char //= ' ' ) { }
        method append( $text, $style //= () )         { }
        method append_text($text)                     { }
        method append_tokens(@tokens)                 { }
        method copy_styles($text)                     { push @$_spans, $text->_spans() }

        method split( $separator //= "\n", $include_separator //= 0, $allow_blank //= 0 ) {
            my $text = $self->plain;
            return [ $self->copy ] unless $text =~ m[$separator];
            if ($include_separator) {
                my $lines = $self->divide();
            }
        }

=cut


    def split(
        self,
        separator: str = "\n",
        *,
        include_separator: bool = False,
        allow_blank: bool = False,
    ) -> Lines:
        """Split rich text in to lines, preserving styles.

        Args:
            separator (str, optional): String to split on. Defaults to "\\\\n".
            include_separator (bool, optional): Include the separator in the lines. Defaults to False.
            allow_blank (bool, optional): Return a blank line if the text ends with a separator. Defaults to False.

        Returns:
            List[RichText]: A list of rich text, one per line of the original.
        """
        assert separator, "separator must not be empty"

        text = self.plain
        if separator not in text:
            return Lines([self.copy()])

        if include_separator:
            lines = self.divide(
                match.end() for match in re.finditer(re.escape(separator), text)
            )
        else:

            def flatten_spans() -> Iterable[int]:
                for match in re.finditer(re.escape(separator), text):
                    start, end = match.span()
                    yield start
                    yield end

            lines = Lines(
                line for line in self.divide(flatten_spans()) if line.plain != separator
            )

        if not allow_blank and text.endswith(separator):
            lines.pop()

        return lines

=cut

        #~ sub max ( $x, $y ) { $x > $y ? $x : $y }
        #~ sub min ( $x, $y ) { $x < $y ? $x : $y }
        method divide (@offsets) {
            return [ $self->copy ] unless @offsets;
            my $text           = $self->plain;
            my $text_length    = length $text;
            my $divide_offsets = [ @offsets, $text_length ];
            my $x              = 0;
            my $line_ranges    = [ map { my $y = [ $x, $_ ]; $x = $_; $y } @$divide_offsets ];
            use Data::Dump;
            ddx $line_ranges;
            #
            my $style     = $self->style;
            my $justify   = $self->justify;
            my $overflow  = $self->overflow;
            my @new_lines = map {
                __CLASS__->new( text => substr( $text, $_->[0], $_->[1] - $_->[0] ), style => $style, justify => $justify, overflow => $overflow )
            } @$line_ranges;
            return \@new_lines unless $_spans;

=cut

        _line_appends = [line._spans.append for line in new_lines._lines]
        line_count = len(line_ranges)
        _Span = Span

        for span_start, span_end, style in self._spans:
            lower_bound = 0
            upper_bound = line_count
            start_line_no = int((lower_bound + upper_bound) / 2)

            while True:
                line_start, line_end = line_ranges[start_line_no]
                if span_start < line_start:
                    upper_bound = start_line_no - 1
                elif span_start > line_end:
                    lower_bound = start_line_no + 1
                else:
                    break
                start_line_no = int((lower_bound + upper_bound) / 2)

            if span_end < line_end:
                end_line_no = start_line_no
            else:
                end_line_no = lower_bound = start_line_no
                upper_bound = line_count

                while True:
                    line_start, line_end = line_ranges[end_line_no]
                    if span_end < line_start:
                        upper_bound = end_line_no - 1
                    elif span_end > line_end:
                        lower_bound = end_line_no + 1
                    else:
                        break
                    end_line_no = int((lower_bound + upper_bound) / 2)

            for line_no in range(start_line_no, end_line_no + 1):
                line_start, line_end = line_ranges[line_no]
                new_start = max(0, span_start - line_start)
                new_end = min(span_end - line_start, line_end - line_start)
                if new_end > new_start:
                    _line_appends[line_no](_Span(new_start, new_end, style))

=cut

            \@new_lines;
        }
        method right_crop( $amount //= 1 )                                                                   { }
        method wrap( $console, $width, $justify //= (), $overflow //= (), $tab_size //= 8, $no_wrap //= () ) { }
        method fit($width)                                                                                   { }
        method detect_indentation()                                                                          { }
        method with_indent_guides( $indent_size //= (), $character //= '|', $style //= 'dim green' )         { }
    }
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
