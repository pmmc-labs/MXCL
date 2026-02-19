# MXCL Research Agenda

**Post Modern Media Computing Labs**

---

## Overview

MXCL (Matt's eXtensible Control Language) is a programming language and computing environment designed to explore the intersection of language semantics, distributed systems, and personal computing. The research agenda is organized as a seven-layer stack (0–6), where each layer answers a distinct question and enables the work above it.

Layer 0 defines the substrate — what code *is* as data. Layers 1–3 address *what computation means* (semantics, execution, effects). Layers 4–6 address *how computation lives in the world* (trust, topology, humans).

---

## Layer 0: Term Structure

**Core question:** What is code, before we ask what it does?

### Contribution

Layer 0 defines the substrate — what code *is* as data, independent of how it evaluates or where it runs. Three properties, chosen together, create a foundation that the rest of the stack builds on:

**Homoiconicity.** Code is s-expressions. The representation you write is the representation that exists at runtime. Terms are inspectable, serializable, and manipulable as data. This is established Lisp tradition, but it's load-bearing for everything above.

**No keywords.** MXCL has no reserved words baked into the grammar. What looks like syntax (`if`, `define`, `λ`) is actually bindings in the environment. The reader produces pure structure — nested lists of symbols and literals. Semantics come from the environment, not the parser.

**Content-addressing.** Definitions are identified by the hash of their structure. A function's identity is what it *is* (its AST), not what it's *called*. Names are local metadata — bindings in a namespace that point to hashes.

### Why These Three Together

Each property reinforces the others:

- Homoiconicity makes hashing straightforward (the code is already a tree)
- No keywords means the structure isn't language-dependent at the syntax level
- Content-addressing makes names truly local (you bind to hashes, hashes don't know their names)

The result: **terms are self-describing, portable, and namespace-independent.**

### What Layer 0 Enables

| Property | What it enables upstream |
|----------|--------------------------|
| Homoiconicity | Operatives can inspect/transform their arguments (Layer 1) |
| No keywords | Builtins are environment bindings, can be rebound (Layer 1) |
| Content-addressing | Terms can move across Channels without name conflicts (Layer 4-5) |
| All three | Code mobility, structural equality, namespace independence |

### What Layer 0 Does NOT Address

- What happens when a term evaluates (Layer 1: operatives)
- How evaluation proceeds (Layer 2: continuation machines)
- How names are managed for humans (Layer 6: Image)

### Technical Notes

**Parameter names.** To preserve structural identity across equivalent definitions, parameter names should not affect the hash. Internally, parameters can be represented positionally (de Bruijn indices or similar). The human-readable names are metadata, bound in the Image layer.

**Metadata.** Comments, docstrings, type annotations (if added) do not affect the hash. They are associated with hashes in the Image, not embedded in the hashed structure.

### Lineage

Content-addressed code draws from Unison's hash-based identity model. The specific combination with keywordless syntax and homoiconicity is novel — together they create a substrate where code has no privileged human language at the structural level.

---

## Layer 1: Operative Object Semantics

**Core question:** Can objects *be* operatives?

### Contribution

MXCL unifies objects and operatives (fexprs). An object is not something that *has* methods which are operatives — the object *is* an operative. It receives its arguments unevaluated and decides what to do with them: inspect the syntax, control evaluation order, transform the expression, or evaluate normally.

This means:
- Homoiconicity (Layer 0) is leveraged — operatives receive and manipulate actual syntax
- Metaprogramming becomes method definition, not a separate macro system
- The object protocol *is* the evaluation protocol

### Object Model

The object system uses a three-tier structure:

- **Roles** — Pure behavior, composable units. "What it can do" without commitment to state representation.
- **Classes** — Factories that wire together role compositions with a chosen representation type. The meta-object layer lives here.
- **Objects** — The operatives themselves. They have a representation (could be a record, a scalar, a remote handle) and behavior (from composed roles).

The separation of behavior (roles) from state (representation) is crucial. Representation is a choice made at the Class level, and the object's operative behavior is indifferent to it. This enables later layers to implement remote references transparently.

### Validation

A meta-circular MOP (Meta-Object Protocol) demonstrates the model is expressive enough for serious metaprogramming. The MOP is self-describing: roles, classes, and objects are themselves defined using roles, classes, and objects.

### Lineage and Novelty

The role/representation separation draws from Perl 5's blessable types and Perl 6's object system. Role composition semantics are established research. The novel contribution is the operative/object unification itself.

### Future Formalization

A vau calculus treatment of the operative/object relationship would be a valuable eventual contribution, but is not blocking.

---

## Layer 2: Continuation Machines

**Core question:** Can incremental CPS transformation with queue-based execution give us delimited continuations and isolation?

### Contribution

Rather than transforming the entire program into continuation-passing style at compile time, MXCL incrementally transforms expressions into continuations as it evaluates. Each continuation has its current environment and a stack for temporary values. Continuations are placed in a queue and run, producing either more continuations (enqueued) or values (pushed to the waiting continuation's stack).

This architecture provides:
- **Delimited continuations for free** — Each continuation is already a bounded piece of work. No shift/reset markers needed.
- **Natural interleaving** — The queue enables round-robin, prioritization, suspension, and inspection without special machinery.
- **Serialization** — Continuations are explicit data (environment + stack + what-to-do-next), enabling snapshot, migration, and persistence.

### The Machine

A Machine is the smallest unit of computation: a single CPS queue, fully isolated. A Machine is an Actor in the theoretical sense.

### The Strand

A Strand coordinates one or more Machines cooperatively. It is the boundary between MXCL semantics and the host system — where I/O, network, time, and other Strands enter.

### Operative-as-Scheduler

Operatives return continuation lists, not values. An operative doesn't just control evaluation of its arguments — it controls *what work happens next* by explicitly producing queue entries.

Combined with Layer 1's object system:
- Objects can have operative methods
- Operative methods return continuations to be enqueued
- Objects can hold continuations in their representation (as data)
- Later, an operative method can release stored continuations back onto a queue

An object can therefore be a scheduler, coroutine manager, promise, or channel — not by special-casing, but because the primitives compose. The object protocol *is* the concurrency protocol.

### Open Work

- Lexically-scoped `return` operative for non-local returns with proper unwinding
- Addressing continuations in the queue for non-local return targeting
- User-defined operatives: how the language surfaces continuation-returning behavior (explicit first-class continuations, quasi-quote syntax, or restricted to native operatives)

---

## Layer 3: Effects

**Core question:** Can the host boundary be just "special continuations"?

### Contribution

The effect system is the purity boundary. A Machine runs until it yields a Host continuation — a request that escapes to the outside world. The Strand inspects the Host continuation, delegates to the appropriate effect handler, and the handler returns continuations to be enqueued.

Effects are not a separate system. They are continuations that the Strand intercepts. The effect handler is external to pure computation but speaks the same language.

### What Effects Enable

Actor mailbox semantics, fork/join threading, file I/O, network communication, and TTY interaction can all be implemented as effects. The effect system handles routing data between Machines in a single Strand, sending data to another Strand, or serializing and sending to another computer.

---

## Layer 4: Capabilities

**Core question:** Can Strand construction be the trust boundary?

### Contribution

The Capabilities layer constructs Strands, configures their root environments, and binds effect handlers to them. A Strand can only invoke the effects it was given at construction time. Trust is structural, not runtime-checked.

### Mechanism

- Capabilities layer creates Strands with controlled effect bindings
- Resources (files, network, etc.) are proxied through effects
- Access is granted via functions bound to the Strand's environment
- Object Capability model: if you have a reference, you have the capability

### Channels

Channels are the universal I/O primitive, following Plan 9's "everything is a file" philosophy — but instead of byte streams, everything is a stream of terms.

This means:
- Homoiconicity extends to I/O (data flowing through Channels is what you compute with)
- Serialization is natural (terms are already the representation)
- Effect handlers have one interface: read terms, write terms, signal completion/error

### Validation

Real effects (TTY, network, filesystem) that are mediated through effect handlers and granted via capability binding at Strand construction. A Strand with TTY capability can interact with the terminal; one without cannot.

### Lineage

The E language and object-capability literature. Specific novel aspects to be determined as the design solidifies.

---

## Layer 5: Geometry

**Core question:** Can system topology be a live, reactive Object?

### Contribution

System topology is described and managed as a first-class Object in MXCL. The topology is not a static configuration file — it is a living shape that exists in the system, with operative methods, event handlers, and capability constraints.

### Primitives

- **Nodes** = Strands (units of computation)
- **Edges** = Channels (units of communication)
- **Shape** = The graph structure, itself an Object

### Geometric Operations

| Operation | System Behavior |
|-----------|-----------------|
| Scaling | Adding nodes/edges — system grows |
| Deformation | Failure, partition — shape is damaged |
| Repair | Supervision — restore the shape |
| Symmetry | Replication — identical substructures |
| Distance | Latency, hop count — metric on the graph |

### What This Enables

- A script is trivial geometry: one node, TTY channel
- A pipeline is linear geometry: nodes connected by pipes
- A distributed system is complex geometry: nodes across machines, supervision, replication

Because this is MXCL code, geometry management uses the same Effect handlers and Capability controls as everything else. You are not describing a system in YAML hoping an orchestrator interprets it — you are writing MXCL that constructs and manages the geometry directly.

### Synchronization: CRDT Vertices

CRDT vertices act as Propagators (in the Sussman/Radul sense) at the geometry level:
- Hold replicated state
- Merge incoming partial information according to CRDT semantics
- Propagate results outward

These are not language-visible as CRDTs. From MXCL code's perspective, they are Channel endpoints that happen to be eventually consistent. The geometry provides the guarantee; the language stays pure.

### Validation

A non-trivial geometry demonstrating scaling, deformation, repair, and optionally replication with CRDT-backed consistency.

---

## Layer 6: Image

**Core question:** Can humans actually live and work in this thing?

### Contribution

HCI research into personal computing environments built on the MXCL stack.

### What "Image" Means

- Smalltalk's "everything is live and persistent"
- But grounded in text files and git (not opaque binary blobs)
- System state is version-controlled by construction
- Every modification is a commit; history is navigable

### Interface Surface

- **Transcript windows** — REPL, but richer; CLI and GUI as peers
- **Object inspectors** — Live introspection of the object graph
- **System browsers** — Classes, geometries, effects, capabilities

### Key Properties

- **Local-first** — "This is mine" even if it spans machines
- **Collaborative** — Controlled sharing, not cloud-by-default
- **Practical** — Perl's pragmatism, not Smalltalk's insularity
- **Personal** — Dynabook ethos: augmenting individual capability, not enterprise workflow

### Linguistic Plurality (Future Work)

Layer 0's content-addressed, keywordless terms create the *possibility* of linguistic plurality — code that has no privileged human language. The Image layer is where this would become *practical*:

- Namespace mappings in your preferred language
- Tooling that displays your local names for hashes
- Shared code exchanged by hash, named locally by each party

This is not a launch requirement, but the architecture enables it. The semantic identity (hash) is shared; the names are yours.

### Research Pivot

This layer asks different questions. Not "what are the semantics" but "how do humans live inside this system?" How do you debug a geometry? What does it feel like to inspect a distributed object? How do you teach someone to think in terms, channels, and capabilities?

The answers will feed back into the lower layers.

---

## Validation Summary

| Layers | Validated By |
|--------|--------------|
| 0 | Reader produces pure structure; equivalent definitions hash identically |
| 1 | Meta-circular MOP |
| 1+2 | Operative-as-scheduler composition |
| 3+4 | Real effects (TTY, network) with capability enforcement |
| 5 | Non-trivial self-managing geometry |
| 6 | Living in the Image |

---

## Lineage

MXCL builds on and acknowledges:

- **Kernel/vau calculus** (Shutt) — Operative/fexpr foundations
- **Moose and Perl 6** — Role-based object systems, representation flexibility
- **Scheme/Lisp tradition** — Homoiconicity, meta-circular interpretation
- **Unison** — Content-addressed code, hash-based identity
- **Actor model** (Hewitt, Agha, Akka) — Isolated computation, message passing
- **E language** — Object capabilities
- **Plan 9** — Uniform resource access via file-like abstractions
- **Smalltalk** — Live environments, image-based development
- **Propagators** (Sussman, Radul) — Monotonic information accumulation
- **CRDTs** — Conflict-free replicated data types
- **Local-first software** — Ownership, offline capability, collaboration


