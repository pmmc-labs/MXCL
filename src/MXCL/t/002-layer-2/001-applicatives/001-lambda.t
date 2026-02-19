#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- lambda produces a Lambda term ---
# lambda? is an applicative: its argument is evaluated before being checked.

test_mxcl(q[
    (ok (lambda? (lambda (x) x))         "... anonymous lambda is a lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... two-arg lambda is a lambda term")
]);

# --- let + lambda: let now evaluates its value, so the name is bound to the Lambda ---

test_mxcl(q[
    (let id (lambda (x) x))
    (ok (lambda? id) "... let-bound lambda is a lambda term")
    (is (id 42) 42   "... identity lambda returns its argument")
]);

# --- basic lambda application ---

test_mxcl(q[
    (let double (lambda (x) (x + x)))
    (is (double 0)  0  "... double 0 = 0")
    (is (double 5) 10  "... double 5 = 10")
    (is (double 7) 14  "... double 7 = 14")
]);

# --- applicative semantics: arguments are evaluated before the body runs ---

test_mxcl(q[
    (let double (lambda (x) (x + x)))
    (is (double (2 + 3))  10 "... arg (2+3) evaluated to 5 before call; double 5 = 10")
    (is (double (10 - 4)) 12 "... arg (10-4) evaluated to 6 before call; double 6 = 12")
]);

# --- multi-arg lambda ---

test_mxcl(q[
    (let add (lambda (x y) (x + y)))
    (is (add 3 4)   7  "... add 3 4 = 7")
    (is (add 0 99) 99  "... add 0 99 = 99")
    (is (add 10 10) 20 "... add 10 10 = 20")
]);

# --- closure: lambda captures its defining environment ---

test_mxcl(q[
    (let base 100)
    (let add-base (lambda (x) (x + base)))

    (is (add-base 5)   105 "... closure captures base = 100; add-base 5 = 105")
    (is (add-base 42)  142 "... same closure, different arg; add-base 42 = 142")
    (is (add-base 0)   100 "... add-base 0 = 100")
]);

# --- lambda as a value: can be passed to another lambda ---

test_mxcl(q[
    (let apply-twice (lambda (f x) (f (f x))))
    (let inc (lambda (n) (n + 1)))

    (is (apply-twice inc 0) 2  "... apply-twice inc 0 = 2")
    (is (apply-twice inc 5) 7  "... apply-twice inc 5 = 7")
]);

done_testing;
