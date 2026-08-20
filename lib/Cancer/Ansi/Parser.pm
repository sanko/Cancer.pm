use v5.42;

package Cancer::Ansi::Parser v0.0.1 {
    use Exporter 'import';
    use utf8;
    use constant {

        # Action constants (must match transition table encoding)
        NoneAction     => 0,
        IgnoreAction   => 0,
        ClearAction    => 1,
        CollectAction  => 2,
        PrefixAction   => 3,
        DispatchAction => 4,
        ExecuteAction  => 5,
        StartAction    => 6,
        PutAction      => 7,
        ParamAction    => 8,
        PrintAction    => 9,

        # State constants
        GroundState             => 0,
        CsiEntryState           => 1,
        CsiIntermediateState    => 2,
        CsiParamState           => 3,
        DcsEntryState           => 4,
        DcsIntermediateState    => 5,
        DcsParamState           => 6,
        DcsStringState          => 7,
        EscapeState             => 8,
        EscapeIntermediateState => 9,
        OscStringState          => 10,
        SosStringState          => 11,
        PmStringState           => 12,
        ApcStringState          => 13,
        Utf8State               => 14,

        # Cmd/Param masks and shifts
        PrefixShift    => 8,
        IntermedShift  => 16,
        FinalMask      => 0xff,
        HasMoreFlag    => 0x80000000,
        ParamMask      => 0x7FFFFFFF,
        MissingParam   => 0x7FFFFFFF,
        MissingCommand => 0x7FFFFFFF,
        MaxParam       => 0xFFFF,

        # MaxParamsSize is the maximum number of params slots
        MaxParamsSize => 32,

        # Default param value for missing params
        DefaultParamValue => 0,

        # DecodeSequence states
        NormalState         => 0,
        DecodePrefixState   => 1,
        DecodeParamsState   => 2,
        DecodeIntermedState => 3,
        DecodeEscapeState   => 4,
        DecodeStringState   => 5
    };
    use constant { TransitionActionShift => 4, TransitionStateMask => 15, IndexStateShift => 8, DefaultTableSize => 4096 };
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                GroundState CsiEntryState CsiIntermediateState CsiParamState
                DcsEntryState DcsIntermediateState DcsParamState DcsStringState
                EscapeState EscapeIntermediateState OscStringState
                SosStringState PmStringState ApcStringState Utf8State
                NoneAction IgnoreAction ClearAction CollectAction PrefixAction
                DispatchAction ExecuteAction StartAction PutAction ParamAction PrintAction
                NormalState DecodePrefixState DecodeParamsState DecodeIntermedState
                DecodeEscapeState DecodeStringState
                PrefixShift IntermedShift FinalMask HasMoreFlag ParamMask
                MissingParam MissingCommand MaxParam MaxParamsSize DefaultParamValue
                new_parser set_handler set_params_size set_data_size
                parser_advance parser_parse parser_reset
                params param command rune control data state state_name
                Cmd Prefix Intermediate Final
                Command
                Param ParamVal HasMore
                Parameter
                HasCsiPrefix HasOscPrefix HasApcPrefix HasDcsPrefix
                HasSosPrefix HasPmPrefix HasStPrefix HasEscPrefix
                DecodeSequence
                _read_style_color
                ]
        ]
    );
    use constant {
        ESC => 0x1B,
        CSI => 0x9B,
        DCS => 0x90,
        OSC => 0x9D,
        APC => 0x9F,
        SOS => 0x98,
        PM  => 0x9E,
        ST  => 0x9C,
        BEL => 0x07,
        CAN => 0x18,
        SUB => 0x1A,
        DEL => 0x7F,
        US  => 0x1F
    };

    # Transition table
    our $TABLE;

    BEGIN {
        my $size = DefaultTableSize;
        $TABLE = "\x00" x $size;
        my sub r ( $start, $end ) {
            my @a;
            for my $i ( $start .. $end ) {
                push @a, chr($i);
            }
            return @a;
        }

        sub set_default ( $action, $state ) {
            my $v = chr( ( $action << TransitionActionShift ) | $state );
            for my $i ( 0 .. length($TABLE) - 1 ) {
                substr( $TABLE, $i, 1 ) = $v;
            }
        }

        sub add_one( $code, $state, $action, $next ) {
            my $idx = ( $state << IndexStateShift ) | $code;
            my $v   = chr( ( $action << TransitionActionShift ) | $next );
            substr( $TABLE, $idx, 1 ) = $v;
        }

        sub add_many( $codes, $state, $action, $next ) {
            for my $c (@$codes) {
                add_one( ord($c), $state, $action, $next );
            }
        }

        sub add_range ( $start, $end, $state, $action, $next ) {
            for my $c ( $start .. $end ) {
                add_one( $c, $state, $action, $next );
            }
        }
        set_default( NoneAction, GroundState );

        # Anywhere
        for my $s ( GroundState .. Utf8State ) {
            add_many( [ chr(0x18), chr(0x1A), chr(0x99), chr(0x9A) ], $s, ExecuteAction, GroundState );
            add_range( 0x80, 0x8F, $s, ExecuteAction, GroundState );
            add_range( 0x90, 0x97, $s, ExecuteAction, GroundState );
            add_one( 0x9C, $s, ExecuteAction, GroundState );
            add_one( 0x1B, $s, ClearAction,   EscapeState );
            add_one( 0x98, $s, StartAction,   SosStringState );
            add_one( 0x9E, $s, StartAction,   PmStringState );
            add_one( 0x9F, $s, StartAction,   ApcStringState );
            add_one( 0x9B, $s, ClearAction,   CsiEntryState );
            add_one( 0x90, $s, ClearAction,   DcsEntryState );
            add_one( 0x9D, $s, StartAction,   OscStringState );
            add_range( 0xC2, 0xDF, $s, CollectAction, Utf8State );
            add_range( 0xE0, 0xEF, $s, CollectAction, Utf8State );
            add_range( 0xF0, 0xF4, $s, CollectAction, Utf8State );
        }

        # Ground
        add_range( 0x00, 0x17, GroundState, ExecuteAction, GroundState );
        add_one( 0x19, GroundState, ExecuteAction, GroundState );
        add_range( 0x1C, 0x1F, GroundState, ExecuteAction, GroundState );
        add_range( 0x20, 0x7E, GroundState, PrintAction,   GroundState );
        add_one( 0x7F, GroundState, ExecuteAction, GroundState );

        # EscapeIntermediate
        add_range( 0x00, 0x17, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState );
        add_one( 0x19, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState );
        add_range( 0x1C, 0x1F, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState );
        add_range( 0x20, 0x2F, EscapeIntermediateState, CollectAction, EscapeIntermediateState );
        add_one( 0x7F, EscapeIntermediateState, IgnoreAction, EscapeIntermediateState );
        add_range( 0x30, 0x7E, EscapeIntermediateState, DispatchAction, GroundState );

        # Escape
        add_range( 0x00, 0x17, EscapeState, ExecuteAction, EscapeState );
        add_one( 0x19, EscapeState, ExecuteAction, EscapeState );
        add_range( 0x1C, 0x1F, EscapeState, ExecuteAction, EscapeState );
        add_one( 0x7F, EscapeState, IgnoreAction, EscapeState );
        add_range( 0x30, 0x4F, EscapeState, DispatchAction, GroundState );
        add_range( 0x51, 0x57, EscapeState, DispatchAction, GroundState );
        add_one( 0x59, EscapeState, DispatchAction, GroundState );
        add_one( 0x5A, EscapeState, DispatchAction, GroundState );
        add_one( 0x5C, EscapeState, DispatchAction, GroundState );
        add_range( 0x60, 0x7E, EscapeState, DispatchAction, GroundState );
        add_range( 0x20, 0x2F, EscapeState, CollectAction,  EscapeIntermediateState );
        add_one( ord('X'), EscapeState, StartAction, SosStringState );
        add_one( ord('^'), EscapeState, StartAction, PmStringState );
        add_one( ord('_'), EscapeState, StartAction, ApcStringState );
        add_one( ord('P'), EscapeState, ClearAction, DcsEntryState );
        add_one( ord('['), EscapeState, ClearAction, CsiEntryState );
        add_one( ord(']'), EscapeState, StartAction, OscStringState );

        # SosPmApcString (SosStringState..ApcStringState)
        for my $s ( SosStringState .. ApcStringState ) {
            add_range( 0x00, 0x17, $s, PutAction, $s );
            add_one( 0x19, $s, PutAction, $s );
            add_range( 0x1C, 0x1F, $s, PutAction, $s );
            add_range( 0x20, 0x7F, $s, PutAction, $s );
            add_one( 0x1B, $s, DispatchAction, EscapeState );
            add_one( 0x9C, $s, DispatchAction, GroundState );
            add_many( [ chr(0x18), chr(0x1A) ], $s, IgnoreAction, GroundState );
        }

        # DcsEntry
        add_range( 0x00, 0x07, DcsEntryState, IgnoreAction, DcsEntryState );
        add_range( 0x0E, 0x17, DcsEntryState, IgnoreAction, DcsEntryState );
        add_one( 0x19, DcsEntryState, IgnoreAction, DcsEntryState );
        add_range( 0x1C, 0x1F, DcsEntryState, IgnoreAction, DcsEntryState );
        add_one( 0x7F, DcsEntryState, IgnoreAction, DcsEntryState );
        add_range( 0x20, 0x2F, DcsEntryState, CollectAction, DcsIntermediateState );
        add_range( 0x30, 0x3B, DcsEntryState, ParamAction,   DcsParamState );
        add_range( 0x3C, 0x3F, DcsEntryState, PrefixAction,  DcsParamState );
        add_range( 0x08, 0x0D, DcsEntryState, PutAction,     DcsStringState );
        add_one( 0x1B, DcsEntryState, PutAction, DcsStringState );
        add_range( 0x40, 0x7E, DcsEntryState, StartAction, DcsStringState );

        # DcsIntermediate
        add_range( 0x00, 0x17, DcsIntermediateState, IgnoreAction, DcsIntermediateState );
        add_one( 0x19, DcsIntermediateState, IgnoreAction, DcsIntermediateState );
        add_range( 0x1C, 0x1F, DcsIntermediateState, IgnoreAction,  DcsIntermediateState );
        add_range( 0x20, 0x2F, DcsIntermediateState, CollectAction, DcsIntermediateState );
        add_one( 0x7F, DcsIntermediateState, IgnoreAction, DcsIntermediateState );
        add_range( 0x30, 0x3F, DcsIntermediateState, StartAction, DcsStringState );
        add_range( 0x40, 0x7E, DcsIntermediateState, StartAction, DcsStringState );

        # DcsParam
        add_range( 0x00, 0x17, DcsParamState, IgnoreAction, DcsParamState );
        add_one( 0x19, DcsParamState, IgnoreAction, DcsParamState );
        add_range( 0x1C, 0x1F, DcsParamState, IgnoreAction, DcsParamState );
        add_range( 0x30, 0x3B, DcsParamState, ParamAction,  DcsParamState );
        add_one( 0x7F, DcsParamState, IgnoreAction, DcsParamState );
        add_range( 0x3C, 0x3F, DcsParamState, IgnoreAction,  DcsParamState );
        add_range( 0x20, 0x2F, DcsParamState, CollectAction, DcsIntermediateState );
        add_range( 0x40, 0x7E, DcsParamState, StartAction,   DcsStringState );

        # DcsString (passthrough)
        add_range( 0x00, 0x17, DcsStringState, PutAction, DcsStringState );
        add_one( 0x19, DcsStringState, PutAction, DcsStringState );
        add_range( 0x1C, 0x1F, DcsStringState, PutAction, DcsStringState );
        add_range( 0x20, 0x7E, DcsStringState, PutAction, DcsStringState );
        add_one( 0x7F, DcsStringState, PutAction, DcsStringState );
        add_range( 0x80, 0xFF, DcsStringState, PutAction, DcsStringState );
        add_one( 0x1B, DcsStringState, DispatchAction, EscapeState );
        add_one( 0x9C, DcsStringState, DispatchAction, GroundState );
        add_many( [ chr(0x18), chr(0x1A) ], DcsStringState, IgnoreAction, GroundState );

        # CsiParam
        add_range( 0x00, 0x17, CsiParamState, ExecuteAction, CsiParamState );
        add_one( 0x19, CsiParamState, ExecuteAction, CsiParamState );
        add_range( 0x1C, 0x1F, CsiParamState, ExecuteAction, CsiParamState );
        add_range( 0x30, 0x3B, CsiParamState, ParamAction,   CsiParamState );
        add_one( 0x7F, CsiParamState, IgnoreAction, CsiParamState );
        add_range( 0x3C, 0x3F, CsiParamState, IgnoreAction,   CsiParamState );
        add_range( 0x40, 0x7E, CsiParamState, DispatchAction, GroundState );
        add_range( 0x20, 0x2F, CsiParamState, CollectAction,  CsiIntermediateState );

        # CsiIntermediate
        add_range( 0x00, 0x17, CsiIntermediateState, ExecuteAction, CsiIntermediateState );
        add_one( 0x19, CsiIntermediateState, ExecuteAction, CsiIntermediateState );
        add_range( 0x1C, 0x1F, CsiIntermediateState, ExecuteAction, CsiIntermediateState );
        add_range( 0x20, 0x2F, CsiIntermediateState, CollectAction, CsiIntermediateState );
        add_one( 0x7F, CsiIntermediateState, IgnoreAction, CsiIntermediateState );
        add_range( 0x40, 0x7E, CsiIntermediateState, DispatchAction, GroundState );
        add_range( 0x30, 0x3F, CsiIntermediateState, IgnoreAction,   GroundState );

        # CsiEntry
        add_range( 0x00, 0x17, CsiEntryState, ExecuteAction, CsiEntryState );
        add_one( 0x19, CsiEntryState, ExecuteAction, CsiEntryState );
        add_range( 0x1C, 0x1F, CsiEntryState, ExecuteAction, CsiEntryState );
        add_one( 0x7F, CsiEntryState, IgnoreAction, CsiEntryState );
        add_range( 0x40, 0x7E, CsiEntryState, DispatchAction, GroundState );
        add_range( 0x20, 0x2F, CsiEntryState, CollectAction,  CsiIntermediateState );
        add_range( 0x30, 0x3B, CsiEntryState, ParamAction,    CsiParamState );
        add_range( 0x3C, 0x3F, CsiEntryState, PrefixAction,   CsiParamState );

        # OscString
        add_range( 0x00, 0x06, OscStringState, IgnoreAction, OscStringState );
        add_range( 0x08, 0x17, OscStringState, IgnoreAction, OscStringState );
        add_one( 0x19, OscStringState, IgnoreAction, OscStringState );
        add_range( 0x1C, 0x1F, OscStringState, IgnoreAction, OscStringState );
        add_range( 0x20, 0xFF, OscStringState, PutAction,    OscStringState );
        add_one( 0x1B, OscStringState, DispatchAction, EscapeState );
        add_one( 0x07, OscStringState, DispatchAction, GroundState );
        add_one( 0x9C, OscStringState, DispatchAction, GroundState );
        add_many( [ chr(0x18), chr(0x1A) ], OscStringState, IgnoreAction, GroundState );
    }
    #
    sub table_transition ( $state, $code ) {
        my $idx = ( $state << IndexStateShift ) | $code;
        my $v   = ord( substr( $TABLE, $idx, 1 ) );
        ( $v & TransitionStateMask, $v >> TransitionActionShift );
    }
    #
    sub new_parser () {
        bless {
            handler   => undef,
            params    => [ (MissingParam) x MaxParamsSize ],
            data      => "\x00" x ( 1024 * 64 ),
            dataLen   => 0,
            paramsLen => 0,
            cmd       => 0,
            state     => GroundState
        };
    }
    sub set_handler     ( $p, $h )    { $p->{handler} = $h; }
    sub set_params_size ( $p, $size ) { $p->{params}  = [ (MissingParam) x $size ]; }

    sub set_data_size ( $p, $size ) {
        if ( $size <= 0 ) {
            $p->{dataLen} = -1;
            $p->{data}    = '';
        }
        else {
            $p->{data}    = "\x00" x $size;
            $p->{dataLen} = 0;
        }
    }

    sub params ($p) {
        return () if !$p->{paramsLen};
        @{ $p->{params} }[ 0 .. $p->{paramsLen} - 1 ];
    }

    sub param ( $p, $i, $def ) {
        return ( $def, 0 ) if $i < 0 || $i >= $p->{paramsLen};
        my $v = $p->{params}[$i];
        ( ParamVal( $v, $def ), HasMore($v) );
    }
    sub command ($p) { $p->{cmd} }

    sub rune ($p) {
        my $b  = $p->{cmd} & 0xff;
        my $rw = utf8_byte_len($b);
        return chr(0xFFFD) if $rw == -1;
        my $bytes = '';
        for my $i ( 0 .. $rw - 1 ) {
            my $shift = $i * 8;
            $bytes .= chr( ( $p->{cmd} >> $shift ) & 0xff );
        }
        my $r = eval { decode_utf8_bytes($bytes) };
        $r // chr(0xFFFD);
    }
    sub control ($p) { $p->{cmd} & 0xff }

    sub data ($p) {
        my $dl = $p->{dataLen};
        return substr( $p->{data}, 0, $dl ) if $dl >= 0;
        $p->{data};
    }
    sub state ($p) { $p->{state} }

    sub state_name ($p) {
        my @names = qw[
            GroundState CsiEntryState CsiIntermediateState CsiParamState
            DcsEntryState DcsIntermediateState DcsParamState DcsStringState
            EscapeState EscapeIntermediateState OscStringState
            SosStringState PmStringState ApcStringState Utf8State
        ];
        $names[ $p->{state} ] // 'Unknown';
    }

    sub parser_reset ($p) {
        $p->{cmd}       = 0;
        $p->{params}[0] = MissingParam if @{ $p->{params} };
        $p->{paramsLen} = 0;
        $p->{state}     = GroundState;
    }

    sub parser_advance ( $p, $b ) {
        my $state = $p->{state};
        return _advance_utf8( $p, $b ) if $state == Utf8State;
        return _advance_sm( $p, $b );
    }

    sub parser_parse ( $p, $bytes ) {
        utf8::encode($bytes) if utf8::is_utf8($bytes);
        for my $i ( 0 .. length($bytes) - 1 ) {
            parser_advance( $p, ord( substr( $bytes, $i, 1 ) ) );
        }
    }

    sub _clear ($p) {
        $p->{params}[0] = MissingParam if @{ $p->{params} };
        $p->{paramsLen} = 0;
        $p->{cmd}       = 0;
    }

    sub _collect_rune ( $p, $b ) {
        return if $p->{paramsLen} >= 4;
        my $shift = $p->{paramsLen} * 8;
        $p->{cmd} &= ~( 0xff << $shift );
        $p->{cmd} |= $b << $shift;
        $p->{paramsLen}++;
    }

    sub _advance_utf8 ( $p, $b ) {
        _collect_rune( $p, $b );
        my $rw = utf8_byte_len( $p->{cmd} & 0xff );
        return CollectAction if $p->{paramsLen} < $rw;
        my $h = $p->{handler};
        if ( $h && $h->{Print} ) {
            $h->{Print}->( rune($p) );
        }
        $p->{state}     = GroundState;
        $p->{paramsLen} = 0;
        return PrintAction;
    }

    sub _parse_string_cmd ($p) {
        my $data    = $p->{data};
        my $datalen = length($data);
        $datalen = $p->{dataLen} if $p->{dataLen} >= 0;
        for my $i ( 0 .. $datalen - 1 ) {
            my $d = ord( substr( $data, $i, 1 ) );
            last          if $d < ord('0') || $d > ord('9');
            $p->{cmd} = 0 if $p->{cmd} == MissingCommand;
            $p->{cmd} *= 10;
            $p->{cmd} += $d - ord('0');
        }
    }

    sub _perform_action ( $p, $action, $new_state, $b ) {
        return if $action == IgnoreAction;
        if ( $action == ClearAction ) {
            _clear($p);
            return;
        }
        if ( $action == PrintAction ) {
            $p->{cmd} = $b;
            my $h = $p->{handler};
            if ( $h && $h->{Print} ) {
                $h->{Print}->($b);
            }
            return;
        }
        if ( $action == ExecuteAction ) {
            $p->{cmd} = $b;
            my $h = $p->{handler};
            if ( $h && $h->{Execute} ) {
                $h->{Execute}->($b);
            }
            return;
        }
        if ( $action == PrefixAction ) {
            $p->{cmd} &= ~( 0xff << PrefixShift );
            $p->{cmd} |= $b << PrefixShift;
            return;
        }
        if ( $action == CollectAction ) {
            if ( $new_state == Utf8State ) {
                $p->{paramsLen} = 0;
                _collect_rune( $p, $b );
            }
            else {
                $p->{cmd} &= ~( 0xff << IntermedShift );
                $p->{cmd} |= $b << IntermedShift;
            }
            return;
        }
        if ( $action == ParamAction ) {
            if ( $p->{paramsLen} < @{ $p->{params} } ) {
                if ( $b >= ord('0') && $b <= ord('9') ) {
                    if ( $p->{params}[ $p->{paramsLen} ] == MissingParam ) {
                        $p->{params}[ $p->{paramsLen} ] = 0;
                    }
                    $p->{params}[ $p->{paramsLen} ] *= 10;
                    $p->{params}[ $p->{paramsLen} ] += $b - ord('0');
                }
                if ( $b == ord(':') ) {
                    $p->{params}[ $p->{paramsLen} ] |= HasMoreFlag;
                }
                if ( $b == ord(';') || $b == ord(':') ) {
                    $p->{paramsLen}++;
                    if ( $p->{paramsLen} < @{ $p->{params} } ) {
                        $p->{params}[ $p->{paramsLen} ] = MissingParam;
                    }
                }
            }
            return;
        }
        if ( $action == StartAction ) {
            if ( $p->{dataLen} < 0 && length( $p->{data} ) >= 0 ) {
                $p->{data} = '';
            }
            else {
                $p->{dataLen} = 0;
            }
            my $s = $p->{state};
            if ( $s >= DcsEntryState && $s <= DcsStringState ) {
                $p->{cmd} |= $b;
            }
            else {
                $p->{cmd} = MissingCommand;
            }
            return;
        }
        if ( $action == PutAction ) {
            my $s = $p->{state};
            if ( $s == OscStringState && $b == ord(';') && $p->{cmd} == MissingCommand ) {
                _parse_string_cmd($p);
            }
            if ( $p->{dataLen} < 0 ) {
                $p->{data} .= chr($b);
            }
            else {
                if ( $p->{dataLen} < length( $p->{data} ) ) {
                    substr( $p->{data}, $p->{dataLen}, 1 ) = chr($b);
                    $p->{dataLen}++;
                }
            }
            return;
        }
        if ( $action == DispatchAction ) {
            if ( ( $p->{paramsLen} > 0 && $p->{paramsLen} < @{ $p->{params} } - 1 ) ||
                ( $p->{paramsLen} == 0 && @{ $p->{params} } > 0 && $p->{params}[0] != MissingParam ) ) {
                $p->{paramsLen}++;
            }
            my $s = $p->{state};
            if ( $s == OscStringState && $p->{cmd} == MissingCommand ) {
                _parse_string_cmd($p);
            }
            my $data_out;
            if ( $p->{dataLen} >= 0 ) {
                $data_out = substr( $p->{data}, 0, $p->{dataLen} );
            }
            else {
                $data_out = $p->{data};
            }
            my @p_out = params($p);
            my $h     = $p->{handler};
            if ( $s == CsiEntryState || $s == CsiParamState || $s == CsiIntermediateState ) {
                $p->{cmd} |= $b;
                if ( $h && $h->{HandleCsi} ) {
                    $h->{HandleCsi}->( $p->{cmd}, \@p_out );
                }
            }
            elsif ( $s == EscapeState || $s == EscapeIntermediateState ) {
                $p->{cmd} |= $b;
                if ( $h && $h->{HandleEsc} ) {
                    $h->{HandleEsc}->( $p->{cmd} );
                }
            }
            elsif ( $s >= DcsEntryState && $s <= DcsStringState ) {
                if ( $h && $h->{HandleDcs} ) {
                    $h->{HandleDcs}->( $p->{cmd}, \@p_out, $data_out );
                }
            }
            elsif ( $s == OscStringState ) {
                if ( $h && $h->{HandleOsc} ) {
                    $h->{HandleOsc}->( $p->{cmd}, $data_out );
                }
            }
            elsif ( $s == SosStringState ) {
                if ( $h && $h->{HandleSos} ) {
                    $h->{HandleSos}->($data_out);
                }
            }
            elsif ( $s == PmStringState ) {
                if ( $h && $h->{HandlePm} ) {
                    $h->{HandlePm}->($data_out);
                }
            }
            elsif ( $s == ApcStringState ) {
                if ( $h && $h->{HandleApc} ) {
                    $h->{HandleApc}->($data_out);
                }
            }
            return;
        }
    }

    sub _advance_sm ( $p, $b ) {
        my ( $new_state, $action ) = table_transition( $p->{state}, $b );
        if ( $p->{state} != $new_state ) {
            if ( $p->{state} == EscapeState ) {
                _perform_action( $p, ClearAction, $new_state, $b );
            }
            if ( $action == PutAction && $p->{state} == DcsEntryState && $new_state == DcsStringState ) {
                _perform_action( $p, StartAction, $new_state, 0 );
            }
        }
        if ( $b == ESC && $p->{state} == EscapeState ) {
            _perform_action( $p, ExecuteAction, $new_state, $b );
        }
        else {
            _perform_action( $p, $action, $new_state, $b );
        }
        $p->{state} = $new_state;
        return $action;
    }
    #
    sub utf8_byte_len ($b) {
        return 1 if $b <= 0b0111_1111;
        return 2 if $b >= 0b1100_0000 && $b <= 0b1101_1111;
        return 3 if $b >= 0b1110_0000 && $b <= 0b1110_1111;
        return 4 if $b >= 0b1111_0000 && $b <= 0b1111_0111;
        return -1;
    }

    sub decode_utf8_bytes ($bytes) {
        return unless length($bytes) >= 1;
        my $b0 = ord( substr( $bytes, 0, 1 ) );
        return chr($b0) if $b0 <= 0x7F;
        my $len = utf8_byte_len($b0);
        return unless length($bytes) >= $len;
        my $cp;
        if ( $len == 2 ) {
            $cp = ( $b0 & 0x1F ) << 6 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F );
        }
        elsif ( $len == 3 ) {
            $cp = ( $b0 & 0x0F ) << 12 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F ) << 6 | ( ord( substr( $bytes, 2, 1 ) ) & 0x3F );
        }
        elsif ( $len == 4 ) {
            $cp = ( $b0 & 0x07 ) << 18 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F ) << 12 | ( ord( substr( $bytes, 2, 1 ) ) & 0x3F ) << 6
                | ( ord( substr( $bytes, 3, 1 ) ) & 0x3F );
        }
        return chr($cp);
    }

    sub _decode_cp ($bytes) {
        my $b0  = ord( substr( $bytes, 0, 1 ) );
        my $len = utf8_byte_len($b0);
        return -1 if $len <= 0 || length($bytes) < $len;
        my $cp;
        if ( $len == 1 ) {
            $cp = $b0;
        }
        elsif ( $len == 2 ) {
            $cp = ( $b0 & 0x1F ) << 6 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F );
        }
        elsif ( $len == 3 ) {
            $cp = ( $b0 & 0x0F ) << 12 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F ) << 6 | ( ord( substr( $bytes, 2, 1 ) ) & 0x3F );
        }
        elsif ( $len == 4 ) {
            $cp = ( $b0 & 0x07 ) << 18 | ( ord( substr( $bytes, 1, 1 ) ) & 0x3F ) << 12 | ( ord( substr( $bytes, 2, 1 ) ) & 0x3F ) << 6
                | ( ord( substr( $bytes, 3, 1 ) ) & 0x3F );
        }
        return $cp;
    }

    sub _is_grapheme_extender ($cp) {
        return 1 if $cp == 0x200D;                       # ZWJ
        return 1 if $cp >= 0xFE00  && $cp <= 0xFE0F;     # Variation selectors
        return 1 if $cp >= 0x1F3FB && $cp <= 0x1F3FF;    # Skin tone modifiers
        return 1 if $cp >= 0x0300  && $cp <= 0x036F;     # Combining diacritical marks
        return 1 if $cp >= 0x1AB0  && $cp <= 0x1AFF;     # Combining diacritical marks extended
        return 1 if $cp >= 0x1DC0  && $cp <= 0x1DFF;     # Combining diacritical marks supplement
        return 1 if $cp >= 0x20D0  && $cp <= 0x20FF;     # Combining marks for symbols
        return 1 if $cp >= 0xFE20  && $cp <= 0xFE2F;     # Combining half marks
        return 1 if $cp == 0xFE0F;                       # VS16
        0;
    }

    sub _grapheme_cluster_len ($bytes) {
        my $len      = length($bytes);
        my $end      = 0;
        my $prev_zwj = 0;
        while ( $end < $len ) {
            my $b = ord( substr( $bytes, $end, 1 ) );
            last if ( $b & 0xC0 ) != 0xC0 && $b >= 0x80;
            my $clen = utf8_byte_len($b);
            last if $clen <= 0 || $end + $clen > $len;
            if ( $end == 0 ) {
                $end += $clen;
                $prev_zwj = 0;
                next;
            }
            my $sub = substr( $bytes, $end, $clen );
            my $cp  = _decode_cp($sub);
            last if $cp < 0;
            last if !$prev_zwj && !_is_grapheme_extender($cp);
            $end += $clen;
            $prev_zwj = ( $cp == 0x200D );
        }
        return $end;
    }

    # Cmd / Param helpers
    sub Prefix ($cmd) {
        ( $cmd >> PrefixShift ) & FinalMask;
    }

    sub Intermediate ($cmd) {
        ( $cmd >> IntermedShift ) & FinalMask;
    }

    sub Final ($cmd) {
        $cmd & FinalMask;
    }

    sub Command ( $prefix, $inter, $final ) {
        my $c = $final;
        $c |= $prefix << PrefixShift;
        $c |= $inter << IntermedShift;
        $c;
    }

    sub ParamVal ( $p, $def ) {
        my $v = $p & ParamMask;
        $v == MissingParam ? $def : $v;
    }

    sub HasMore ($p) {
        $p & HasMoreFlag ? 1 : 0;
    }

    sub Parameter ( $p, $has_more ) {
        my $s = $p & ParamMask;
        $s |= HasMoreFlag if $has_more;
        $s;
    }

    # Has*Prefix helpers
    sub HasCsiPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x9B ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('[') );
    }

    sub HasOscPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x9D ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord(']') );
    }

    sub HasApcPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x9F ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('_') );
    }

    sub HasDcsPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x90 ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('P') );
    }

    sub HasSosPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x98 ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('X') );
    }

    sub HasPmPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x9E ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('^') );
    }

    sub HasStPrefix ($b) {
        ( length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x9C ) ||
            ( length($b) > 1 && ord( substr( $b, 0, 1 ) ) == 0x1B && ord( substr( $b, 1, 1 ) ) == ord('\\') );
    }

    sub HasEscPrefix ($b) {
        length($b) > 0 && ord( substr( $b, 0, 1 ) ) == 0x1B;
    }
    #
    sub DecodeSequence ( $bytes, $state, $parser ) {
        my $len = length($bytes);
        for my $i ( 0 .. $len - 1 ) {
            my $c = ord( substr( $bytes, $i, 1 ) );
            if ( $state == NormalState ) {
                if ( $c == ESC ) {
                    if ( defined $parser ) {
                        $parser->{params}[0] = MissingParam if @{ $parser->{params} };
                        $parser->{cmd}       = 0;
                        $parser->{paramsLen} = 0;
                        $parser->{dataLen}   = 0;
                    }
                    $state = DecodeEscapeState;
                    next;
                }
                if ( $c == CSI || $c == DCS ) {
                    if ( defined $parser ) {
                        $parser->{params}[0] = MissingParam if @{ $parser->{params} };
                        $parser->{cmd}       = 0;
                        $parser->{paramsLen} = 0;
                        $parser->{dataLen}   = 0;
                    }
                    $state = DecodePrefixState;
                    next;
                }
                if ( $c == OSC || $c == APC || $c == SOS || $c == PM ) {
                    if ( defined $parser ) {
                        $parser->{cmd}     = MissingCommand;
                        $parser->{dataLen} = 0;
                    }
                    $state = DecodeStringState;
                    next;
                }
                if ( defined $parser ) {
                    $parser->{dataLen}   = 0;
                    $parser->{paramsLen} = 0;
                    $parser->{cmd}       = 0;
                }
                if ( $c > US && $c < DEL ) {
                    return ( substr( $bytes, $i, 1 ), 1, 1, NormalState );
                }
                if ( $c <= US || $c == DEL || $c < 0xC0 ) {
                    return ( substr( $bytes, $i, 1 ), 0, 1, NormalState );
                }

                # Check if it starts a UTF-8 multi-byte sequence
                if ( ( $c & 0xC0 ) == 0xC0 ) {
                    my $clen = utf8_byte_len($c);
                    if ( $clen > 1 && $i + $clen <= $len ) {
                        my $cluster_len = _grapheme_cluster_len( substr( $bytes, $i ) );
                        $cluster_len = $clen     if $cluster_len <= 0;
                        $cluster_len = $len - $i if $i + $cluster_len > $len;
                        my $seq = substr( $bytes, $i, $cluster_len );
                        return ( $seq, 1, $cluster_len, NormalState );
                    }

                    # Incomplete UTF-8, return the lone start byte
                    return ( substr( $bytes, $i, 1 ), 0, 1, NormalState );
                }
                return ( substr( $bytes, 0, $i ), 0, $i, NormalState );
            }
            if ( $state == DecodePrefixState ) {
                if ( $c >= ord('<') && $c <= ord('?') ) {
                    if ( defined $parser ) {
                        $parser->{cmd} &= ~( 0xff << PrefixShift );
                        $parser->{cmd} |= $c << PrefixShift;
                    }
                    next;
                }
                $state = DecodeParamsState;

                # Fall through
            }
            if ( $state == DecodeParamsState ) {
                if ( $c >= ord('0') && $c <= ord('9') ) {
                    if ( defined $parser ) {
                        if ( $parser->{params}[ $parser->{paramsLen} ] == MissingParam ) {
                            $parser->{params}[ $parser->{paramsLen} ] = 0;
                        }
                        $parser->{params}[ $parser->{paramsLen} ] *= 10;
                        $parser->{params}[ $parser->{paramsLen} ] += $c - ord('0');
                    }
                    next;
                }
                if ( $c == ord(':') ) {
                    if ( defined $parser ) {
                        $parser->{params}[ $parser->{paramsLen} ] |= HasMoreFlag;
                    }
                }
                if ( $c == ord(';') || $c == ord(':') ) {
                    if ( defined $parser ) {
                        $parser->{paramsLen}++;
                        if ( $parser->{paramsLen} < @{ $parser->{params} } ) {
                            $parser->{params}[ $parser->{paramsLen} ] = MissingParam;
                        }
                    }
                    next;
                }
                $state = DecodeIntermedState;

                # Fall through
            }
            if ( $state == DecodeIntermedState ) {
                if ( $c >= ord(' ') && $c <= ord('/') ) {
                    if ( defined $parser ) {
                        $parser->{cmd} &= ~( 0xff << IntermedShift );
                        $parser->{cmd} |= $c << IntermedShift;
                    }
                    next;
                }
                if ( defined $parser ) {
                    if ( ( $parser->{paramsLen} > 0 && $parser->{paramsLen} < @{ $parser->{params} } - 1 ) ||
                        ( $parser->{paramsLen} == 0 && @{ $parser->{params} } > 0 && $parser->{params}[0] != MissingParam ) ) {
                        $parser->{paramsLen}++;
                    }
                }
                if ( $c >= ord('@') && $c <= ord('~') ) {
                    if ( defined $parser ) {
                        $parser->{cmd} &= ~0xff;
                        $parser->{cmd} |= $c;
                    }
                    if ( HasDcsPrefix($bytes) ) {
                        if ( defined $parser ) {
                            $parser->{dataLen} = 0;
                        }
                        $state = DecodeStringState;
                        next;
                    }
                    return ( substr( $bytes, 0, $i + 1 ), 0, $i + 1, NormalState );
                }
                return ( substr( $bytes, 0, $i ), 0, $i, NormalState );
            }
            if ( $state == DecodeEscapeState ) {
                if ( $c == ord('[') || $c == ord('P') ) {
                    if ( defined $parser ) {
                        $parser->{params}[0] = MissingParam if @{ $parser->{params} };
                        $parser->{paramsLen} = 0;
                        $parser->{cmd}       = 0;
                    }
                    $state = DecodePrefixState;
                    next;
                }
                if ( $c == ord(']') || $c == ord('X') || $c == ord('^') || $c == ord('_') ) {
                    if ( defined $parser ) {
                        $parser->{cmd}     = MissingCommand;
                        $parser->{dataLen} = 0;
                    }
                    $state = DecodeStringState;
                    next;
                }
                if ( $c >= ord(' ') && $c <= ord('/') ) {
                    if ( defined $parser ) {
                        $parser->{cmd} &= ~( 0xff << IntermedShift );
                        $parser->{cmd} |= $c << IntermedShift;
                    }
                    next;
                }
                if ( $c >= ord('0') && $c <= ord('~') ) {
                    if ( defined $parser ) {
                        $parser->{cmd} &= ~0xff;
                        $parser->{cmd} |= $c;
                    }
                    return ( substr( $bytes, 0, $i + 1 ), 0, $i + 1, NormalState );
                }
                return ( substr( $bytes, 0, $i ), 0, $i, NormalState );
            }
            if ( $state == DecodeStringState ) {
                if ( $c == BEL && HasOscPrefix($bytes) ) {
                    _parse_osc_cmd($parser);
                    return ( substr( $bytes, 0, $i + 1 ), 0, $i + 1, NormalState );
                }
                if ( ( $c == CAN || $c == SUB ) && HasOscPrefix($bytes) ) {
                    _parse_osc_cmd($parser);
                    return ( substr( $bytes, 0, $i ), 0, $i, NormalState );
                }
                if ( $c == ST ) {
                    if ( HasOscPrefix($bytes) ) {
                        _parse_osc_cmd($parser);
                    }
                    return ( substr( $bytes, 0, $i + 1 ), 0, $i + 1, NormalState );
                }
                if ( $c == ESC ) {
                    if ( HasStPrefix( substr( $bytes, $i ) ) ) {
                        if ( HasOscPrefix($bytes) ) {
                            _parse_osc_cmd($parser);
                        }
                        return ( substr( $bytes, 0, $i + 2 ), 0, $i + 2, NormalState );
                    }
                    return ( substr( $bytes, 0, $i ), 0, $i, NormalState );
                }
                if ( defined $parser && $parser->{dataLen} < length( $parser->{data} ) ) {
                    substr( $parser->{data}, $parser->{dataLen}, 1 ) = chr($c);
                    $parser->{dataLen}++;
                    if ( $c == ord(';') && HasOscPrefix($bytes) ) {
                        _parse_osc_cmd($parser);
                    }
                }
            }
        }
        return ( $bytes, 0, $len, $state );
    }

    sub _parse_osc_cmd ($p) {
        return if !defined $p || $p->{cmd} != MissingCommand;
        my $dl = $p->{dataLen};
        for my $j ( 0 .. $dl - 1 ) {
            my $d = ord( substr( $p->{data}, $j, 1 ) );
            last if $d < ord('0') || $d > ord('9');
            if ( $p->{cmd} == MissingCommand ) {
                $p->{cmd} = 0;
            }
            $p->{cmd} *= 10;
            $p->{cmd} += $d - ord('0');
        }
    }

    # Read a color from SGR params starting at position $i.
    # Returns ( $color_hashref, $params_consumed ).
    sub _read_style_color ( $params, $i = () ) {
        my $n_params = scalar @$params;
        return ( undef, 0 ) if $i + 1 >= $n_params;
        my $s          = $params->[$i];          # The 38/48/58 param
        my $p          = $params->[ $i + 1 ];    # The color type param
        my $color_type = ParamVal( $p, 0 );
        my $s_has_more = HasMore($s);
        my $p_has_more = HasMore($p);
        my $n          = 2;

        if ( $color_type == 5 ) {

            # Indexed color: 38;5;N or 38:5:N
            return ( undef, 0 ) if $i + 2 >= $n_params;
            my $idx = ParamVal( $params->[ $i + 2 ], 0 );
            if ( $p_has_more && !$s_has_more ) {

                # colon: 38:5:idx
            }
            elsif ( !$p_has_more && !$s_has_more ) {

                # semicolon: 38;5;idx
            }
            else {
                return ( undef, 0 );
            }
            return ( { type => '256', index => $idx }, 3 );
        }
        elsif ( $color_type == 2 ) {

            # RGB color: 38;2;R;G;B or 38:2:R:G:B or 38:2::CSID:R:G:B
            return ( undef, 0 ) if $i + 4 >= $n_params;
            my ( $r, $g, $b );
            if ( $s_has_more && $p_has_more ) {

                # Colon-separated. Check for color space id:
                # 38:2::R:G:B has CSID at i+2, RGB at i+3..i+5
                # 38:2:R:G:B has RGB at i+2..i+4
                if ( $i + 5 < $n_params &&
                    HasMore( $params->[ $i + 2 ] ) &&
                    HasMore( $params->[ $i + 3 ] ) &&
                    HasMore( $params->[ $i + 4 ] ) &&
                    !HasMore( $params->[ $i + 5 ] ) ) {

                    # With color space id
                    $r = ParamVal( $params->[ $i + 3 ], 0 );
                    $g = ParamVal( $params->[ $i + 4 ], 0 );
                    $b = ParamVal( $params->[ $i + 5 ], 0 );
                    $n = 6;
                }
                else {
                    # Without color space id
                    $r = ParamVal( $params->[ $i + 2 ], 0 );
                    $g = ParamVal( $params->[ $i + 3 ], 0 );
                    $b = ParamVal( $params->[ $i + 4 ], 0 );
                    $n = 5;
                }
            }
            elsif ( !$s_has_more && !$p_has_more ) {

                # Semicolons: 38;2;R;G;B
                $r = ParamVal( $params->[ $i + 2 ], 0 );
                $g = ParamVal( $params->[ $i + 3 ], 0 );
                $b = ParamVal( $params->[ $i + 4 ], 0 );
                $n = 5;
            }
            else {
                return ( undef, 0 );
            }
            return ( { type => 'rgb', r => $r, g => $g, b => $b }, $n );
        }
        return ( undef, 0 );
    }
}
#
1;
