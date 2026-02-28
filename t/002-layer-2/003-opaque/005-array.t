#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed method dispatch on Array: (array-term .method ...args)
# Arrays are constructed with +[...] syntax.

# --- construction and .length ---

test_mxcl(q[
    (let a +[1 2 3])
    (is (a .length) 3 "... +[1 2 3].length = 3")

    (let empty +[])
    (is (empty .length) 0 "... +[].length = 0")

    (let single +["x"])
    (is (single .length) 1 "... +[x].length = 1")
]);

# --- .at (zero-indexed) ---

test_mxcl(q[
    (let a +[10 20 30])
    (is (a .at 0) 10 "... at(0) = 10")
    (is (a .at 1) 20 "... at(1) = 20")
    (is (a .at 2) 30 "... at(2) = 30")
]);

# --- .reverse ---

test_mxcl(q[
    (let a  +[1 2 3])
    (let r  (a .reverse))
    (is (r .at 0) 3 "... reverse[0] = 3")
    (is (r .at 1) 2 "... reverse[1] = 2")
    (is (r .at 2) 1 "... reverse[2] = 1")
]);

# --- .push (appends a single element) ---

test_mxcl(q[
    (let a  +[1 2])
    (let a2 (a .push 3))
    (is (a2 .length) 3  "... push increases length")
    (is (a2 .at 2)   3  "... push appends element")
]);

# --- .unshift (prepends a single element) ---

test_mxcl(q[
    (let a  +[2 3])
    (let a2 (a .unshift 1))
    (is (a2 .length) 3  "... unshift increases length")
    (is (a2 .at 0)   1  "... unshift prepends element")
    (is (a2 .at 1)   2  "... unshift shifts original first")
]);

# --- .splice (offset, length) ---

test_mxcl(q[
    (let a  +[1 2 3 4 5])
    (let s  (a .splice 1 3))
    (is (s .length) 3  "... splice(1,3) returns 3 elements")
    (is (s .at 0)   2  "... splice[0] = 2")
    (is (s .at 1)   3  "... splice[1] = 3")
    (is (s .at 2)   4  "... splice[2] = 4")
]);

# --- .join ---

test_mxcl(q[
    (let a +["a" "b" "c"])
    (is (a .join ",") "a,b,c" "... array.join(,) = a,b,c")
    (is (a .join "-") "a-b-c" "... array.join(-) = a-b-c")
    (is (a .join "")  "abc"   "... array.join() = abc")
]);

done_testing;
