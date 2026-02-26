#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ ctx test_mxcl ];

# Layer 2 thesis: every callable is either an Applicative (args evaluated before
# the call) or an Operative (args are raw unevaluated AST).  There is no third
# kind.  This file demonstrates the duality both structurally (via Perl-level
# type inspection) and behaviourally (via observable MXCL execution).

# =============================================================================
# Structural: inspect the base scope
# =============================================================================

my $ctx   = ctx;
my $scope = $ctx->base_scope;

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
    my $result = $ctx->evaluate(
        $scope,
        $ctx->compile_source(q[ (define f (x) x) ])
    );

    isa_ok $result->env->lookup('f')->value, 'MXCL::Term::Lambda',
        'define inserts a Lambda into the env';
}

# --- let + lambda also produces a Lambda in the env ---
# let now evaluates its value, so the Lambda term is what gets bound.

{
    my $result = $ctx->evaluate(
        $scope,
        $ctx->compile_source(q[ (let g (lambda (x) x)) ])
    );

    isa_ok $result->env->lookup('g')->value, 'MXCL::Term::Lambda',
        'let + lambda: g is bound to a Lambda term';
}

done_testing;
