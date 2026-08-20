use v5.42;

package Cancer::CellBuf::Link v0.0.1 {

    sub new ( $class, %args ) {
        bless { url => $args{url} // '', params => $args{params} // '' }, $class;
    }
    sub url    ($self) { $self->{url} }
    sub params ($self) { $self->{params} }
    sub empty  ($self) { $self->{url} eq '' && $self->{params} eq '' }
    sub reset  ($self) { $self->{url} = ''; $self->{params} = ''; $self }

    sub equal ( $self, $other ) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $self->{url} eq $other->{url} && $self->{params} eq $other->{params};
    }
    sub clone ($self) { bless {%$self}, ref $self }
}
1;
