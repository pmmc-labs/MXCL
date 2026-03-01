#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[

    (diag "if with boolean conditions")
    (is (if true 1 2)       1       "... if true returns then-branch")
    (is (if false 1 2)      2       "... if false returns else-branch")

    (diag "if with truthy/falsy values")
    (is (if 1 "yes" "no")       "yes"   "... 1 is truthy")
    (is (if 0 "yes" "no")       "no"    "... 0 is falsy")
    (is (if "hello" "yes" "no") "yes"   "... non-empty string is truthy")
    (is (if "" "yes" "no")      "no"    "... empty string is falsy")
    (is (if () "yes" "no")      "no"    "... nil is falsy")

    (diag "if with computed conditions")
    (is (if (5 > 3) "bigger" "smaller") "bigger" "... 5 > 3")
    (is (if (5 < 3) "bigger" "smaller") "smaller" "... not 5 < 3")
    (is (if (2 == 2) "equal" "different") "equal" "... 2 == 2")

    (diag "if with expressions in branches")
    (is (if true (1 + 2) (3 + 4))   3   "... evaluates then-expr")
    (is (if false (1 + 2) (3 + 4))  7   "... evaluates else-expr")

    (diag "Nested if expressions")
    (is (if true (if true 1 2) 3)   1   "... nested if, both true")
    (is (if true (if false 1 2) 3)  2   "... nested if, outer true inner false")
    (is (if false 1 (if true 2 3))  2   "... nested in else branch")

    (diag "do block tests")
    (is (do 1 2 3)                  3   "... do returns last value")
    (is (do (1 + 1) (2 + 2) (3 + 3)) 6  "... do evaluates all, returns last")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result  = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}

