#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- do sequences expressions; later exprs see names bound by earlier ones ---

test_mxcl(q[
    (do
        (let a 1)
        (let b 2)
        (is a 1 "... a visible to later exprs in do block")
        (is b 2 "... b visible to later exprs in do block"))
]);

# --- a function defined inside do is callable within the same do block ---

test_mxcl(q[
    (do
        (define square (x) (x * x))
        (is (square 4) 16 "... square defined and callable within do")
        (is (square 7) 49 "... square 7 = 49"))
]);

# --- nested do blocks compose correctly ---

test_mxcl(q[
    (let outer 10)
    (do
        (let mid 20)
        (do
            (let inner 30)
            (is (outer + mid)   30 "... outer + mid = 30")
            (is (mid + inner)   50 "... mid + inner = 50")
            (is (outer + inner) 40 "... outer + inner = 40")))
]);

# --- do passes the result of the last expression upward ---
# do can be used as an expression: it returns the value of its last sub-expression.
# Here do is an argument to is (an applicative), so it gets fully evaluated first.

test_mxcl(q[
    (is (do (let tmp 41) (tmp + 1)) 42
        "... do returns the value of its last expression")
]);

done_testing;
