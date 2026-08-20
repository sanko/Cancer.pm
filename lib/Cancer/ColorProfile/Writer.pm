use v5.42;
use experimental 'class';
class Cancer::ColorProfile::Writer v0.0.1 {
    use Cancer::Ansi::Parser qw[
        new_parser parser_reset DecodeSequence HasCsiPrefix HasOscPrefix
        param command params MissingParam ParamVal HasMore
        _read_style_color
    ];
    use Cancer::Ansi         qw[ResetStyle Strip];
    use Cancer::ColorProfile qw[TrueColor NoTTY ASCII ANSI ANSI256 Unknown Detect];
    field $forward : param //= \*STDOUT;
    field $environ : param //= \%ENV;
    field $profile : param //= Detect( $forward, $environ );
    method profile () {$profile}
    method forward () {$forward}

    method write ($data) {
        if ( $profile == TrueColor ) {
            return $self->_write_raw($data);
        }
        if ( $profile <= NoTTY ) {
            my $stripped = Strip($data);
            return $self->_write_raw($stripped);
        }
        return $self->_downsample($data);
    }

    method _write_raw ($data) {
        if ( ref $forward && $forward->can('print') ) {
            $forward->print($data);
        }
        else {
            print {$forward} $data;
        }
        return length($data);
    }

    method _downsample ($data) {
        my $parser = new_parser();
        my $state  = 0;
        my $out    = '';
        while ( length $data ) {
            parser_reset($parser);
            my ( $seq, $width, $n, $new_state ) = DecodeSequence( $data, $state, $parser );
            $state = $new_state;
            if ( HasCsiPrefix($seq) && command($parser) == ord('m') ) {
                $out .= _handle_sgr( $profile, $parser );
            }
            else {
                $out .= $seq;
            }
            $data = substr( $data, $n );
        }
        return $self->_write_raw($out);
    }

    sub _handle_sgr ( $p, $parser ) {
        my @params   = params($parser);
        my $n_params = scalar @params;
        my @parts;
        my $i = 0;
        while ( $i < $n_params ) {
            my ( $val, $has_more ) = param( { params => \@params, paramsLen => $n_params }, $i, 0 );
            if ( $val == 0 ) {
                push @parts, '';
            }
            elsif ( $val == 38 || $val == 48 || $val == 58 ) {
                my ( $c, $consumed ) = _read_style_color( \@params, $i );
                $i += $consumed - 1 if $consumed > 0;
                if ( $p >= ANSI && defined $c ) {
                    my $converted = Cancer::ColorProfile::Convert( $p, $c );
                    push @parts, _color_str( $val, $converted );
                }
            }
            elsif ( $val == 39 || $val == 49 || $val == 59 ) {
                push @parts, "$val" if $p >= ANSI;
            }
            elsif ( ( $val >= 30 && $val <= 37 ) || ( $val >= 40 && $val <= 47 ) ) {
                if ( $p >= ANSI ) {
                    my $offset    = ( $val < 40 ) ? 30 : 40;
                    my $code      = $val - $offset;
                    my $c         = { type => 'basic', code => $code };
                    my $converted = Cancer::ColorProfile::Convert( $p, $c );
                    push @parts, _color_str( $val < 40 ? 38 : 48, $converted );
                }
            }
            elsif ( ( $val >= 90 && $val <= 97 ) || ( $val >= 100 && $val <= 107 ) ) {
                if ( $p >= ANSI ) {
                    my $offset    = ( $val < 100 ) ? 90 : 100;
                    my $code      = $val - $offset + 8;
                    my $c         = { type => 'basic', code => $code };
                    my $converted = Cancer::ColorProfile::Convert( $p, $c );
                    push @parts, _color_str( $val < 100 ? 38 : 48, $converted );
                }
            }
            else {
                push @parts, "$val";
            }
            $i++;
        }
        my @filtered = grep { $_ ne '' } @parts;
        return ResetStyle() unless @filtered;
        return "\e[" . join( ';', @filtered ) . "m";
    }

    sub _color_str ( $prefix, $c ) {
        return "${prefix};39" if $prefix == 39;
        return "${prefix};49" if $prefix == 49;
        return "${prefix};59" if $prefix == 59;
        return '' unless defined $c;
        my $type = $c->{type};
        if ( $type eq 'basic' ) {
            my $code = $c->{code};
            if   ( $code < 8 ) { return ( $prefix == 38 ? 30 : 40 ) + $code }
            else               { return ( $prefix == 38 ? 90 : 100 ) + $code - 8 }
        }
        elsif ( $type eq '256' ) { return "${prefix};5;$c->{index}" }
        elsif ( $type eq 'rgb' ) { return "${prefix};2;$c->{r};$c->{g};$c->{b}" }
        return '';
    }
} 1;
