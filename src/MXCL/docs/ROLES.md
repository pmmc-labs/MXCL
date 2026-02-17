# Role Composition Algebra

## Specification for Slot-Based Role Composition, Resolution, and Content-Addressed Identity

---

## 1. Overview

This document describes a role composition model built on a total algebra over
slot states. The algebra is used uniformly for two purposes: composing roles
into classes/objects, and constructing lexical scopes. The key design principle
is the separation of **composition** (a pure, total operation that accumulates
structure) from **resolution** (a policy-driven phase that interprets the
accumulated structure in context).

The entire system is content-addressed via hash consing, giving us structural
sharing, immutable persistent data structures, and efficient identity
comparison throughout.

---

## 2. The Slot ADT

A **Slot** is the fundamental unit of the system. Every slot owns its external
name, and that name participates in the slot's hash identity. There are four
variants:

### 2.1 Variants

**Required(name)**

Declares that a name must be fulfilled but provides no implementation. This is
the "hole" in a role — an abstract method, or an unbound variable in a scope.

**Defined(name, value)**

Provides a concrete implementation for a name. The value may be a method body,
a variable binding, or any other payload appropriate to the context.

**Conflicted(left, right)**

Records that two slots with the same external name were composed together. Does
not carry its own name — the name is derived from its children (which are
guaranteed to share the same external name). Conflicted is recursive: its
children are themselves slots, which may include other Conflicted nodes. This
recursion produces a binary tree that naturally encodes composition history.

**Alias(name, slot)**

Re-presents an inner slot under a new external name. The inner slot retains its
original name. This is the mechanism for renaming during composition — to
resolve or avoid conflicts.

### 2.2 Name Recovery

Every slot has an **external name**, recoverable by pattern matching:

```
external_name(Required(name))       = name
external_name(Defined(name, _))     = name
external_name(Alias(name, _))       = name
external_name(Conflicted(left, _))  = external_name(left)
```

For Conflicted, this walks the left spine. In practice, this is shallow — it
terminates as soon as it hits a non-Conflicted node.

**Invariant:** For any `Conflicted(left, right)`, `external_name(left) ==
external_name(right)`. This invariant is enforced at construction time.

### 2.3 Slot Hashing

Each slot variant hashes differently, and the hash is what gives the slot its
identity in the content-addressed store.

**Required(name)**
- Hash input: `(tag="Required", name)`
- Uniqueness: Two Required slots with the same name are identical. There is
  exactly one Required slot per name in the system.

**Defined(name, value)**
- Hash input: `(tag="Defined", name, hash(value))`
- Uniqueness: Two Defined slots are identical iff they have the same name AND
  the same value. Two different implementations of the same name produce
  different hashes. Two identical implementations under different names also
  produce different hashes.

**Conflicted(left, right)**
- Hash input: `(tag="Conflicted", hash(left), hash(right))`
- Uniqueness: A Conflicted node is identified entirely by its children. It
  carries no name of its own — adding one would be redundant since the name is
  derivable from the children, and the children's hashes already incorporate
  their names. Two Conflicted nodes with the same children (in the same
  positions) are identical.
- Note: `Conflicted(A, B)` and `Conflicted(B, A)` are **different** hashes.
  The left/right ordering encodes composition order, which matters for
  resolution policies (e.g., shadowing in scopes). This is intentional.

**Alias(name, slot)**
- Hash input: `(tag="Alias", name, hash(slot))`
- Uniqueness: An Alias is identified by the new name and the inner slot. Same
  inner slot under different names → different hashes. Different inner slots
  under the same name → different hashes.

### 2.4 Why Hash This Way

The hashing strategy is chosen to satisfy these properties:

1. **Self-describing identity.** A slot's hash encodes everything meaningful
   about it. No external context (like position in a map) is needed to
   determine what a slot is.

2. **Structural sharing.** Because identity is hash-based, identical
   sub-structures are automatically deduplicated. A `Required("foo")` slot
   used in 100 different roles exists exactly once in memory.

3. **Composition history preservation.** Conflicted nodes form a tree whose
   structure records the order and grouping of compositions. This tree IS the
   scope chain in scope contexts, and IS the conflict audit trail in role
   contexts.

4. **Alias transparency.** An Alias has a different hash from its inner slot
   (because the name differs), which correctly models that a renamed method is
   a distinct entry point even if it delegates to the same implementation.

---

## 3. Composition

Composition is a **pure, total, binary operation** over slots. It never fails
and never discards information. All error detection and policy decisions are
deferred to the resolution phase.

### 3.1 Slot Composition

Given two slots with the same external name, composition produces a new slot
according to the following table:

```
compose(left, right)  where external_name(left) == external_name(right)

left \ right       | Required(n)     | Defined(n, v2)  | Conflicted(_, _) | Alias(n, _)
-------------------|-----------------|-----------------|------------------|-------------
Required(n)        | Required(n)     | Defined(n, v2)  | Conflicted(_, _) | Alias(n, _)
Defined(n, v1)     | Defined(n, v1)  | *see below*     | Conflicted(L, R) | Conflicted(L, R)
Conflicted(_, _)   | Conflicted(_, _)| Conflicted(L, R)| Conflicted(L, R) | Conflicted(L, R)
Alias(n, _)        | Alias(n, _)     | Conflicted(L, R)| Conflicted(L, R) | *see below*
```

Key cases explained:

**Required + Required → Required.** Two declarations of the same requirement
collapse. Required is the identity element.

**Required + Defined → Defined.** A requirement fulfilled by a definition
resolves to the definition. This is the fundamental role satisfaction
mechanism.

**Required + Conflicted → Conflicted.** A requirement cannot resolve an
existing conflict.

**Required + Alias → Alias.** A requirement is satisfied by a renamed slot.

**Defined + Defined → Conflicted(left, right) if different values.** Two
different implementations of the same name conflict. If the values (and
therefore hashes) are identical, the result is just that Defined slot — this
is the idempotent case where the same implementation was composed from two
paths.

**Defined + Conflicted → Conflicted(left, right).** A new definition doesn't
resolve an existing conflict — it adds to it.

**Alias + Alias → Conflicted(left, right) if different inner slots.** Two
aliases to the same name but different implementations conflict. If the inner
slots are identical, they collapse (idempotent).

**Anything + Conflicted → Conflicted.** Once conflicted, further composition
wraps the Conflicted node into a new Conflicted. Conflict absorbs, but it
absorbs by growing the tree, not by losing information.

### 3.2 Properties

**Commutativity.** `compose(A, B)` produces the same *resolved behavior* as
`compose(B, A)`, but note that the Conflicted tree structure may differ
(`Conflicted(A, B)` vs `Conflicted(B, A)` have different hashes). For
symmetric composition (role into class), resolution treats left and right
identically so this doesn't matter. For asymmetric resolution (scope
shadowing), the caller must be deliberate about argument order.

**Associativity.** `compose(compose(A, B), C)` and `compose(A, compose(B, C))`
produce different tree shapes but equivalent behavior under resolution. The
flattened set of leaf slots is the same; only the nesting differs.

**Identity.** Required is the identity element: `compose(Required(n), X) = X`
for all X with `external_name(X) == n`.

**Idempotency for identical values.** `compose(Defined(n, v), Defined(n, v)) =
Defined(n, v)`. Composing a slot with itself changes nothing.

### 3.3 Role Composition

A **Role** is a map from names to slots. Composing two roles operates
**pointwise**:

```
compose_roles(R1, R2) =
  for each name n in union(keys(R1), keys(R2)):
    if n in R1 and n in R2:
      result[n] = compose(R1[n], R2[n])
    else if n in R1:
      result[n] = R1[n]
    else:
      result[n] = R2[n]
```

Names present in only one role pass through unchanged. Names present in both
are composed according to the slot composition rules.

Role composition is itself associative: you can compose N roles by folding,
and the result is independent of fold order (up to tree shape within
Conflicted nodes, which does not affect symmetric resolution).

### 3.4 Composition Modifiers

Before composing, roles can be transformed:

**Exclusion.** Remove a slot by name from a role before composition. This
prevents a specific name from participating in composition, which avoids
the conflict that would otherwise arise.

**Aliasing.** Wrap a Defined slot in an Alias with a new name. The original
name's slot becomes Required (since the implementation has been "moved"),
and the new name carries the Alias. This renames a method to avoid conflict
while preserving the implementation.

These modifiers are applied to the input roles before the compose operation
runs — they are not part of the compose algebra itself, but preprocessing
steps that shape what goes into it.

---

## 4. Resolution

Resolution is the phase that examines composed structure and applies
context-dependent policy. It is always a separate step from composition.

### 4.1 Resolution for Roles (Class Finalization)

When a composed role is finalized into a class (or into a concrete role that
will be used directly), resolution walks all slots and enforces:

1. **No Conflicted slots.** Every Conflicted slot is an error. Resolution
   collects ALL Conflicted slots and reports them together, rather than
   failing on the first one. This gives the developer complete diagnostic
   information in a single pass.

2. **No Required slots** (optionally). Depending on whether the target is a
   concrete class or an abstract role, unresolved Required slots may or may
   not be acceptable. For concrete classes, all Required slots must be
   fulfilled. For intermediate roles, Required slots are permitted.

3. **Alias slots resolve to their inner implementation.** An Alias in a
   finalized class is valid — it simply provides the inner slot's value
   under the alias name.

**Conflict resolution strategies** available to the developer at finalization:

- **Explicit override.** Provide a new Defined slot for the conflicted name,
  replacing the Conflicted tree entirely.
- **Aliasing.** Rename one or both conflicting implementations so they no
  longer collide on the same name.
- **Exclusion.** Remove one side of the conflict from the source role before
  composition.
- **Delegation.** Provide a new Defined slot that internally delegates to one
  or both of the conflicting implementations (which are still accessible in
  the Conflicted tree).

### 4.2 Resolution for Scopes

When a scope is used for variable lookup, resolution interprets the same
composed structure with a different policy:

1. **Conflicted slots are acceptable.** A Conflicted slot in a scope means
   shadowing has occurred. This is normal and expected.

2. **Lookup walks the Conflicted tree.** The meta layer resolves Conflicted
   nodes by selecting the appropriate child based on scope ordering. In
   practice, this means "the most recently composed value wins" — which
   corresponds to the inner-most scope shadowing outer scopes.

3. **Required slots indicate unbound variables.** A lookup that resolves to a
   Required slot means the variable is declared but not yet defined. Whether
   this is an error depends on the evaluation context (it may be filled later
   by further composition).

4. **The full Conflicted tree is available for introspection.** The meta layer
   can expose the complete shadowing history — not just the winning value but
   all shadowed values. This enables debugging tools, scope inspection, and
   potentially "unshadowing" if a binding is removed.

### 4.3 How Scope Resolution Walks the Tree

Given a `Conflicted(left, right)` node during scope lookup, the convention is:

```
resolve_scope(Required(name))           = Unbound(name)
resolve_scope(Defined(name, value))     = value
resolve_scope(Alias(name, slot))        = resolve_scope(slot)
resolve_scope(Conflicted(left, right))  = resolve_scope(right)
```

The **right** child is the most recent binding (the newer scope frame was
composed on the right). This convention must be consistent with how scope
frames are composed: new frames are always composed as the right-hand argument.

```
current_scope = compose_roles(current_scope, new_frame)
```

This means the tree leans right for the most recent values — the right spine
is the fast path for lookup, while the left subtrees hold the shadowed history.

### 4.4 Resolution Summary

| Aspect               | Role Finalization              | Scope Lookup                  |
|----------------------|-------------------------------|-------------------------------|
| Conflicted slots     | Error (all reported at once)   | Shadowing (resolved by order) |
| Required slots       | Error for concrete classes     | Unbound variable              |
| When it runs         | At class/role finalization      | At each variable lookup       |
| What it returns      | A validated flat role, or errors| A single value, or unbound    |
| Tree traversal       | Full walk, check all slots     | Right-spine walk, short-circuit|

---

## 5. Role Identity and Provenance

### 5.1 Role Hashing

A Role's structural hash is computed from its slots:

- Hash input: the set of `(name, hash(slot))` pairs for all slots in the role
- Since this is a set (not ordered), the hash must use an order-independent
  accumulation (e.g., sort the pairs by name then hash the sequence, or XOR
  the individual hashes)
- Two roles with identical slot sets have identical hashes, regardless of how
  they were constructed

This hash represents **what the role provides** — its behavioral interface.

### 5.2 Provenance

A Role also carries a **provenance set**: a set of hashes identifying every
role in its composition lineage.

When composing Role A and Role B into Role C:

```
C.provenance = { hash(A), hash(B) } ∪ A.provenance ∪ B.provenance
```

Provenance is **not** included in the role's own structural hash. It is
metadata about construction history, separate from behavioral identity. Two
roles with identical slots but different construction histories have the same
structural hash but different provenance sets.

The role's own hash **cannot** be in its provenance set (circular dependency).
It is treated as a virtual first element during checks (see below).

### 5.3 Provenance Hashing

The provenance set itself can be content-addressed:

- Hash input: the sorted set of role hashes in the provenance
- This produces a single hash summarizing the entire composition lineage
- Because provenance includes the provenance of sub-roles transitively, this
  forms a **Merkle tree** of role composition

Properties of the Merkle provenance tree:

- **Tamper evidence.** Any change to any role in the lineage changes all
  hashes above it.
- **Efficient comparison.** Two roles with the same provenance hash have
  identical composition histories.
- **Structural sharing.** Widely-used roles (e.g., Comparable, Serializable)
  appear once in memory, referenced by hash from many provenance trees.
- **Partial verification.** `does?` checks can short-circuit at any level
  without walking the full tree.

### 5.4 The `does?` Check

Two flavors of role satisfaction checking:

**Nominal (provenance-based):**

```
does_nominal?(obj, Role) =
  obj.role.hash == Role.hash             # virtual first element
  || Role.hash ∈ obj.role.provenance     # O(1) set lookup
```

This is fast and exact. It answers "was this specific role used in the
construction of this object's class?"

**Structural (slot-based):**

```
does_structural?(obj, Role) =
  for each slot S in Role.slots:
    case S of
      Required(name) → obj.role has a slot for name (any kind)
      Defined(name, _) → obj.role has a Defined slot for name
                         (value need not match)
```

This is slower but works across independently-defined but compatible roles. It
answers "does this object provide everything this role requires?"

In practice, nominal is the default. Structural is the fallback for duck-typing
or cross-boundary compatibility checking.

---

## 6. Scope as Composed Role

A lexical scope is a Role whose slots are variable bindings. Scope construction
follows the same algebra as role composition.

### 6.1 Constructing a Scope

An empty scope is a role with no slots. Each scope frame is a role containing
Defined slots for its bindings:

```
frame1 = Role { x: Defined("x", 1), y: Defined("y", 2) }
frame2 = Role { x: Defined("x", 10), z: Defined("z", 3) }
scope  = compose_roles(frame1, frame2)
```

Result:
```
scope = Role {
  x: Conflicted(Defined("x", 1), Defined("x", 10)),
  y: Defined("y", 2),
  z: Defined("z", 3)
}
```

Looking up `x` in this scope: the meta layer walks the Conflicted node,
selects the right child (`Defined("x", 10)`), returns `10`. The shadowed
value `1` remains accessible via introspection.

### 6.2 Nested Shadowing

Further composition extends the chain:

```
frame3 = Role { x: Defined("x", 100) }
scope2 = compose_roles(scope, frame3)
```

Result for the `x` slot:
```
Conflicted(
  Conflicted(
    Defined("x", 1),     # original
    Defined("x", 10)     # first shadow
  ),
  Defined("x", 100)      # second shadow (current)
)
```

Lookup resolves to `100`. The full history `[1, 10, 100]` is recoverable by
walking the tree.

### 6.3 Scope Persistence and Continuations

Because the entire scope is an immutable, content-addressed data structure:

- **Capturing a continuation** means capturing a reference to the current scope
  role. No copying is needed — the scope is immutable and will never change.
- **Resuming a continuation** means using the captured scope reference. All the
  slots and their Conflicted trees are still valid, still shared with any
  other continuations that captured overlapping scopes.
- **"Popping" a scope frame** requires no mutation. You simply use a reference
  to the scope that existed before the frame was composed. The composed scope
  remains in the content-addressed store, available to any continuation that
  still references it.

---

## 7. The Meta Layer

The meta layer sits between the raw composed structure and the consumer (method
dispatch, variable lookup, developer tooling). It is the only place where
context-dependent policy is applied.

### 7.1 Responsibilities

- Deciding how to interpret Conflicted nodes (error vs. shadowing)
- Enforcing resolution rules at finalization time
- Providing introspection APIs (list conflicts, show shadowed values, query
  provenance)
- Implementing `does?` checks (nominal and structural)

### 7.2 The Meta Layer Does Not Mutate

The meta layer reads the composed structure and produces answers, but it never
modifies the underlying roles or slots. All "resolution" is interpretive — the
data stays as the algebra produced it. This is essential for the persistence
and sharing properties of the content-addressed store.

---

## 8. Glossary

**Slot:** The fundamental unit — a named entry in a role, in one of four
states (Required, Defined, Conflicted, Alias).

**Role:** A map from names to slots, with a structural hash and a provenance
set.

**Composition:** The pure, total operation that combines two roles (or slots)
into one, preserving all information.

**Resolution:** The policy-driven interpretation of composed structure,
applied at finalization (for roles) or lookup (for scopes).

**Provenance:** The set of hashes identifying all roles in a role's
composition lineage, forming a Merkle tree.

**Structural hash:** A role's identity based on what it provides (its slots).

**Nominal check:** Role satisfaction by provenance identity (was this role
used?).

**Structural check:** Role satisfaction by slot compatibility (does this
object provide what the role needs?).

**External name:** The name a slot presents to the outside world, used for
composition matching and lookup.

**Finalization:** The resolution phase for roles/classes that demands no
Conflicted or (optionally) Required slots remain.

**Shadowing:** The scope resolution policy where Conflicted nodes are resolved
by composition order, with the most recent binding winning.
