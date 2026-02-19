#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- define creates a Lambda that can call itself by its own name ---
# The apply mechanism injects the Lambda's own name into the local env
# so the body can reference it for self-calls.

test_mxcl(q[
    (define factorial (n)
        (if (n == 0)
            1
            (n * (factorial (n - 1)))))

    (is (factorial 0) 1   "... factorial 0 = 1 (base case)")
    (is (factorial 1) 1   "... factorial 1 = 1")
    (is (factorial 5) 120 "... factorial 5 = 120")
    (is (factorial 6) 720 "... factorial 6 = 720")
]);

# --- recursive countdown produces the correct final value ---

test_mxcl(q[
    (define count-down (n)
        (if (n == 0)
            0
            (count-down (n - 1))))

    (is (count-down 0)   0 "... count-down 0 = 0")
    (is (count-down 1)   0 "... count-down 1 terminates at 0")
    (is (count-down 100) 0 "... count-down 100 terminates at 0")
]);

# --- recursive sum: sum of 1..n ---

test_mxcl(q[
    (define sum-to (n)
        (if (n == 0)
            0
            (n + (sum-to (n - 1)))))

    (is (sum-to 0)  0  "... sum-to 0 = 0")
    (is (sum-to 4) 10  "... sum-to 4 = 10 (1+2+3+4)")
    (is (sum-to 5) 15  "... sum-to 5 = 15 (1+2+3+4+5)")
]);

done_testing;
