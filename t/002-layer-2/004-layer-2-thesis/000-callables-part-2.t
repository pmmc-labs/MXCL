#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ ctx test_mxcl ];

# Layer 2 thesis: every callable is either an Applicative (args evaluated before
# the call) or an Operative (args are raw unevaluated AST).  There is no third
# kind.  This file demonstrates the duality both structurally (via Perl-level
# type inspection) and behaviourally (via observable MXCL execution).

# --- lambda? confirms both paths at the MXCL level ---

test_mxcl(q[
    (ok (lambda? (lambda (x) x))         "... lambda expression produces a Lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... multi-arg lambda is also a Lambda term")
    (let h (lambda (x) x))
    (ok (lambda? h) "... let-bound lambda is a Lambda term")
]);

# =============================================================================
# Behavioural: applicatives pre-evaluate; operatives do not
# =============================================================================

# --- applicative: the arg expression is evaluated before the body sees it ---
# (define square (x) (x * x)) applied to (2 + 3):
# the arg is first reduced to 5, then square receives 5 and returns 25.

test_mxcl(q[
    (define square (x) (x * x))
    (is (square (2 + 3)) 25 "... applicative: arg (2+3) evaluated to 5 before call")
]);

# --- operative: the dead branch is never evaluated ---
# if is an operative; it picks one branch and discards the other as raw AST.
# (1 / 0) would raise a Perl exception if the runtime ever tried to evaluate it.

test_mxcl(q[
    (ok (if true  true  (1 / 0)) "... operative if: false-branch (1/0) never evaluated")
    (ok (if false (1 / 0) true)  "... operative if: true-branch  (1/0) never evaluated")
]);

# --- operative short-circuit: and and or also skip evaluation ---

test_mxcl(q[
    (ok      (and true  true)       "... and true  true  => true")
    (ok (not (and false (1 / 0)))   "... operative and: rhs (1/0) not evaluated when lhs is false")
    (ok      (or  true  (1 / 0))    "... operative or:  rhs (1/0) not evaluated when lhs is true")
]);

done_testing;
