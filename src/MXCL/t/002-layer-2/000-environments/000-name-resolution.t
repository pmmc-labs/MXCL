#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- self-evaluating literals ---

test_mxcl(q[
    (is 42      42      "... Num literal self-evaluates")
    (is 3.14    3.14    "... Num float self-evaluates")
    (is "hello" "hello" "... Str literal self-evaluates")
    (is true    true    "... Bool true self-evaluates")
    (is false   false   "... Bool false self-evaluates")
]);

# --- let binds a name; the name resolves to the bound value ---

test_mxcl(q[
    (let x 42)
    (is x 42 "... x resolves to 42")

    (let greeting "hello")
    (is greeting "hello" "... greeting resolves to bound string")

    (let flag true)
    (is flag true "... flag resolves to true")

    (let zero 0)
    (is zero 0 "... zero resolves to 0")
]);

# --- multiple bindings are independent; later lets do not shadow earlier ones ---

test_mxcl(q[
    (let a 1)
    (let b 2)
    (let c 3)

    (is a 1 "... a resolves to 1 after b and c are bound")
    (is b 2 "... b resolves to 2 after c is bound")
    (is c 3 "... c resolves to 3")
]);

# --- structural identity: two lets with the same literal share a term ---

test_mxcl(q[
    (let p 10)
    (let q 10)

    (ok (eq? p q) "... p and q share the same Num(10) term (content-addressed)")
    (ok (eq? p 10) "... p and the literal 10 are the same term")
]);

done_testing;
