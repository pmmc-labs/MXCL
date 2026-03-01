#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[

    (diag "eq? predicate tests")
    (ok (eq? 1 1)           "... equal numbers")
    (ok (not (eq? 1 2))     "... unequal numbers")
    (ok (eq? "foo" "foo")   "... equal strings")
    (ok (not (eq? "foo" "bar")) "... unequal strings")
    (ok (eq? true true)     "... equal bools")
    (ok (not (eq? true false)) "... unequal bools")
    (ok (eq? () ())         "... nil equals nil")

    (diag "bool? predicate tests")
    (ok (bool? true)        "... true is bool")
    (ok (bool? false)       "... false is bool")
    (ok (not (bool? 1))     "... number is not bool")
    (ok (not (bool? "true")) "... string is not bool")

    (diag "num? predicate tests")
    (ok (num? 42)           "... integer is num")
    (ok (num? 3.14)         "... float is num")
    (ok (num? -10)          "... negative is num")
    (ok (not (num? "42"))   "... string is not num")
    (ok (not (num? true))   "... bool is not num")

    (diag "str? predicate tests")
    (ok (str? "hello")      "... string is str")
    (ok (str? "")           "... empty string is str")
    (ok (not (str? 42))     "... number is not str")
    (ok (not (str? true))   "... bool is not str")

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



