use Test2::V0;
use lib 'lib', '../lib';
use Cancer;
$|++;
diag 'Cancer v' . $Cancer::VERSION;
ok 'works';
done_testing();
