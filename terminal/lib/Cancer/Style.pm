package Cancer::Style 0.5 {
    use v5.36;

    # color     Color
    # bgcolor   Color
    # bold      bool
    # italic    bool
    # blink     bool
    # blink2    bool
    sub new ( $class, %args ) {
        bless \%args, $class;
    }

    sub open ($self) {
        my $ret = '';
        $ret .= Cancer::Terminal::bold()       if $self->{bold};
        $ret .= Cancer::Terminal::italic()     if $self->{italic};
        $ret .= Cancer::Terminal::slow_blink() if $self->{blink};
        $ret .= Cancer::Terminal::fast_blink() if $self->{blink2};

     #~ $ret .= Cancer::Terminal::bg_rgb( $self->{bgcolor}->rgb ) if $self->{bgcolor} && $self->{bgcolor}->{type} == Cancer::ColorSystem::TRUECOLOR();
     #~ $ret .= Cancer::Terminal::fg_rgb( $self->{color}->rgb )   if $self->{color}   && $self->{color}->{type} == Cancer::ColorSystem::TRUECOLOR();
        $ret;
    }

    sub close ($self) {
        my $ret = '';

        #~ $ret .= Cancer::Terminal::bg_reset()        if $self->{bgcolor};
        #~ $ret .= Cancer::Terminal::fg_reset()        if $self->{color};
        $ret .= Cancer::Terminal::disable_blink()   if $self->{blink2} || $self->{blink};
        $ret .= Cancer::Terminal::normal_emphasis() if $self->{italic};
        $ret .= Cancer::Terminal::normal_weight()   if $self->{bold};
        $ret;
    }
}

#~ sub reset ()            { SGR 0 }
#~ sub bold()              { SGR 1 }
#~ sub dim()               { SGR 2 }
#~ sub italic()            { SGR 3 }
#~ sub underline()         { SGR 4 }
#~ sub slow_blink()        { SGR 5 }
#~ sub fast_blink()        { SGR 6 }
#~ sub invert ()           { SGR 7 }
#~ sub hide()              { SGR 8 }
#~ sub strike()            { SGR 9 }
#~ sub default_font()      { SGR 10 }
#~ sub alternate_font ($n) { Carp::confess 'Alternate font should be between 1 and 9' unless 1 <= $n <= 9; SGR 10 + $n }
#~ sub gothic ()           { SGR 20 }
#~ sub double_underline()  { SGR 21 }
#~ sub normal_weight()     { SGR 22 }                                                                                      # disables bold and dim
#~ sub normal_emphasis()   { SGR 23 }                                                                                      # disables italic
#~ sub disable_underline() { SGR 24 }    # disables underline and double_underline
#~ sub disable_blink()     { SGR 25 }    # disables slow and fast blink
#~ sub disable_invert()    { SGR 27 }
#~ sub disable_hide()      { SGR 28 }
#~ sub disable_strike()    { SGR 29 }
1;
