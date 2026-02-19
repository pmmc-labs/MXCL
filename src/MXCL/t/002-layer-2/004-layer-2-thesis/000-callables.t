#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ runtime test_mxcl ];

# Layer 2 thesis: every callable is either an Applicative (args evaluated before
# the call) or an Operative (args are raw unevaluated AST).  There is no third
# kind.  This file demonstrates the duality both structurally (via Perl-level
# type inspection) and behaviourally (via observable MXCL execution).

# =============================================================================
# Structural: inspect the base scope
# =============================================================================

my $r     = runtime;
my $scope = $r->base_scope;

# --- known operatives in the base scope ---

for my $name (qw[ if define let lambda do while and or ]) {
    my $slot = $scope->lookup($name);
    isa_ok $slot->value, 'MXCL::Term::Native::Operative',
        "\"$name\" in base_scope is a NativeOperative";
}

# --- known applicatives in the base scope ---

for my $name (qw[ eq? not nil? bool? num? str? lambda? sym? ]) {
    my $slot = $scope->lookup($name);
    isa_ok $slot->value, 'MXCL::Term::Native::Applicative',
        "\"$name\" in base_scope is a NativeApplicative";
}

# --- define produces a Lambda ---
# define is an operative that constructs a Lambda and installs it in the env.

{
    my $ctx = $r->context;
    my $result = $ctx->evaluate(
        $scope,
        $ctx->compile_source(q[ (define f (x) x) ])
    );

    isa_ok $result->env->lookup('f')->value, 'MXCL::Term::Lambda',
        'define inserts a Lambda into the env';
}

# --- lambda (operative) also produces a Lambda ---
# lambda? is an applicative so its argument (lambda ...) is fully evaluated
# before the predicate receives it - yielding the Lambda term directly.

test_mxcl(q[
    (ok (lambda? (lambda (x) x))         "... lambda expression produces a Lambda term")
    (ok (lambda? (lambda (x y) (x + y))) "... multi-arg lambda is also a Lambda term")
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
