# Layer 1: Role Substrate -- Test Suite

## What Layer 1 Is

Layer 1 defines a composition algebra over **slots** and **roles**. It answers
the question: **How do named bindings combine?**

A **slot** is the atomic unit -- a name paired with one of three states:
Required (abstract declaration), Defined (concrete implementation), or Conflict
(two incompatible Defined values recorded without discarding either). A **role**
is a finite map from names to slots.

The central operation is **composition**: merging two roles pointwise by name.
Composition is total (it never fails), pure (it discards nothing), and defers
all policy decisions to a separate resolution phase. This makes it suitable for
two distinct purposes -- role/class composition and lexical scope construction
-- using the same underlying algebra with different resolution policies.

Three properties distinguish this algebra:

- **Required is the identity element** -- composing anything with a Required
  slot leaves the other slot unchanged. Required is a declaration of need, not
  a value.

- **Conflicts accumulate, not resolve** -- when two Defined slots with
  different content hashes meet, the result is a Conflict node that preserves
  both children. Further composition wraps deeper; nothing is ever silently
  discarded.

- **Order-independent role hashing** -- role identity is based on slot content,
  not construction order. Two roles with the same slots in any order have the
  same hash and are the same Arena object.

## What This Suite Proves

The validation criterion for Layer 1:

> Role composition is total, content-addressed, and order-independent.
> Required is the identity element. Conflicts accumulate structurally.
> Identical content never conflicts, regardless of origin.

The tests verify this from the slot level up through the full algebraic laws.

## Test Organization

```
t/001-layer-1/
    000-slots/              The three slot variants (Required, Defined, Conflict)
    001-slot-composition/   The 3x3 slot composition table
    001-basic.t             Order-independent hashing of real Runtime roles
    002-role-composition/   Role-level composition scenarios
    003-layer-1-thesis/     Algebraic law proofs (commutativity, associativity, idempotency)
```

### 000-slots/ -- Slot Types

The three slot variants are the atomic elements of the algebra. These tests
verify type hierarchy, accessor correctness, content-addressing, and the
structural invariants of each variant.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-required.t` | 7 | Type hierarchy, ident accessor, hash, interning, eq |
| `001-defined.t` | 12 | Type hierarchy, ident/value accessors, hash, interning, eq, multiple value types |
| `002-conflict.t` | 25 | Type hierarchy, lhs/rhs accessors, ident-from-lhs, hash, order-matters-for-hash, invariant check (mismatched idents die), nested conflicts |

### 001-slot-composition/ -- Slot Composition Table

The composition function `MergeSlot(s1, s2)` is defined by a 3x3 table.
These tests verify every cell of that table at the slot level.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-compose-table.t` | 5 | S1-S5: Required+Required, Required+Defined, Defined+Required, Defined+Defined (same hash), Defined+Defined (different hash) |
| `001-conflict-rows.t` | 5 | S6-S10: Required+Conflict (identity), Conflict+Required (identity), Defined+Conflict (wraps), Conflict+Defined (wraps), Conflict+Conflict (wraps) |

### 001-basic.t -- Order-Independent Hashing (Real Roles)

An integration test using the real `EQ`, `ORD`, `NUM`, and `STR` roles from
the Runtime. Verifies that `Union`, `Intersection`, `SymmetricDifference`, and
`AsymmetricDifference` all produce hash-identical results regardless of
argument order, and that nested compositions (`NUM + (ORD + EQ)` vs
`ORD + (EQ + NUM)`) hash identically.

| File | Tests | What It Covers |
|------|-------|----------------|
| `001-basic.t` | 16 | Order-independent hash for all four set operations; associativity of union over Runtime roles |

### 002-role-composition/ -- Role Composition Scenarios

Role-level tests using abstract fixture roles (RA, RB, RC, RD, etc.) drawn
directly from `docs/ROLE-TEST.md`. Each test verifies the size of the composed
role, the type of each slot, and where relevant the exact lhs/rhs structure
of Conflict nodes.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-disjoint.t` | 4 | R1-R2: No-overlap merge; empty role as left and right identity |
| `001-requirements.t` | 6 | R3-R8: Req satisfaction, Req propagation, multiple Reqs, mutual satisfaction, Req meets Conflict (identity) |
| `002-conflicts.t` | 5 | R9-R13: Simple conflict; same-hash non-conflict; mixed; two conflicts; total conflict (four roles) |
| `003-diamond.t` | 4 | R19-R22: Classic diamond (same hash, no conflict); one override; both override differently; convergent override (same hash, no conflict) |

### 003-layer-1-thesis/ -- Layer 1 Thesis

Integration tests that prove the algebraic laws hold across the full
composition pipeline.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-algebraic.t` | 5 | R14-R18: Commutativity (different hash, same leaves); associativity (same structure); associativity (divergent tree shapes); idempotency; idempotency with Requirements |
| `001-absorption.t` | 7 | R23-R29: Conflict survives empty; third provider deepens conflict; Con+Con; Req met by idempotent providers; Req meets conflict (not satisfied); Req satisfied alongside conflict; clean requirement satisfaction |

## Running the Tests

```bash
# Run the full Layer 1 suite
prove -lrv t/001-layer-1/

# Run a single subdirectory
prove -lrv t/001-layer-1/002-role-composition/

# Run a single file
prove -lv t/001-layer-1/001-slot-composition/001-conflict-rows.t
```

Requires Perl v5.42+ with `use experimental qw[ class ]`.

## Shared Utilities

Tests use `lib/Test/MXCL.pm`, which provides lazy-initialized accessors
for a shared `MXCL::Context` and its subsystems:

```perl
use Test::MXCL qw[ terms roles ];
```

The shared context is safe because terms and roles are immutable and
interned -- no test pollution between files.

## Reference Documents

- `docs/SLOTS.md` -- Formal specification of the slot composition algebra
- `docs/ROLE-TEST.md` -- The complete test fixture definitions (fixture roles,
  expected outputs for R1-R34) that the role composition tests are drawn from

## What Is Not Tested Here

- **R30-R34 (Resolution)** -- Class-level resolution (overrides, conflict
  resolution, finalization) is deferred; `docs/LAYERS.md` marks this WIP.
- **Scope usage** -- Roles-as-Scope (the Machine's `Define` and `Union`
  for name binding) is exercised by the execution layer, not here.
- **Set algebra operations** -- `Difference`, `Intersection`,
  `SymmetricDifference`, `AsymmetricDifference` are tested in `001-basic.t`
  for the order-independence property but not exhaustively for all combinations.
