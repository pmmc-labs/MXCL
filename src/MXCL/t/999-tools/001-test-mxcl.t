#!perl

use v5.42;
use Test::MXCL qw[ test_mxcl ];

test_mxcl(q[

    (ok true "... hello TAP world")

    (is 10 10 "... hello is() world")

    (done-testing)

]);
