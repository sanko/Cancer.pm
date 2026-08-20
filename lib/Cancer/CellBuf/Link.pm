use v5.42;
use experimental 'class';
class Cancer::CellBuf::Link v0.0.1 {
    field $url    : param : reader = '';
    field $params : param : reader = '';
    method empty () { $url eq '' && $params eq '' }

    method reset () {
        $url    = '';
        $params = '';
        return $self;
    }
    method set_url    ($u) { $url    = $u; return $self }
    method set_params ($p) { $params = $p; return $self }

    method equal ($other) {
        return 1 if $self == $other;
        return 0 unless defined $other;
        $url eq $other->url && $params eq $other->params;
    }

    method clone () {
        return __CLASS__->new( url => $url, params => $params );
    }
} 1;
