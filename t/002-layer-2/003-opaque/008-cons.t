#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Cons cells: built with `cons`, destructured with `head` and `tail`.
# The Cons role also provides .eval for evaluating a quoted list as an expression.

# --- cons / head / tail (pair) ---

test_mxcl(q[
    (let c (cons 1 2))
    (is (head c) 1 "... head of (cons 1 2) = 1")
    (is (tail c) 2 "... tail of (cons 1 2) = 2")
]);

test_mxcl(q[
    (let c (cons "hello" "world"))
    (is (head c) "hello" "... head of string cons = hello")
    (is (tail c) "world" "... tail of string cons = world")
]);

# --- proper list from split (cons cells terminated by nil) ---

test_mxcl(q[
    (let lst ("a,b,c" .split ","))
    (is (head lst)               "a" "... head of list = a")
    (is (head (tail lst))        "b" "... second element = b")
    (is (head (tail (tail lst))) "c" "... third element = c")
    (ok (nil? (tail (tail (tail lst)))) "... tail of last element is nil")
]);

# --- single-element list has nil tail ---

test_mxcl(q[
    (let lst ("x" .split ","))
    (is (head lst)        "x" "... single element = x")
    (ok (nil? (tail lst)) "... tail of single-element list is nil")
]);

# --- .eval: evaluates a quoted cons list as an expression ---

test_mxcl(q[
    (let expr '(1 + 2))
    (is (expr .eval) 3 "... (eval '(1 + 2)) = 3")
]);

test_mxcl(q[
    (let expr '(not true))
    (ok (not (expr .eval)) "... (eval '(not true)) = false")
]);

done_testing;
