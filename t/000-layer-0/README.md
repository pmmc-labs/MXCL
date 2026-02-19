# Layer 0: Term Structure -- Test Suite

## What Layer 0 Is

Layer 0 defines the substrate -- what code *is* as data, independent of how
it evaluates or where it runs. It answers the question: **What is code, before
we ask what it does?**

Three properties, chosen together, create the foundation:

- **Homoiconicity** -- Code is s-expressions. The representation you write is
  the representation that exists at runtime. Terms are inspectable, serializable,
  and manipulable as data.

- **No keywords** -- The grammar has no reserved words. What looks like syntax
  (`if`, `define`, `lambda`) is actually bindings in the environment. The reader
  produces pure structure; semantics come from the environment, not the parser.

- **Content-addressing** -- Terms are identified by the MD5 hash of their
  structure. Identity is what a term *is* (its AST), not what it is *called*.

## What This Suite Proves

The AGENDA validation criterion for Layer 0:

> Reader produces pure structure; equivalent definitions hash identically.

The tests verify this in progressively broader scope, from individual
primitives up to whole-system integration properties.

## Test Organization

```
t/000-layer-0/
    000-arena/              Arena (memory model and content-addressing)
    001-scalars/            Scalar term types
    002-composites/         Composite term types and list utilities
    003-parser/             Tokenizer and parser
    004-compiler/           Compound-to-term lowering
    005-layer-0-thesis/     Integration tests for the three Layer 0 properties
```

### 000-arena/ -- Arena

The Arena is the central memory manager. Every term creation goes through
`Arena->allocate(type, fields)`, which MD5-hashes the fields so that
identical content yields the same object reference.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-allocation.t` | 18 | Basic allocation via arena and factory, isa checks, hash/gen fields |
| `001-content-addressing.t` | 11 | Interning (same content = same ref), type in hash, stats tracking, nested hashing |
| `002-generations.t` | 13 | Generation counter, commit snapshots, term gen tracking |

### 001-scalars/ -- Scalar Terms

Six scalar types, each immutable and interned.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-nil.t` | 6 | Nil singleton, type, eq, hash |
| `001-bool.t` | 18 | True/False singletons, Bool() factory, Perl truthiness mapping |
| `002-num.t` | 12 | Construction, interning, value, edge cases (0, negative, float) |
| `003-str.t` | 10 | Construction, interning, empty string |
| `004-sym.t` | 10 | Construction, interning, cross-type distinction (Sym("42") != Num(42)) |
| `005-tag.t` | 11 | Construction, interning, cross-type distinction (Tag("foo") != Sym("foo")) |

### 002-composites/ -- Composite Terms

Cons cells, list utilities, arrays, and hashes.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-cons.t` | 17 | Cons construction, head/tail, interning, chain walking, uncons |
| `001-list.t` | 25 | List(), Uncons(), round-trip, Append(), empty/single-element cases |
| `002-array.t` | 12 | Array construction, length, at(), empty array, interning |
| `003-hash.t` | 15 | Hash construction, length, get(), keys/values, order-independent interning |

### 003-parser/ -- Parser

The tokenizer and recursive descent parser that convert source text into
Token and Compound objects.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-tokenizer.t` | 12 | Numbers, symbols, strings, tags, brackets, whitespace, quote, line tracking |
| `001-parser.t` | 8 | Compounds, nesting, bracket types, quote, multiple expressions, error on mismatch |

### 004-compiler/ -- Compiler

The compiler lowers parser output (Compounds) into interned Terms.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-tokens.t` | 27 | Literal expansion: true/false, numbers, tags, symbols, strings, "0" != false |
| `001-compounds.t` | 40 | Bracket expansion: () -> Nil, +{} -> Hash, +[] -> Array, list building, nesting |

### 005-layer-0-thesis/ -- Layer 0 Thesis

Integration tests that demonstrate the three Layer 0 properties working
together across the full pipeline.

| File | Tests | What It Covers |
|------|-------|----------------|
| `000-structural-identity.t` | 21 | Same source -> same ref; whitespace irrelevance; manual construction matches compilation; sub-expression sharing |
| `001-pure-structure.t` | 100 | "Keywords" compile as plain Syms; no type distinction between keywords and user symbols; tree walk finds only standard term types |

## Running the Tests

```bash
# Run the full Layer 0 suite
prove -lrv t/000-layer-0/

# Run a single subdirectory
prove -lrv t/000-layer-0/000-arena/

# Run a single file
prove -lv t/000-layer-0/001-scalars/000-nil.t
```

Requires Perl v5.42+ with `use experimental qw[ class ]`.

## Shared Utilities

Tests use `lib/Test/MXCL.pm`, which provides lazy-initialized accessors
for a shared `MXCL::Context` and its subsystems:

```perl
use Test::MXCL qw[ terms arena compiler parser ];
```

The shared context is safe because terms are immutable and interned -- no
test pollution. Tests that need isolation (e.g., generation tracking) create
their own `MXCL::Context->new`.

## What Is Not Tested Here

- **Stringify/pprint/numify** -- Display behavior is still evolving.
- **Evaluation** -- What happens when terms execute (Layer 1+2).
- **Effects** -- Host boundary, I/O, capabilities (Layer 3+4).
- **Lambda/Opaque** -- Function terms exist in the allocator but are
  exercised by the execution engine, not Layer 0.
