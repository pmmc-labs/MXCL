#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ctx ];

# --- inner scope can see bindings from the outer scope ---

test_mxcl(q[
    (let x 1)
    (do
        (is x 1 "... inner scope sees outer x = 1"))
]);

# --- bindings made inside a do block are visible to later exprs in the same block ---

test_mxcl(q[
    (do
        (let y 99)
        (is y 99 "... y visible to later exprs within the same do block"))
]);

# --- multiple nested do blocks each see their parent scope ---

test_mxcl(q[
    (let outer 10)
    (do
        (let mid 20)
        (do
            (is outer 10 "... inner-inner sees outer = 10")
            (is mid   20 "... inner-inner sees mid = 20")))
]);

# --- Perl level: top-level let extends the threading env ---
# A let at the top level (not inside a do) propagates up to the returned env.

{
    my $ctx = ctx;

    my $result = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source('(let __top 1)')
    );

    isnt $result->env->hash, $ctx->base_scope->hash,
        'top-level let: returned env is extended beyond base_scope';
}

# --- Perl level: let inside a do block does not escape the scope boundary ---
# The do operative wraps its body in Scope::Enter / Scope::Leave.
# When Leave fires it restores the pre-Enter env, so any defines made
# inside do never propagate to the returned Host continuation.

{
    my $ctx = ctx;

    my $result = $ctx->evaluate(
        $ctx->base_scope,
        $ctx->compile_source('(do (let __inner 1))')
    );

    is $result->env->hash, $ctx->base_scope->hash,
        'do-scoped let: returned env equals base_scope (scope boundary reverted)';
}

done_testing;
