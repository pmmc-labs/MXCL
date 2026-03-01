#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# while: operative that re-evaluates its condition each iteration and runs
# body until the condition becomes false. Mutable state is via Ref.

# --- basic countdown: ref reaches zero ---

test_mxcl(q[
    (let x (make-ref 10))
    (while ((x .get) > 0)
        (x .set! ((x .get) - 1)))
    (is (x .get) 0 "... countdown from 10 reaches 0")
]);

# --- never executes body when condition is initially false ---

test_mxcl(q[
    (let touched (make-ref 0))
    (while false
        (touched .set! 1))
    (is (touched .get) 0 "... while false: body never executes")
]);

# --- body runs exactly n times ---

test_mxcl(q[
    (let n     (make-ref 5))
    (let count (make-ref 0))
    (while ((n .get) > 0)
        (do
            (count .set! ((count .get) + 1))
            (n .set! ((n .get) - 1))))
    (is (count .get) 5 "... body runs exactly 5 times")
]);

# --- accumulate sum via while (mirrors tester.pl example) ---

test_mxcl(q[
    (let i   (make-ref 1))
    (let sum (make-ref 0))
    (while ((i .get) <= 4)
        (do
            (sum .set! ((sum .get) + (i .get)))
            (i   .set! ((i .get) + 1))))
    (is (sum .get) 10 "... while summing 1..4 = 10")
]);

# --- condition references accumulating state ---

test_mxcl(q[
    (let x (make-ref 1))
    (while ((x .get) < 100)
        (x .set! ((x .get) * 2)))
    (ok ((x .get) >= 100) "... x doubled until >= 100")
]);

done_testing;
