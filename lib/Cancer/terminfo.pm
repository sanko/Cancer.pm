package Cancer::terminfo {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::for_list';    # Be quiet.
    use feature 'class';
    use experimental 'try';
    class Cancer::terminfo 0.01 {
        field $static : param //= {};
        #
        method tparm ( $format, @args ) {
            my @chrs   = split '', $format;
            my $retval = '';
            my $chr    = '';
            my @params = @args;
            my @tf;                   # True/False
            my $dynamic = {};
            my $percent = 0;
            my $nest    = 0;
            CORE::state $dispatch;    # TODO: Pass args to dispatch so I may make this only define once
            $dispatch = {
                default => sub {
                    die "unknown encoding '%$chr";
                },
                '{' => sub {
                    my $int = '';
                    while (@chrs) {
                        $chr = shift @chrs;
                        if ( $chr !~ /\d/ ) {
                            push @params, $int;
                            return;
                        }
                        $int .= $chr;
                    }
                },
                '\'' => sub {
                    my $char = shift @chrs;
                    die 'Malformed' if shift @chrs ne '\'';
                    push @params, $char;
                    return;
                },
                '%' => sub { $retval .= '%' },
                '+' => sub { push @params, ( pop(@params) + pop(@params) ) },
                '-' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia - $ib;
                },
                '*' => sub { push @params, ( pop(@params) * pop(@params) ) },
                '/' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia / $ib;
                },
                m => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia % $ib;
                },
                '&' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia & $ib;
                },
                '|' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia | $ib;
                },
                '^' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia ^ $ib;
                },
                '=' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia == $ib;
                },
                '<' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia < $ib;
                },
                '>' => sub {
                    my $ib = pop @params;
                    my $ia = pop @params;
                    push @params, $ia > $ib;
                },
                c => sub { $retval .= sprintf '%c', shift @params },
                d => sub { $retval .= sprintf '%d', shift @params },
                s => sub { $retval .= sprintf '%s', shift @params },
                p => sub {
                    my $ith = shift @chrs;
                    push @params, ( $params[ $ith - 1 ] // 0 );    #(scalar @params >= $ith - 1) ? $params[$ith-1] : 0;
                },
                P => sub {
                    my $name = shift @chrs;
                    ( $name eq lc $name ? $dynamic->{$name} : $static->{$name} ) = shift @params;
                },
                g => sub {
                    my $name = shift @chrs;
                    push @params, sprintf '%s', ( $name eq lc $name ? $dynamic->{$name} // '' : $static->{$name} // '' );
                },
                l => sub { push @params, length pop @params },
                i => sub {

                    # TODO: Only do this for ANSI terminals
                    $params[0]++ if $params[0] =~ m[^\d$];
                    $params[1]++ if $params[1] =~ m[^\d$];
                },
                #
                '!' => sub { push @params, !pop(@params) },
                '~' => sub { push @params, pop(@params) ^ -1 },
                A   => sub { my $y = pop @params; my $x = pop @params; push @params, $y && $x },
                O   => sub { my $y = pop @params; my $x = pop @params; push @params, $y || $x },

                # conditionals
                '?' => sub { },    # nothing to do here
                t   => sub {
                    push @tf, pop @params;
                    if ( $tf[-1] ) {
                        return;    # just keep going
                    }
                    $nest = 0;
                IFLOOP:
                    while (@chrs) {    # This loop consumes everything until we hit out else or the end of the conditional
                        $chr = shift @chrs;
                        $chr // die 'Malformed';
                        next if $chr ne '%';
                        $chr = shift @chrs;
                        if ( $chr eq ';' ) {
                            if ( $nest == 0 ) {
                                last IFLOOP;
                            }
                            $nest--;
                        }
                        elsif ( $chr eq '?' ) {
                            $nest++;
                        }
                        elsif ( $chr eq 'e' ) {
                            if ( $nest == 0 ) {
                                last IFLOOP;
                            }
                        }
                    }
                },
                e => sub {

                    # If we got here, we didn't use the else in the 't' case above and should skip until the end of the  conditional
                    $nest = 0;
                ELLOOP: while (@chrs) {
                        $chr = shift @chrs;
                        $chr // die 'Malformed';
                        if ( $chr ne '%' ) {
                            next;
                        }
                        $chr = shift @chrs;
                        if ( $chr eq ';' ) {
                            if ( $nest == 0 ) {
                                last ELLOOP;
                            }
                            $nest--;
                        }
                        elsif ( $chr eq '?' ) {
                            $nest++;
                        }
                    }
                },
                ';' => sub {
                    pop @tf;
                }
            };
            while (@chrs) {
                $chr = shift @chrs;
                if ( ( !$percent ) && $chr eq '%' ) {
                    $percent++;
                }
                elsif ($percent) {
                    ( $dispatch->{$chr} // $dispatch->{default} )->();
                    $percent--;
                }
                else {
                    $retval .= $chr if defined $chr;
                }
            }
            return $retval;
        }
    };
}
1;
__END__

  #       The % encodings have the following meanings:
  #
  #       %%        outputs `%'
  #       %c        print pop() like %c in printf()
  #       %s        print pop() like %s in printf()
  *       %[[:]flags][width[.precision]][doxXs]
  *                 as in printf, flags are [-+#] and space
  *                 The ':' is used to avoid making %+ or %-
  *                 patterns (see below).
  #
  *       %p[1-9]   push ith parm
  #       %P[a-z]   set dynamic variable [a-z] to pop()
  #       %g[a-z]   get dynamic variable [a-z] and push it
  #       %P[A-Z]   set static variable [A-Z] to pop()
  #       %g[A-Z]   get static variable [A-Z] and push it
  #       %l        push strlen(pop)
  #       %'c'      push char constant c
  #       %{nn}     push integer constant nn
  #
  #       %+ %- %* %/ %m
  #                 arithmetic (%m is mod): push(pop() op pop())
  #       %& %| %^  bit operations: push(pop() op pop())
  #       %= %> %<  logical operations: push(pop() op pop())
  #       %A %O     logical and & or operations for conditionals
  #       %! %~     unary operations push(op pop())
  #       %i        add 1 to first two parms (for ANSI terminals)
  #
  #       %? expr %t thenpart %e elsepart %;
  #                 if-then-else, %e elsepart is optional.
  #                 else-if's are possible ala Algol 68:
  #                 %? c1 %t b1 %e c2 %t b2 %e c3 %t b3 %e c4 %t b4 %e b5 %;
  #
  #  For those of the above operators which are binary and not commutative,
  #  the stack works in the usual way, with
  #          %gx %gy %m
  #  resulting in x mod y, not the reverse.
