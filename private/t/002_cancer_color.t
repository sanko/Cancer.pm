use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer::Color;
#
subtest 'Cancer::ColorSystem' => sub {
    isa_ok my $truecolor = Cancer::ColorSystem::TRUECOLOR->new(), ['Cancer::ColorSystem'];
    is $truecolor,     'Cancer::ColorSystem::TRUECOLOR', 'stringify';
    is int $truecolor, 3,                                'numeric';
};
subtest 'Cancer::ColorType' => sub {
    isa_ok my $truecolor = Cancer::ColorType::TRUECOLOR->new(), ['Cancer::ColorType'];
    is $truecolor,     'Cancer::ColorType::TRUECOLOR', 'stringify';
    is int $truecolor, 3,                              'numeric';
};
subtest 'Cancer::Color::Triplet' => sub {
    subtest 'black' => sub {
        isa_ok my $black = Cancer::Color::Triplet->new( red => 0, green => 0, blue => 0 ), ['Cancer::Color::Triplet'];
        is $black->hex,            '#000000',    'hex';
        is $black->rgb,            'rgb(0,0,0)', 'rgb';
        is [ $black->normalized ], [ 0, 0, 0 ],  'normalized';
    };
    subtest 'flame red' => sub {
        isa_ok my $black = Cancer::Color::Triplet->new( red => 175, green => 43, blue => 30 ), ['Cancer::Color::Triplet'];
        is $black->hex, '#af2b1e',        'hex';
        is $black->rgb, 'rgb(175,43,30)', 'rgb';
        is [ $black->normalized ],
            [ float( 0.6862, tolerance => 0.0001 ), float( 0.1686, tolerance => 0.0001 ), float( 0.1176, tolerance => 0.001 ) ], 'normalized';
    }
};
#
done_testing;
