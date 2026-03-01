#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "true condition selects the then-branch")
    (is (if true  1 2) 1 "... true  => then-branch (1)")
    (is (if false 1 2) 2 "... false => else-branch (2)")

    (diag "condition is evaluated; branches receive the result")
    (let x 5)
    (is (if (x == 5) "yes" "no") "yes" "... (x == 5) is truthy; then-branch taken")
    (is (if (x == 9) "yes" "no") "no"  "... (x == 9) is falsy; else-branch taken")

    (diag "nested if")
    (define classify (n)
        (if (n == 0)
            "zero"
            (if (n > 0)
                "positive"
                "negative")))

    (is (classify  0)  "zero"     "... classify 0 = zero")
    (is (classify  5)  "positive" "... classify 5 = positive")
    (is (classify -3)  "negative" "... classify -3 = negative")

    (diag "operative semantics: the dead branch is never evaluated")
    (ok (if true  true  (1 / 0)) "... true  condition: else (1/0) never evaluated")
    (ok (if false (1 / 0) true)  "... false condition: then (1/0) never evaluated")

    (diag "truthy and falsy values")
    (is (if 1       "yes" "no") "yes" "... 1 is truthy")
    (is (if 0       "yes" "no") "no"  "... 0 is falsy")
    (is (if "hello" "yes" "no") "yes" "... non-empty string is truthy")
    (is (if ""      "yes" "no") "no"  "... empty string is falsy")
    (is (if ()      "yes" "no") "no"  "... nil is falsy")

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
