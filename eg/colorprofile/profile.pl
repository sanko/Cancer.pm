use v5.42;
use lib '../../lib';
use Cancer::ColorProfile qw[:constants :all];
use Cancer::ColorProfile::Writer;

# Detect the color profile for stdout.
my $p = Detect( \*STDOUT );
printf "Your color profile is what we call '%s'.\n\n", Profile_String($p);

# Let's talk about the profile.
my $desc = do {
    if    ( $p == TrueColor ) {'fancy'}
    elsif ( $p == ANSI256 )   {'1990s fancy'}
    elsif ( $p == ANSI )      {'normcore'}
    elsif ( $p == ASCII )     {'ancient'}
    elsif ( $p == NoTTY )     {'naughty!'}
    else                      {'...IDK'}
};
printf "You know, your colors are quite %s.\n\n", $desc;

# Here's a nice color.
my $rgb = { type => 'rgb', r => 0x6b, g => 0x50, b => 0xff };
printf "A cute color we like is: #%02x%02x%02x.\n\n", $rgb->{r}, $rgb->{g}, $rgb->{b};

# Let's convert it to the detected color profile.
my $converted = Convert( $p, $rgb );
if ( defined $converted ) {
    printf "This terminal needs that color to be a %s, at best.\n", $converted->{type};
    if ( $converted->{type} eq '256' ) {
        printf "In this case that color is 256-color index %d.\n\n", $converted->{index};
    }
    elsif ( $converted->{type} eq 'basic' ) {
        printf "In this case that color is basic color %d.\n\n", $converted->{code};
    }
    elsif ( $converted->{type} eq 'rgb' ) {
        printf "In this case that color is RGB(%d,%d,%d).\n\n", $converted->{r}, $converted->{g}, $converted->{b};
    }
    else {
        print "\n";
    }
}
else {
    print "This terminal doesn't support color (the color was stripped).\n\n";
}

# Now let's convert it to a color profile that only supports up to 256 colors.
my $ansi256_color = Convert( ANSI256, $rgb );
printf "Apple Terminal would want this color to be: %d (a %s).\n\n", $ansi256_color->{index}, $ansi256_color->{type};

# But really, who has time to convert? Not you? Well, kiddo, here's
# a magical writer that will just auto-convert whatever ANSI you throw at
# it to the appropriate color profile.
my $cute_ansi = "\e[38;2;107;80;255mCute \e[1;3mpuppy!!\e[m";
my $w         = Cancer::ColorProfile::Writer->new( forward => \*STDOUT );
$w->write("This terminal: $cute_ansi\n");

# But we're old school. Make the writer only use 4-bit ANSI, 1980s style.
$w = Cancer::ColorProfile::Writer->new( forward => \*STDOUT, profile => ANSI );
$w->write("4-bit ANSI: $cute_ansi\n");

# Too colorful. Use black and white only.
$w = Cancer::ColorProfile::Writer->new( forward => \*STDOUT, profile => ASCII );
$w->write("Old school cool: $cute_ansi\n");

# That's way too modern. Let's go back to MIT in the 1970s.
$w = Cancer::ColorProfile::Writer->new( forward => \*STDOUT, profile => NoTTY );
$w->write("No TTY :(: $cute_ansi\n");
