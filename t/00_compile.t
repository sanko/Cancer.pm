#!perl
use Test2::V0;
use Test2::Tools::Exception qw[dies];
use lib 'lib', '../lib';
END { done_testing(); }
$|++;
ok 'use Cancer';
