use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';

# Ported from charmbracelet/x/ansi/sixel/raster_test.go
use Cancer::Ansi::Sixel qw(
    Raster WriteRaster DecodeRaster
);
subtest 'TestWriteRaster' => sub {
    my @tests = (
        { name => 'basic case',               pan => 1, pad => 2, ph => 0, pv => 0, want => '"1;2', },
        { name => 'with ph and pv',           pan => 2, pad => 3, ph => 4, pv => 5, want => '"2;3;4;5', },
        { name => 'zero pad converts to 1,1', pan => 2, pad => 0, ph => 0, pv => 0, want => '"1;1', },
        { name => 'with ph only',             pan => 1, pad => 2, ph => 3, pv => 0, want => '"1;2;3;0', },
        { name => 'with pv only',             pan => 1, pad => 2, ph => 0, pv => 3, want => '"1;2;0;3', },
    );
    for my $tt (@tests) {
        my $got = WriteRaster( $tt->{pan}, $tt->{pad}, $tt->{ph}, $tt->{pv} );
        is $got, $tt->{want}, $tt->{name};
    }
};
subtest 'TestRaster_WriteTo' => sub {
    my @tests = (
        { name => 'basic case', raster => Raster( Pan => 1, Pad => 2 ), want => '"1;2', },
        { name => 'full attributes', raster => Raster( Pan => 2, Pad => 3, Ph => 4, Pv => 5 ), want => '"2;3;4;5', },
    );
    for my $tt (@tests) {
        my $got = $tt->{raster}->String;
        is $got, $tt->{want}, $tt->{name};
    }
};
subtest 'TestDecodeRaster' => sub {
    my @tests = (
        { name => 'basic case',              input => '"1;2',     want_pan => 1, want_pad => 2, want_ph => 0, want_pv => 0, read => 4, },
        { name => 'full attributes',         input => '"2;3;4;5', want_pan => 2, want_pad => 3, want_ph => 4, want_pv => 5, read => 8, },
        { name => 'empty input',             input => '',         want_pan => 0, want_pad => 0, want_ph => 0, want_pv => 0, read => 0, },
        { name => 'invalid start character', input => 'x1;2',     want_pan => 0, want_pad => 0, want_ph => 0, want_pv => 0, read => 0, },
        { name => 'too short',               input => '"1',       want_pan => 1, want_pad => 0, want_ph => 0, want_pv => 0, read => 2, },
        { name => 'invalid character',       input => '"1;a',     want_pan => 1, want_pad => 0, want_ph => 0, want_pv => 0, read => 3, },
        { name => 'partial attributes',      input => '"1;2;3',   want_pan => 1, want_pad => 2, want_ph => 3, want_pv => 0, read => 6, },
    );
    for my $tt (@tests) {
        my ( $got, $n ) = DecodeRaster( $tt->{input} );
        is $got->Pan, $tt->{want_pan}, "$tt->{name} Pan";
        is $got->Pad, $tt->{want_pad}, "$tt->{name} Pad";
        is $got->Ph,  $tt->{want_ph},  "$tt->{name} Ph";
        is $got->Pv,  $tt->{want_pv},  "$tt->{name} Pv";
        is $n,        $tt->{read},     "$tt->{name} read";
    }
};
subtest 'TestRaster_String' => sub {
    my @tests = (
        { name => 'basic case', raster => Raster( Pan => 1, Pad => 2 ), want => '"1;2', },
        { name => 'full attributes', raster => Raster( Pan => 2, Pad => 3, Ph => 4, Pv => 5 ), want => '"2;3;4;5', },
    );
    for my $tt (@tests) {
        my $got = $tt->{raster}->String;
        is $got, $tt->{want}, $tt->{name};
    }
};
done_testing;
