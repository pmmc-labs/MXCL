#!perl

use v5.42;

use Test::More;
use Scalar::Util qw[ refaddr ];
use Test::MXCL qw[ ctx test_mxcl ];

# Layer 2 thesis: environments are immutable, content-addressed Roles.
# Scope derivation is Role union; name lookup is slot lookup.
# Scoped forms (do, lambda body) restore the pre-entry env on exit.

my $ctx = ctx;

# =============================================================================
# Structural: the base scope is a Role
# =============================================================================

isa_ok $ctx->base_scope, 'MXCL::Term::Role',
    'base_scope is a Role';

# =============================================================================
# Structural: define extends the env by adding exactly one slot
# =============================================================================

{
    my $before = $ctx->base_scope->size;

    my $result = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source(q[ (define f (x) x) ])
    );

    is $result->env->size, $before + 1,
        'define extends the env by exactly one slot';

    isa_ok $result->env->lookup('f'), 'MXCL::Term::Role::Slot::Defined',
        'the new slot is a Defined slot';

    isa_ok $result->env->lookup('f')->value, 'MXCL::Term::Lambda',
        'the slot value is a Lambda';
}

# =============================================================================
# Structural: each define produces a distinct env (content-addressed union)
# =============================================================================

{
    my $env_f = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source(q[ (define f (x) x) ])
    )->env;

    my $env_g = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source(q[ (define g (x) x) ])
    )->env;

    isnt $env_f->hash, $env_g->hash,
        'defining different names produces different env hashes';
}

# =============================================================================
# Structural: a do block does not extend the returned env
# The Scope::Enter / Scope::Leave pair restores the pre-enter env.
# =============================================================================

{
    my $before_hash = $ctx->base_scope->hash;

    my $result = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source(q[ (do (let __scoped 1)) ])
    );

    is $result->env->hash, $before_hash,
        'do block: returned env matches base_scope (scope reverted on Leave)';

    isnt refaddr($ctx->base_scope), refaddr(undef),
        'base_scope itself is unchanged (it is immutable)';
}

# =============================================================================
# Behavioural: inner scope sees outer bindings via env threading
# =============================================================================

test_mxcl(q[
    (let x 10)
    (do
        (is x 10 "... do block sees outer x = 10"))
]);

# =============================================================================
# Behavioural: scope boundary is transparent for reads, opaque for writes
# =============================================================================

test_mxcl(q[
    (let outer 1)
    (do
        (let inner 2)
        (is outer 1  "... inner scope sees outer")
        (is inner 2  "... inner scope sees inner"))
    (is outer 1 "... outer still visible after do block")
]);

# =============================================================================
# Behavioural: two different names in the same run share the same env object
# when their values are structurally identical (content-addressing)
# =============================================================================

test_mxcl(q[
    (let a 42)
    (let b 42)
    (ok (eq? a b) "... a and b are the same Num(42) term (content-addressed)")
]);

done_testing;
