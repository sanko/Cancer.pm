use v5.42;
use experimental 'class';
use Test2::V1 -ipP;
use lib 'lib', '../lib';
use blib;

# Ported from charmbracelet/x/ansi/sixel/raster_test.go
use Cancer::Ansi::Sixel qw[Raster WriteRaster DecodeRaster];
#
subtest WriteRaster => sub {
    is WriteRaster( 1, 2, 0, 0 ), '"1;2',     'basic case';
    is WriteRaster( 2, 3, 4, 5 ), '"2;3;4;5', 'with ph and pv';
    is WriteRaster( 2, 0, 0, 0 ), '"1;1',     'zero pad converts to 1,1';
    is WriteRaster( 1, 2, 3, 0 ), '"1;2;3;0', 'with ph only';
    is WriteRaster( 1, 2, 0, 3 ), '"1;2;0;3', 'with pv only';
};
subtest Raster => sub {
    is Raster( Pan => 1, Pad => 2 )->String, '"1;2', 'basic case';
    is Raster( Pan => 2, Pad => 3, Ph => 4, Pv => 5 )->String, '"2;3;4;5', 'full attributes';
};
subtest DecodeRaster => sub {
    my @tests = (
        { name => 'basic case',              input => '"1;2',     want_pan => 1, want_pad => 2, want_ph => 0, want_pv => 0, read => 4 },
        { name => 'full attributes',         input => '"2;3;4;5', want_pan => 2, want_pad => 3, want_ph => 4, want_pv => 5, read => 8 },
        { name => 'empty input',             input => '',         want_pan => 0, want_pad => 0, want_ph => 0, want_pv => 0, read => 0 },
        { name => 'invalid start character', input => 'x1;2',     want_pan => 0, want_pad => 0, want_ph => 0, want_pv => 0, read => 0 },
        { name => 'too short',               input => '"1',       want_pan => 1, want_pad => 0, want_ph => 0, want_pv => 0, read => 2 },
        { name => 'invalid character',       input => '"1;a',     want_pan => 1, want_pad => 0, want_ph => 0, want_pv => 0, read => 3 },
        { name => 'partial attributes',      input => '"1;2;3',   want_pan => 1, want_pad => 2, want_ph => 3, want_pv => 0, read => 6 }
    );
    for my $tt (@tests) {
        subtest $tt->{name} => sub {
            my ( $got, $n ) = DecodeRaster( $tt->{input} );
            is $got->Pan, $tt->{want_pan}, 'Pan';
            is $got->Pad, $tt->{want_pad}, 'Pad';
            is $got->Ph,  $tt->{want_ph},  'Ph';
            is $got->Pv,  $tt->{want_pv},  'Pv';
            is $n,        $tt->{read},     'read';
        }
    }
};
subtest 'Raster->String' => sub {
    is Raster( Pan => 1, Pad => 2 )->String, '"1;2', 'basic case';
    is Raster( Pan => 2, Pad => 3, Ph => 4, Pv => 5 )->String, '"2;3;4;5', 'full attributes';
};
#
done_testing;
