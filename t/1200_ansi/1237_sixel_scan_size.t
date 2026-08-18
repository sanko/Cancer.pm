use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Port of TestScanSize from charmbracelet/x/ansi/sixel/sixel_test.go
use Cancer::Ansi::Sixel qw(DecodeRepeat);
use constant LINE_BREAK        => ord('-');
use constant CARRIAGE_RETURN   => ord('$');
use constant REPEAT_INTRODUCER => ord('!');

sub _scanSize ($data) {
    return ( 0, 0 ) if !defined $data || $data eq '';
    my @d = unpack 'C*', $data;
    my ( $max_width, $band_count, $cur_width ) = ( 0, 0, 0 );
    my $new_band = 1;
    my $i        = 0;
    while ( $i < @d ) {
        my $b = $d[$i];
        if ( $b == LINE_BREAK ) {
            $cur_width = 0;
            $new_band  = 1;
        }
        elsif ( $b == CARRIAGE_RETURN ) {
            $cur_width = 0;
        }
        elsif ( $b == REPEAT_INTRODUCER || ( $b >= ord('?') && $b <= ord('~') ) ) {
            my $count = 1;
            if ( $b == REPEAT_INTRODUCER ) {
                my $rest = substr $data, $i;
                my ( $r, $n ) = DecodeRepeat($rest);
                return ( $max_width, $band_count * 6 ) if $n == 0;
                $i += $n - 1;
                $count = $r->Count;
            }
            $cur_width += $count;
            if ($new_band) {
                $new_band = 0;
                $band_count++;
            }
            $max_width = $cur_width if $cur_width > $max_width;
        }
        $i++;
    }
    return ( $max_width, $band_count * 6 );
}
subtest 'TestScanSize' => sub {
    my @tests = (
        { name => 'two lines',                   data => "~~~~~~-~~~~~~-",                                             want_w => 6,  want_h => 12 },
        { name => 'two lines no newline at end', data => "~~~~~~-~~~~~~",                                              want_w => 6,  want_h => 12 },
        { name => 'no pixels',                   data => "",                                                           want_w => 0,  want_h => 0 },
        { name => 'smaller carriage returns',    data => '~$~~$~~~$~~~~$~~~~~$~~~~~~',                                 want_w => 6,  want_h => 6 },
        { name => 'transparent',                 data => "??????",                                                     want_w => 6,  want_h => 6 },
        { name => 'RLE',                         data => "??!20?",                                                     want_w => 22, want_h => 6 },
        { name => 'Colors',                      data => "#0;2;0;0;0~~~~~\$#1;2;100;100;100;~~~~~~-#0~~~~~~-#1~~~~~~", want_w => 6,  want_h => 18 },
    );
    for my $tt (@tests) {
        my ( $w, $h ) = _scanSize( $tt->{data} );
        is $w, $tt->{want_w}, "$tt->{name} width";
        is $h, $tt->{want_h}, "$tt->{name} height";
    }
};
done_testing;
