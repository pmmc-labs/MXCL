#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- eq? returns true for structurally identical terms ---
# Because all terms are content-addressed, structural identity == object identity.

test_mxcl(q[
    (ok (eq? 1 1)            "... eq? Num same literal")
    (ok (eq? "a" "a")        "... eq? Str same literal")
    (ok (eq? true true)      "... eq? Bool true")
    (ok (eq? false false)    "... eq? Bool false")

    (ok (not (eq? 1 2))      "... not eq? different Nums")
    (ok (not (eq? "a" "b"))  "... not eq? different Strs")
    (ok (not (eq? true false)) "... not eq? true/false")
]);

# --- not ---

test_mxcl(q[
    (ok (not false)  "... not false => true")
    (ok (not (not true)) "... not not true => true")

    (is (not false) true  "... not false returns Bool true")
    (is (not true)  false "... not true returns Bool false")
]);

# --- type predicates: positive cases ---

test_mxcl(q[
    (ok (nil?    ())          "... nil? ()")
    (ok (bool?   true)        "... bool? true")
    (ok (bool?   false)       "... bool? false")
    (ok (num?    42)          "... num? 42")
    (ok (num?    0)           "... num? 0")
    (ok (str?    "hello")     "... str? hello")
    (ok (str?    "")          "... str? empty string")
    (ok (lambda? (lambda (x) x)) "... lambda? lambda")
]);

# --- type predicates: negative cases ---

test_mxcl(q[
    (ok (not (nil?  false))   "... not nil? false")
    (ok (not (bool? 0))       "... not bool? 0")
    (ok (not (bool? "true"))  "... not bool? string")
    (ok (not (num?  "42"))    "... not num? string")
    (ok (not (str?  42))      "... not str? num")
    (ok (not (str?  true))    "... not str? bool")
]);

done_testing;
