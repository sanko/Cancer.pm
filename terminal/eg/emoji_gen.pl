use Data::Dump;
use strict;
use warnings;
use HTTP::Tiny;
use utf8;
binmode STDOUT, ':utf8';
$|++;
use Path::Tiny;
my $emoji_pm = path('../lib/Cancer/Emoji.pm');
my $content  = HTTP::Tiny->new->get('https://unicode.org/Public/emoji/latest/emoji-test.txt')->{content};
my @lines    = split /\n+/, $content;
my ( $date, $version, $group, $subgroup, %emoji );
my %fix = (    # Some are hard to 'fix' properly and will need to be static here
    a_button_                   => 'blood_type_a',
    ab_button_                  => 'blood_type_ab',
    b_button_                   => 'blood_type_b',
    o_button_                   => 'blood_type_o',
    flag_myanmar_               => 'flag_myanmar',
    "flag_\xC3\x85land_islands" => 'flag_aland_islands',
    "flag_cura\xC3\xA7ao"       => 'flag_curacao',
    "flag_c\xC3\xB4te_d_ivoire" => 'flag_cote_d_ivoire',
    'flag_cocos__islands'       => 'flag_cocos_islands',
    'flag_hong_kong_sar_china', => 'flag_hong_kong',
    'flag_macao_sar_china'      => 'flag_macau',
    "flag_t\xC3\xBCrkiye"       => 'flag_turkey',
    "pi\xC3\xB1ata"             => 'pinata'
);
my %subcats = (
    'face-smiling'           => 'Smiling Faces',
    'face-affection'         => 'Faces w/ Affection',
    'face-tongue'            => 'Faces w/ Tongue',
    'face-hand'              => 'Faces w/ Hands',
    'face-neutral-skeptical' => 'Neutral & Skeptical Faces',
    'face-sleepy'            => 'Sleepy Faces',
    'face-unwell'            => 'Sick Faces',
    'face-hat'               => 'Faces w/ Hats',
    'face-glasses'           => 'Faces w/ Glasses',
    'face-concerned'         => 'Concerned Faces',
    'face-negative'          => 'Negative Faces',
    'face-costume'           => 'Faces w/ Costumes',
    'cat-face'               => 'Cat Faces',
    'monkey-face'            => 'Monkey Faces',
    'heart'                  => 'Hearts',
    'emotion'                => 'Emotions',
    'hand-fingers-open'      => 'Open Hands',
    'hand-fingers-partial'   => 'Partially Open Hands',
    'hand-single-finger'     => 'Hands w/ One Finger',
    'hand-fingers-closed'    => 'Closed Hands',
    'hands'                  => 'Hands',
    'hand-prop'              => 'Hands w/ Props',
    'body-parts'             => 'Bodyparts',
    'person'                 => 'People',
    'person-gesture'         => 'People Gesturing',
    'animal-marine'          => 'Marine Animals',
    'animal-reptile'         => 'Reptiles',
    'animal-bug'             => 'Insects',
    'animal-amphibian'       => 'Amphibians',
    'animal-bird'            => 'Birds',
    'subdivision-flag'       => 'Regional Flags',
    'plant-flower'           => 'Flowers',
    'flag'                   => 'Flags',
    'country-flag'           => 'Country Flags',
    'geometric'              => 'Geometric Shapes',
    'alphanum'               => 'Alphanumeric',
    keycap                   => 'Keycaps',
    'other-symbol'           => 'Other Symbols',
    currency                 => 'Currency',
    punctuation              => 'Punctuation',
    math                     => 'Math',
    gender                   => 'Gender',
    'av-symbol'              => 'Audio/Video',
    zodiac                   => 'Zodiac Symbols',
    religion                 => 'Religious Symbols',
    arrow                    => 'Arrows',
    warning                  => 'Warnings',
    'transport-sign'         => 'Traffic Signs',
    'other-object'           => 'Other Objects',
    household                => 'Household Objects',
    medical                  => 'Medical',
    science                  => 'Science',
    tool                     => 'Tools',
    lock                     => 'Locks',
    office                   => 'Office Objects',
    writing                  => 'Writing',
    mail                     => 'Mail',
    money                    => 'Money',
    'book-paper'             => 'Books & Paper',
    'light & video'          => 'Light & Video',
    computer                 => 'Computers',
    phone                    => 'Phones',
    'musical-instrument'     => 'Musical Instruments',
    music                    => 'Music',
    sound                    => 'Sound',
    clothing                 => 'Clothing',
    'arts & crafts'          => 'Arts & Crafts',
    game                     => 'Games',
    sport                    => 'Sports',
    'award-medal'            => 'Awards & Medals',
    event                    => 'Events',
    'sky & weather'          => 'Sky & Weather',
    time                     => 'Time',
    hotel                    => 'Hotels',
    'transport-air'          => 'Air Transportation',
    'transport-water'        => 'Water Transportation',
    'transport-ground'       => 'Ground Transportation',
    'place-other'            => 'Other Places',
    'place-religious'        => 'Religious Places',
    'place-building'         => 'Buildings',
    'place-map'              => 'Maps',
    'place-geographic'       => 'Geography',
    dishware                 => 'Dishware',
    drink                    => 'Drinks',
    'food-marine'            => 'Seafood',
    'food-sweet'             => 'Sweets',
    'food-asian'             => 'Asian Foods',
    'food-prepared'          => 'Prepared Foods',
    'food-vegetable'         => 'Vegetables',
    'food-fruit'             => 'Fruits',
    'plant-other'            => 'Plants',
    'skin-tone'              => 'Skin Tones',
    'hair-style'             => 'Hair Styles',
    'animal-mammal'          => 'Mammals',
    'person-symbol'          => 'People (Symbolic)',
    'person-role'            => 'People (Roles)',
    'person-fantasy'         => 'People (Fantasy)',
    'person-activity'        => 'People (Activity)',
    'person-sport'           => 'People Playing Sports',
    'person-resting'         => 'People Resting',
    family                   => 'Family',
);
for my $line (@lines) {
    $date     = $1           if $line =~ /^# Date: (.+)$/;
    $version  = $1           if $line =~ /^# Version: (.+)$/;
    $group    = $1           if $line =~ /^# group: (.+)$/;
    $subgroup = $subcats{$1} if $line =~ /^# subgroup: (.+)$/;
    next if $line =~ /^#/;

    #~ https://github.com/Textualize/rich/blob/26152e9cc95eef9c8f363d7bf1dfda426275348d/rich/_emoji_codes.py#L2351
    my ( $code, $status, $name ) = $line =~ m[^([A-F\d\s]+?)\s+;\s+(.+?)\s+#.*?E\d+\.\d+\s+(.+)$];

    #~ die unless length $subcats{$subgroup};
    #~ $subgroup = $subcats{$subgroup};
    #~ ddx [ $code, $status, $name ];
    #~ $name =~ s[^$subgroup:][];
    my $fix_name = lc $name;
    $code = join '', map { chr hex $_ } split ' ', $code;
    $fix_name =~ s[\xE2\x80\x99][_]g;
    $fix_name =~ s[\xE2\x80\x9D]["]g;
    $fix_name =~ s[\xE2\x80\x9C]["]g;
    $fix_name =~ s[\xC3\xA9][e]g;
    $fix_name =~ s[\xC3\xAD][e]g;
    $fix_name =~ s[\xC3\xA3][a]g;
    $fix_name =~ s[[”“]]["]g;
    $fix_name =~ s[[:\s\-\,\.]+][_]g;
    $fix_name =~ s[__+][_]g;
    $fix_name =~ s[__][_]g;
    $fix_name =~ s[\(.+\)][]g;          # Myanmar (Burma)
    $fix_name =~ s[ñ][n];               # Piñata
    $fix_name =~ s[é][e];               # Réunion
    $fix_name =~ s[_u_s_][_us_]g;

    #~ $fix_name = 'flag_ivory_coast'  if $name eq 'flag: Côte d’Ivoire';
    #~ $fix_name = 'flag_sao_tome'     if $name eq 'flag: São Tomé & Príncipe';
    #~ $fix_name = 'flag_turkey'       if $name eq 'flag: Türkiye';
    $fix_name = $fix{$fix_name}     if defined $fix{$fix_name};
    $fix_name = $fix_name . '-text' if defined $emoji{$group}{$subgroup}{$fix_name} && $status eq 'unqualified';
    $emoji{$group}{$subgroup}{$fix_name} //= [ $code, $status, $name ];
}

#~ warn $date;
#~ warn $version;
#~ ddx \%emoji;
my $data = sprintf "package Cancer::Emoji %.2f {\nuse v5.36;\nuse utf8;\nmy \$emoji = ", $version;
{
    my %flat;
    for my $group ( sort keys %emoji ) {
        for my $subgroup ( sort keys %{ $emoji{$group} } ) {
            for my $emoji ( sort keys %{ $emoji{$group}{$subgroup} } ) {
                $flat{$emoji} = $emoji{$group}{$subgroup}{$emoji}->[0];
            }
        }
    }
    $data .= Data::Dump::pp( \%flat ) . ';';
}
$data .= sprintf <<'END', $version, $date;
    sub locate($name) { $emoji->{$name} // () }
}
1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Cancer::Emoji - Emoji List

=head1 Description

This list is based on <the full emoji list from Unicode.org|https://unicode.org/Public/emoji/latest/emoji-test.txt>.

Current version: %s
Date: %s

=head1 Emojis

This is the current list of emojis by category.

END
for my $group ( sort keys %emoji ) {
    $data .= sprintf "=head2 %s\n\n", $group;
    for my $subgroup ( sort keys %{ $emoji{$group} } ) {
        $data .= sprintf "=head3 %s\n\n=over\n\n", $subgroup;
        for my $emoji ( sort keys %{ $emoji{$group}{$subgroup} } ) {
            $data .= sprintf "=item C<:%s:> - %s\n\n", $emoji, $emoji{$group}{$subgroup}{$emoji}->[0];
        }
        $data .= "=back\n\n";
    }
}
$data .= sprintf <<'END';
=head1 Author

Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2024 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the terms of The Artistic License 2.0.
See http://www.perlfoundation.org/artistic_license_2_0.  For clarification, see
http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the Creative Commons Attribution-Share Alike
3.0 License. See http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification, see
http://creativecommons.org/licenses/by-sa/3.0/us/.

=begin stopwords

termbox tty

=end stopwords

=cut

END
$emoji_pm->spew_utf8($data);
`tidyall -a`;
