#!perl

use v5.42;

use Test::More;
use Scalar::Util qw[ refaddr ];
use Test::MXCL qw[ ctx test_mxcl ];

# Layer 2 thesis: environments are immutable, content-addressed Roles.
# Scope derivation is Role union; name lookup is slot lookup.
# Scoped forms (do, lambda body) restore the pre-entry env on exit.

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
