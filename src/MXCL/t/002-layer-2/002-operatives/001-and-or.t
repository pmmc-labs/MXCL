#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# --- and: all four combinations ---

test_mxcl(q[
    (ok      (and true  true)  "... true  and true  => true")
    (ok (not (and true  false)) "... true  and false => false")
    (ok (not (and false true))  "... false and true  => false (short-circuit)")
    (ok (not (and false false)) "... false and false => false")
]);

# --- and: short-circuit means the rhs is not evaluated when lhs is false ---

test_mxcl(q[
    (ok (not (and false (1 / 0))) "... false and <dead> => false; rhs never evaluated")
]);

# --- and: returns a truthy/falsy value, not just Bool ---

test_mxcl(q[
    (is (and true  true)  true  "... true and true returns true")
    (is (and true  false) false "... true and false returns false")
    (is (and false false) false "... false and false returns false")
]);

# --- or: all four combinations ---

test_mxcl(q[
    (ok      (or true  true)  "... true  or true  => true")
    (ok      (or true  false) "... true  or false => true  (short-circuit)")
    (ok      (or false true)  "... false or true  => true")
    (ok (not (or false false)) "... false or false => false")
]);

# --- or: short-circuit means the rhs is not evaluated when lhs is true ---

test_mxcl(q[
    (ok (or true (1 / 0)) "... true or <dead> => true; rhs never evaluated")
]);

# --- or: returns a truthy/falsy value ---

test_mxcl(q[
    (is (or true  false) true  "... true or false returns true")
    (is (or false true)  true  "... false or true returns true")
    (is (or false false) false "... false or false returns false")
]);

done_testing;
