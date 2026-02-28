#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Ref: mutable cell created with make-ref, accessed with .get and mutated with .set!

# --- .get on initial value ---

test_mxcl(q[
    (let r (make-ref 42))
    (is (r .get) 42 "... ref.get returns initial value")
]);

test_mxcl(q[
    (let r (make-ref "hello"))
    (is (r .get) "hello" "... ref.get works for strings")
]);

# --- .set! then .get ---

test_mxcl(q[
    (let r (make-ref 0))
    (r .set! 99)
    (is (r .get) 99 "... ref.get returns updated value after set!")
]);

# --- multiple mutations ---

test_mxcl(q[
    (let r (make-ref 1))
    (r .set! 2)
    (r .set! 3)
    (is (r .get) 3 "... ref.get returns last value after multiple set!")
]);

# --- ref used as counter (as in the Test::Builder role) ---

test_mxcl(q[
    (let count (make-ref 0))
    (count .set! ((count .get) + 1))
    (count .set! ((count .get) + 1))
    (count .set! ((count .get) + 1))
    (is (count .get) 3 "... ref used as counter reaches 3")
]);

done_testing;
