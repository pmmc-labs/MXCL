#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "define creates a Lambda that can call itself by its own name")
    (define factorial (n)
        (if (n == 0)
            1
            (n * (factorial (n - 1)))))

    (is (factorial 0) 1   "... factorial 0 = 1 (base case)")
    (is (factorial 1) 1   "... factorial 1 = 1")
    (is (factorial 5) 120 "... factorial 5 = 120")
    (is (factorial 6) 720 "... factorial 6 = 720")

    (diag "factorial with (n <= 1) base case variant")
    (define factorial2 (n)
        (if (n <= 1)
            1
            (n * (factorial2 (n - 1)))))

    (is (factorial2 0) 1   "... factorial2 0 = 1")
    (is (factorial2 1) 1   "... factorial2 1 = 1")
    (is (factorial2 5) 120 "... factorial2 5 = 120")

    (diag "recursive countdown produces the correct final value")
    (define count-down (n)
        (if (n == 0)
            0
            (count-down (n - 1))))

    (is (count-down 0)   0 "... count-down 0 = 0")
    (is (count-down 1)   0 "... count-down 1 terminates at 0")
    (is (count-down 100) 0 "... count-down 100 terminates at 0")

    (diag "recursive sum: sum of 1..n")
    (define sum-to (n)
        (if (n == 0)
            0
            (n + (sum-to (n - 1)))))

    (is (sum-to 0)  0  "... sum-to 0 = 0")
    (is (sum-to 4) 10  "... sum-to 4 = 10 (1+2+3+4)")
    (is (sum-to 5) 15  "... sum-to 5 = 15 (1+2+3+4+5)")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}
