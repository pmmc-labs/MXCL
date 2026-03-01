#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Array .foreach: calls f on each element for side effects, returns nil.
# We observe effects by accumulating into a Ref.

# --- basic accumulation ---

test_mxcl(q[
    (let sum (make-ref 0))
    (+[1 2 3] .foreach (-> (x)
        (sum .set! ((sum .get) + x))))
    (is (sum .get) 6 "... foreach accumulates sum 1+2+3 = 6")
]);

# --- all elements visited ---

test_mxcl(q[
    (let count (make-ref 0))
    (+[10 20 30 40 50] .foreach (-> (x)
        (count .set! ((count .get) + 1))))
    (is (count .get) 5 "... foreach visits all 5 elements")
]);

# --- foreach on empty array does nothing ---

test_mxcl(q[
    (let touched (make-ref 0))
    (+[] .foreach (-> (x)
        (touched .set! 1)))
    (is (touched .get) 0 "... foreach on +[] never calls f")
]);

# --- foreach on single element ---

test_mxcl(q[
    (let seen (make-ref 0))
    (+[42] .foreach (-> (x)
        (seen .set! x)))
    (is (seen .get) 42 "... foreach on single element visits it")
]);

# --- foreach visits in order (track last seen) ---

test_mxcl(q[
    (let last (make-ref 0))
    (+[1 2 3] .foreach (-> (x)
        (last .set! x)))
    (is (last .get) 3 "... foreach visits in order, last = 3")
]);

done_testing;
