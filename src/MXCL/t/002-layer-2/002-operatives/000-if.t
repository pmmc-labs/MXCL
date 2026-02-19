#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- true condition selects the then-branch ---

test_mxcl(q[
    (is (if true  1 2) 1 "... true  => then-branch (1)")
    (is (if false 1 2) 2 "... false => else-branch (2)")
]);

# --- condition is evaluated; branches receive the result ---

test_mxcl(q[
    (let x 5)
    (is (if (x == 5) "yes" "no") "yes" "... (x == 5) is truthy; then-branch taken")
    (is (if (x == 9) "yes" "no") "no"  "... (x == 9) is falsy; else-branch taken")
]);

# --- nested if ---

test_mxcl(q[
    (define classify (n)
        (if (n == 0)
            "zero"
            (if (n > 0)
                "positive"
                "negative")))

    (is (classify  0)  "zero"     "... classify 0 = zero")
    (is (classify  5)  "positive" "... classify 5 = positive")
    (is (classify -3)  "negative" "... classify -3 = negative")
]);

# --- operative semantics: the dead branch is never evaluated ---
# if is an operative, so it receives raw AST and only evaluates the chosen branch.
# If the dead branch were evaluated, (1 / 0) would throw a division-by-zero error.

test_mxcl(q[
    (ok (if true  true  (1 / 0)) "... true  condition: else (1/0) never evaluated")
    (ok (if false (1 / 0) true)  "... false condition: then (1/0) never evaluated")
]);

done_testing;
