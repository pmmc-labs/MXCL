#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

pass('... calling tests from Perl');

# run tests in mxcl
test_mxcl(q[

    (ok true "... hello MXCL TAP world")

    (is 10 10 "... 10 == 10")

]);

# do other stuff in Perl
pass('... back to Perl');

test_mxcl(q[

    (is "Hello" ("He" ~ "llo") "... got the same things")


    (done-testing)

]);

# Optionally call done_testing in Perl
# if you want to do some tests after
# the MXCL tests.
#
# ok($something, '... test after MXCL runs here');
#
# done_testing;
