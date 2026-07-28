use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Cancer;
#
subtest escape => sub {
    is Cancer::Markup::escape('hello'),               'hello',                                     'No escaping needed';
    is Cancer::Markup::escape('\[bold]hello[/bold]'), qq-\\\\\\\[bold\\]\\\\hello\\[\\/bold\\]\\-, 'Escape brackets';
    is Cancer::Markup::escape('hello\\'),             qq-hello\\-,                                 'Escape single backslash';
    is Cancer::Markup::escape('hello\\\\'),           qq-hello\\\\-,                               'No extra escaping for double backslash';
    is Cancer::Markup::escape('hello\\[bold]'),       qq-hello\\\\\\[bold\\]\\\\-,                 'Escape backslash before bracket';
};
#
done_testing;
