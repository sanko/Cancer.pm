use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer::Text;
#
subtest divide => sub {

    # Test empty offsets
    my $text = Cancer::Text->new( text => 'hello world' );
    is $text->divide(),       ['hello world'],           'empty offsets';
    is $text->divide(5),      [ 'hello', ' world' ],     'single offset';
    is $text->divide( 2, 7 ), [ 'he', 'llo w', 'orld' ], 'multiple offset';
    is $text->divide(15),     [ 'hello world', '' ],     'offsets beyond text length';

    #~ # Test offsets beyond text length
    #~ is_deeply( $text->divide( [15] )->to_list, [ $text->copy(), Text->new('') ], 'Offset beyond length' );
    #~ # Test overlapping offsets
    #~ is_deeply( $text->divide( [ 3, 2 ] )->to_list, [ $text->substr( 0, 2 ), $text->substr(2) ], 'Overlapping offsets' );
};
subtest 'Cancer::Text' => sub {
    subtest generic => sub {
        isa_ok my $text = Cancer::Text->new(), ['Cancer::Text'];
        note 'append plain text';
        $text .= 'Hey' . 'Two';
        is $text,      'HeyTwo', 'checking new text';
        is $text->[3], 'T',      'fetch like an array';
        isa_ok $text, ['Cancer::Text'], 'make sure it is still an object';
        #
        use Data::Dump;
        ddx $text->markup;
    };
    subtest whitespace => sub {
        isa_ok my $text = Cancer::Text->new( text => "This is a test before the tab.\tAnd after the tab." ), ['Cancer::Text'];
        ok $text->expand_tabs, 'expand_tabs';
        is $text, 'This is a test before the tab.    And after the tab.', 'tabs expanded to spaces';
    };
    subtest rich => sub {
        isa_ok my $text
            = Cancer::Text->new( text =>
                "\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n"
            ), ['Cancer::Text'];

        #~
        $text->highlight_words( ['Lorem'], 'bold' );
        $text->highlight_words( ["ipsum"], "italic" );
        diag $text;
        #
        #~ console = Console()
        #
        #~ console.rule("justify='left'")
        #~ console.print(text, style="red")
        #~ console.print()
        #
        #~ console.rule("justify='center'")
        #~ console.print(text, style="green", justify="center")
        #~ console.print()
        #
        #~ console.rule("justify='right'")
        #~ console.print(text, style="blue", justify="right")
        #~ console.print()
        #
        #~ console.rule("justify='full'")
        #~ console.print(text, style="magenta", justify="full")
        #~ console.print()
    }
};
#
done_testing;
