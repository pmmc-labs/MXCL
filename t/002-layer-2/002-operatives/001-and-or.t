#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "and: all four combinations")
    (ok      (and true  true)  "... true  and true  => true")
    (ok (not (and true  false)) "... true  and false => false")
    (ok (not (and false true))  "... false and true  => false (short-circuit)")
    (ok (not (and false false)) "... false and false => false")

    (diag "and: short-circuit means the rhs is not evaluated when lhs is false")
    (ok (not (and false (1 / 0))) "... false and <dead> => false; rhs never evaluated")

    (diag "and: returns a truthy/falsy value, not just Bool")
    (is (and true  true)  true  "... true and true returns true")
    (is (and true  false) false "... true and false returns false")
    (is (and false false) false "... false and false returns false")

    (diag "or: all four combinations")
    (ok      (or true  true)  "... true  or true  => true")
    (ok      (or true  false) "... true  or false => true  (short-circuit)")
    (ok      (or false true)  "... false or true  => true")
    (ok (not (or false false)) "... false or false => false")

    (diag "or: short-circuit means the rhs is not evaluated when lhs is true")
    (ok (or true (1 / 0)) "... true or <dead> => true; rhs never evaluated")

    (diag "or: returns a truthy/falsy value")
    (is (or true  false) true  "... true or false returns true")
    (is (or false true)  true  "... false or true returns true")
    (is (or false false) false "... false or false returns false")

    (diag "not operator")
    (ok (not false)      "... not false = true")
    (ok (not (not true)) "... not not true = true")
    (ok (not ())         "... not nil = true")
    (ok (not 0)          "... not 0 = true")
    (ok (not "")         "... not '' = true")

    (diag "and and or: value return (short-circuit values)")
    (is (and true 42)   42  "... true and 42 returns 42")
    (is (or false 42)   42  "... false or 42 returns 42")
    (is (or 1 2)        1   "... 1 or 2 returns 1 (short-circuit)")

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
