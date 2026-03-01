#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "self-evaluating literals")
    (is 42      42      "... Num literal self-evaluates")
    (is 3.14    3.14    "... Num float self-evaluates")
    (is "hello" "hello" "... Str literal self-evaluates")
    (is true    true    "... Bool true self-evaluates")
    (is false   false   "... Bool false self-evaluates")

    (diag "let binds a name; the name resolves to the bound value")
    (let x 42)
    (is x 42 "... x resolves to 42")

    (let greeting "hello")
    (is greeting "hello" "... greeting resolves to bound string")

    (let flag true)
    (is flag true "... flag resolves to true")

    (let zero 0)
    (is zero 0 "... zero resolves to 0")

    (let computed (10 + 20))
    (is computed 30 "... let evaluates expression before binding")

    (diag "multiple bindings are independent; later lets do not shadow earlier ones")
    (let a 1)
    (let b 2)
    (let c 3)

    (is a 1 "... a resolves to 1 after b and c are bound")
    (is b 2 "... b resolves to 2 after c is bound")
    (is c 3 "... c resolves to 3")

    (diag "structural identity: two lets with the same literal share a term")
    (let p 10)
    (let q 10)

    (ok (eq? p q) "... p and q share the same Num(10) term (content-addressed)")
    (ok (eq? p 10) "... p and the literal 10 are the same term")

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
