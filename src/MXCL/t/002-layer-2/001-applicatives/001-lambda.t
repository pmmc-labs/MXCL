#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Note: `let` is an operative - it binds the *unevaluated* form, so
# `(let f (lambda (x) x))` binds f to the raw AST Cons, not a Lambda term.
# To create named callables, use `define`.  Anonymous lambdas are tested
# by passing them directly to applicatives (which evaluate their arguments).

# --- lambda expression produces a Lambda term ---
# lambda? is an applicative: its argument (lambda (x) x) is evaluated first,
# producing a Lambda term; then lambda? checks the type.

test_mxcl(q[
    (ok (lambda? (lambda (x) x))       "... anonymous lambda is a lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... two-arg lambda is a lambda term")
]);

# --- basic lambda application via define ---

test_mxcl(q[
    (define double (x) (x + x))
    (is (double 0)  0  "... double 0 = 0")
    (is (double 5) 10  "... double 5 = 10")
    (is (double 7) 14  "... double 7 = 14")
]);

# --- applicative semantics: arguments are evaluated before the body runs ---
# The arg (2 + 3) evaluates to 5 before double receives it.

test_mxcl(q[
    (define double (x) (x + x))
    (is (double (2 + 3))  10 "... arg (2+3) evaluated to 5 before call; double 5 = 10")
    (is (double (10 - 4)) 12 "... arg (10-4) evaluated to 6 before call; double 6 = 12")
]);

# --- multi-arg lambda ---

test_mxcl(q[
    (define add (x y) (x + y))
    (is (add 3 4)   7  "... add 3 4 = 7")
    (is (add 0 99) 99  "... add 0 99 = 99")
    (is (add 10 10) 20 "... add 10 10 = 20")
]);

# --- closure: define captures the defining environment ---

test_mxcl(q[
    (let base 100)
    (define add-base (x) (x + base))

    (is (add-base 5)   105 "... closure captures base = 100; add-base 5 = 105")
    (is (add-base 42)  142 "... same closure, different arg; add-base 42 = 142")
    (is (add-base 0)   100 "... add-base 0 = 100")
]);

# --- lambda as a value: a defined function can be passed to another ---

test_mxcl(q[
    (define apply-twice (f x) (f (f x)))
    (define inc (n) (n + 1))

    (is (apply-twice inc 0) 2  "... apply-twice inc 0 = 2")
    (is (apply-twice inc 5) 7  "... apply-twice inc 5 = 7")
]);

done_testing;
