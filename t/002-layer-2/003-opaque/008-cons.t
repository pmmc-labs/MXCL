#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Cons cells: built with `cons`, destructured with `head` and `tail`.
# The Cons role also provides .eval for evaluating a quoted list as an expression.

my $source = q[
    (diag "cons / head / tail (pair)")
    (let c (cons 1 2))
    (is (head c) 1 "... head of (cons 1 2) = 1")
    (is (tail c) 2 "... tail of (cons 1 2) = 2")

    (let c2 (cons "hello" "world"))
    (is (head c2) "hello" "... head of string cons = hello")
    (is (tail c2) "world" "... tail of string cons = world")

    (diag "proper list from split (cons cells terminated by nil)")
    (let lst ("a,b,c" .split ","))
    (is (head lst)               "a" "... head of list = a")
    (is (head (tail lst))        "b" "... second element = b")
    (is (head (tail (tail lst))) "c" "... third element = c")
    (ok (nil? (tail (tail (tail lst)))) "... tail of last element is nil")

    (diag "single-element list has nil tail")
    (let lst2 ("x" .split ","))
    (is (head lst2)        "x" "... single element = x")
    (ok (nil? (tail lst2)) "... tail of single-element list is nil")

    (diag ".eval: evaluates a quoted cons list as an expression")
    (let expr '(1 + 2))
    (is (expr .eval) 3 "... (eval '(1 + 2)) = 3")

    (let expr2 '(not true))
    (ok (not (expr2 .eval)) "... (eval '(not true)) = false")

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
