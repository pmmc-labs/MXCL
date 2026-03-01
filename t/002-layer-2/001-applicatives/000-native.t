#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "eq? returns true for structurally identical terms")
    (ok (eq? 1 1)            "... eq? Num same literal")
    (ok (eq? "a" "a")        "... eq? Str same literal")
    (ok (eq? true true)      "... eq? Bool true")
    (ok (eq? false false)    "... eq? Bool false")

    (ok (not (eq? 1 2))      "... not eq? different Nums")
    (ok (not (eq? "a" "b"))  "... not eq? different Strs")
    (ok (not (eq? true false)) "... not eq? true/false")
    (ok (eq? () ())            "... nil equals nil")

    (diag "not")
    (ok (not false)  "... not false => true")
    (ok (not (not true)) "... not not true => true")

    (is (not false) true  "... not false returns Bool true")
    (is (not true)  false "... not true returns Bool false")

    (diag "type predicates: positive cases")
    (ok (nil?    ())          "... nil? ()")
    (ok (bool?   true)        "... bool? true")
    (ok (bool?   false)       "... bool? false")
    (ok (num?    42)          "... num? 42")
    (ok (num?    0)           "... num? 0")
    (ok (num?    3.14)        "... num? float")
    (ok (num?    -10)         "... num? negative")
    (ok (str?    "hello")     "... str? hello")
    (ok (str?    "")          "... str? empty string")
    (ok (lambda? (lambda (x) x)) "... lambda? lambda")

    (diag "type predicates: negative cases")
    (ok (not (nil?  false))   "... not nil? false")
    (ok (not (bool? 0))       "... not bool? 0")
    (ok (not (bool? "true"))  "... not bool? string")
    (ok (not (num?  "42"))    "... not num? string")
    (ok (not (str?  42))      "... not str? num")
    (ok (not (str?  true))    "... not str? bool")

    (diag "define produces a Lambda")
    (define f (x) x)
    (ok (lambda? f) "... define f: f is bound to a Lambda term")

    (diag "let + lambda produces a Lambda")
    (let g (lambda (x) x))
    (ok (lambda? g) "... let + lambda: g is bound to a Lambda term")

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
