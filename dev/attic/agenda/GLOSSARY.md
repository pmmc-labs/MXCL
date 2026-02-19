# MXCL Glossary

**Concepts and Background for the MXCL Research Agenda**

This document provides context for the less familiar concepts referenced in the MXCL research agenda. Each entry includes a definition, why it matters for MXCL, and links for further exploration.

---

## Table of Contents

- [Operatives and Applicatives](#operatives-and-applicatives)
- [Homoiconicity](#homoiconicity)
- [Content-Addressed Code](#content-addressed-code)
- [Continuations](#continuations)
- [Meta-Object Protocol (MOP)](#meta-object-protocol-mop)
- [Propagators](#propagators)
- [CRDTs](#crdts)
- [Actor Model](#actor-model)
- [Object Capabilities](#object-capabilities)
- [Smalltalk Images](#smalltalk-images)
- [Local-First Software](#local-first-software)
- [Further Reading](#further-reading)

---

## Operatives and Applicatives

### The Distinction

In most programming languages, when you call a function, the arguments are evaluated *before* the function receives them. This is called **applicative** evaluation:

```
add(2 + 3, 4 * 5)
```

The expressions `2 + 3` and `4 * 5` are evaluated first, and `add` receives `5` and `20`.

An **operative** (also called a *fexpr* in older Lisp terminology) receives its arguments *unevaluated*. The operative itself decides what to do with them — evaluate them, transform them, inspect their syntax, or ignore them entirely.

This is how special forms like `if` work: in `if(condition, then-branch, else-branch)`, you don't want both branches evaluated before `if` decides which one to use. An operative receives the raw expressions and chooses.

### Why This Matters for MXCL

In MXCL, objects *are* operatives. When you send a message to an object, it receives the unevaluated argument expressions and controls what happens next. This unifies:

- Object dispatch (deciding what method to run)
- Macro-like metaprogramming (transforming syntax)
- Control flow (deciding evaluation order)
- Scheduling (in MXCL, operatives can return continuations to control execution)

### Key Figure

**John Shutt** developed the modern theoretical treatment of operatives in his work on the Kernel programming language and vau calculus. His PhD thesis, "vau calculus: An operational theory of first-class operatives" (2010), provides the formal foundations.

### Links

- [Kernel Programming Language](https://web.cs.wpi.edu/~jshutt/kernel.html) — Shutt's language based on operatives
- [Fexpr on Wikipedia](https://en.wikipedia.org/wiki/Fexpr) — Historical background
- [vau calculus thesis (PDF)](https://web.cs.wpi.edu/~jshutt/dissertation/etd-090110-124904.pdf) — The formal treatment

---

## Homoiconicity

### Definition

A language is **homoiconic** when its code is represented using the language's own data structures. In Lisp, both code and data are lists:

```lisp
;; This is data (a list of symbols and numbers)
'(+ 1 2)

;; This is code (the same structure, evaluated)
(+ 1 2)
```

The quote mark is the only difference. Code *is* data, and data can become code.

### Why This Matters

Homoiconicity makes metaprogramming natural. If code is just data, you can:

- Write programs that write programs
- Transform code before evaluation
- Serialize code (it's just a data structure)
- Send code over the network and run it elsewhere

For MXCL, homoiconicity is essential for distributed computing. A continuation — a chunk of suspended computation — is data. It can be stored, moved to another machine, and resumed. The code/data equivalence makes this possible without special serialization machinery.

### Links

- [Homoiconicity on Wikipedia](https://en.wikipedia.org/wiki/Homoiconicity)
- [Lisp on Wikipedia](https://en.wikipedia.org/wiki/Lisp_(programming_language)) — The canonical homoiconic language family

---

## Content-Addressed Code

### Definition

In a **content-addressed** system, data is identified by a hash of its contents rather than by a name or location. If two pieces of data have the same hash, they are identical; if the content changes, the hash changes.

Applied to code: a function's identity is the hash of its structure (its AST), not its name. The name is metadata — a local binding that points to a hash.

```
;; Two developers write:
(define (add a b) (+ a b))      ;; English
(définir (ajouter a b) (+ a b)) ;; French

;; Both hash to (let's say) #a8f3b2c...
;; The names "add" and "ajouter" are local bindings to that hash
```

### Key Properties

- **Structural identity**: Same code = same hash, regardless of what you call it
- **Fearless renaming**: Renaming is just rebinding; it never breaks references
- **Natural deduplication**: Identical definitions stored once
- **Distributed caching**: Hash is a universal identifier across machines

### Why This Matters for MXCL

Content-addressing is part of MXCL's Layer 0 (Term Structure). Combined with homoiconicity and keywordless syntax, it creates a foundation where:

- Terms can move across Channels without name conflicts
- Two developers can collaborate while using different names for the same definitions
- Semantic identity (the hash) is separate from local naming (your namespace)

The Image layer (Layer 6) manages the human-facing names; the hash is the shared truth underneath.

### Technical Detail

For content-addressing to work across equivalent definitions, parameter names shouldn't affect the hash. MXCL represents parameters positionally (similar to de Bruijn indices) in the hashed structure, with human-readable names as metadata.

### Key Project

**Unison** is the primary language exploring content-addressed code. Its tagline is "no builds, no dependency conflicts" — consequences of hash-based identity.

### Links

- [Unison Language](https://www.unison-lang.org/) — Language built on content-addressed code
- [Content-addressable storage on Wikipedia](https://en.wikipedia.org/wiki/Content-addressable_storage) — The general concept
- [IPFS](https://ipfs.io/) — Content-addressed filesystem (related concept applied to files)

---

## Continuations

### Definition

A **continuation** represents "the rest of the computation" — everything that would happen after the current point in a program's execution.

Consider evaluating `(+ 1 (* 2 3))`. When you're in the middle of computing `(* 2 3)`, the continuation is "take whatever result you get and add 1 to it."

In most languages, continuations are implicit (the call stack). Some languages make them explicit and first-class, meaning you can capture the "rest of the computation," store it, and run it later — or multiple times, or never.

### Delimited Continuations

A **delimited continuation** captures only *part* of the remaining computation, bounded by a delimiter. This is more practical than capturing everything up to the program's end.

Think of it like this: you're reading a book (the program), and you put in a bookmark (delimiter). A delimited continuation captures your reading state from now until you hit the bookmark — not from now until the end of the book.

### Why This Matters for MXCL

MXCL's evaluation model naturally produces delimited continuations. Each step of evaluation creates a continuation that's placed in a queue. This gives you:

- Suspendable computation (capture and store the continuation)
- Cooperative concurrency (interleave continuations from the queue)
- Distributed computing (serialize a continuation, move it, resume elsewhere)

### Links

- [Continuation on Wikipedia](https://en.wikipedia.org/wiki/Continuation)
- [Delimited continuation on Wikipedia](https://en.wikipedia.org/wiki/Delimited_continuation)
- "The Discoveries of Continuations" by John Reynolds — Historical survey

---

## Meta-Object Protocol (MOP)

### Definition

A **Meta-Object Protocol** is an API that lets you customize how an object system itself works. Instead of just defining classes and objects, you can redefine what "class" and "object" mean.

In a MOP, the concepts of the object system — classes, methods, inheritance, dispatch — are themselves objects with behavior you can modify.

### Example

Normally, method dispatch finds a method by name and calls it. With a MOP, you could intercept this and:

- Log all method calls
- Add caching/memoization
- Change how inheritance works
- Proxy calls to a remote object

### Why This Matters for MXCL

MXCL includes a meta-circular MOP: the object system is defined using itself. Roles, classes, and objects are implemented as roles, classes, and objects.

This serves as validation that MXCL's "objects as operatives" model is powerful enough for serious metaprogramming. It also enables the flexibility needed for features like remote object references, where a local proxy behaves like a local object but forwards operations elsewhere.

### Lineage

The most influential MOP is the **CLOS MOP** (Common Lisp Object System). MXCL's MOP draws more from Moose (Perl 5) and Perl 6's object systems, particularly in its treatment of roles as foundational.

### Links

- [CLOS MOP on Wikipedia](https://en.wikipedia.org/wiki/Common_Lisp_Object_System#Metaobject_protocol)
- [The Art of the Metaobject Protocol](https://mitpress.mit.edu/9780262610742/the-art-of-the-metaobject-protocol/) — The classic book by Kiczales, des Rivières, and Bobrow
- [Moose](https://metacpan.org/pod/Moose) — Perl 5's modern object system

---

## Propagators

### Definition

**Propagators** are a model of computation where autonomous machines (propagators) are connected by shared cells. Each propagator watches its input cells; when information appears, it computes and adds information to its output cells. Information flows through the network as it becomes available.

The key insight is that propagators work with **partial information** that accumulates **monotonically** — information is only ever added, never retracted. A cell might start empty, then learn "the value is between 0 and 100," then learn "the value is between 30 and 50," then finally "the value is 42."

### Example: Temperature Converter

A simple propagator network for Fahrenheit/Celsius conversion:

```
    [C] ←——— C-to-F ←——— [F]
     ↓                     ↑
     └———→ F-to-C ———→————┘
```

- There's a cell for Celsius and a cell for Fahrenheit
- A propagator watches C and computes F when C gets a value
- Another propagator watches F and computes C when F gets a value

If you put 0 into the C cell, the network propagates and puts 32 into the F cell. But it works bidirectionally — put 212 into F, and you get 100 in C.

The same network handles both "given C, find F" and "given F, find C" without you having to specify the direction. The information flows wherever it can.

### Why This Matters for MXCL

MXCL uses propagator-like CRDT vertices in its geometry layer. These accumulate partial information from multiple sources and propagate merged results. This enables distributed synchronization where:

- Multiple nodes contribute information
- The network converges without central coordination
- Queries can be answered as soon as enough information exists

### Key Figures

**Gerald Jay Sussman** and **Alexey Radul** developed the propagator model. Radul's PhD thesis "Propagation Networks: A Flexible and Expressive Substrate for Computation" (2009) is the main reference.

### Links

- [Propagator model on Wikipedia](https://en.wikipedia.org/wiki/Propagator_(cellular_automaton))
- [The Art of the Propagator (PDF)](https://dspace.mit.edu/bitstream/handle/1721.1/44215/MIT-CSAIL-TR-2009-002.pdf) — Radul and Sussman's paper
- [Propagation Networks thesis (PDF)](https://groups.csail.mit.edu/mac/users/gjs/propagators/revised-html.html) — Radul's full treatment

---

## CRDTs

### Definition

A **Conflict-free Replicated Data Type** (CRDT) is a data structure designed for distributed systems where multiple nodes can make updates independently, without coordination, and still converge to the same state.

The "conflict-free" comes from the mathematical properties of the merge operation. If you design your data type so that merging is:

- **Commutative**: A merge B = B merge A
- **Associative**: (A merge B) merge C = A merge (B merge C)  
- **Idempotent**: A merge A = A

Then replicas can receive updates in any order, merge them any number of times, and always end up in the same state. No conflicts to resolve, no coordination needed.

### Example: Grow-Only Counter

Each node maintains a map of `{node_id: count}`. To increment, a node bumps its own count. To merge, take the max of each node's count. To read the total, sum all counts.

```
Node A: {A: 5, B: 3}  →  total = 8
Node B: {A: 4, B: 7}  →  total = 11

Merged: {A: 5, B: 7}  →  total = 12
```

Both nodes converge to the same merged state regardless of message ordering.

### Why This Matters for MXCL

MXCL's geometry layer uses CRDT vertices for distributed state synchronization. The language doesn't need to understand CRDTs — the geometry provides eventual consistency as a property of the infrastructure. Code sees ordinary channels; the CRDT semantics are hidden in how the vertices merge information.

### Links

- [CRDT on Wikipedia](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
- [A comprehensive study of CRDTs (PDF)](https://hal.inria.fr/inria-00555588/document) — Shapiro et al.'s survey paper
- [crdt.tech](https://crdt.tech/) — Community resources and implementations

---

## Actor Model

### Definition

The **Actor Model** is a mathematical model of concurrent computation where "actors" are the universal primitives. Each actor can:

- Receive messages
- Make local decisions
- Create new actors
- Send messages to actors it knows about
- Designate how to handle the next message

Crucially, actors don't share state. All communication is via asynchronous message passing. This eliminates whole categories of concurrency bugs (no shared mutable state means no race conditions on that state).

### Why This Matters for MXCL

MXCL's Machine is essentially an actor: isolated state, processes messages (continuations) from a queue, can create more work. The Strand coordinates Machines the way an actor runtime coordinates actors.

The operative-as-scheduler insight connects actors to language semantics: an object's operative method can receive a message, store continuations, and release them later — this is actor behavior expressed in the object protocol.

### Key Figures

**Carl Hewitt** introduced the Actor Model in 1973. **Gul Agha** developed it further in his book "Actors: A Model of Concurrent Computation in Distributed Systems" (1986). Modern incarnations include Erlang/OTP and Akka.

### Links

- [Actor model on Wikipedia](https://en.wikipedia.org/wiki/Actor_model)
- [Erlang](https://www.erlang.org/) — Language built on actor principles
- [Akka](https://akka.io/) — Actor toolkit for JVM (source of "ActorRef" terminology)

---

## Object Capabilities

### Definition

**Object Capabilities** (ocaps) are a security model where access rights are tied to object references. If you have a reference to an object, you have the capability to use it. If you don't have a reference, you can't.

This contrasts with Access Control Lists (ACLs), where a central authority decides who can access what. In ocap systems:

- Capabilities are unforgeable (you can't manufacture a reference)
- Capabilities can be delegated (pass the reference to someone else)
- Capabilities can be attenuated (wrap in a proxy that restricts operations)

The principle of least authority (POLA) falls out naturally: give code only the references it needs, nothing more.

### Why This Matters for MXCL

MXCL's capability layer constructs Strands with specific effect bindings. A Strand can only invoke effects it was given references to at construction time. Want to do network I/O? You need the network capability. Filesystem access? Need that capability.

This makes the security model structural. You don't check permissions at runtime; you simply can't express "do unauthorized thing" because you don't have the reference.

### Key Figure

**Mark S. Miller** is the primary figure in modern object capability work. The **E programming language** is the reference implementation of ocap principles.

### Links

- [Object-capability model on Wikipedia](https://en.wikipedia.org/wiki/Object-capability_model)
- [E Programming Language](http://erights.org/) — Miller's capability-secure language
- [Capability Myths Demolished (PDF)](https://srl.cs.jhu.edu/pubs/SRL2003-02.pdf) — Miller et al. on what capabilities actually provide

---

## Smalltalk Images

### Definition

A Smalltalk **image** is a snapshot of a running Smalltalk system — all objects, all code, all state, persisted to disk. When you start Smalltalk, you're resuming that snapshot. When you define a class or modify code, you're changing the live system, and saving the image persists those changes.

This is different from file-based development where source code lives in text files and you compile/run from scratch each time. In Smalltalk, there's no separation between "development environment" and "running program" — it's all one live system.

### Interface Elements

Traditional Smalltalk environments include:

- **Transcript** — A log/REPL window
- **Inspector** — Live view into any object's state
- **Browser** — Navigate and edit classes, methods, categories
- **Workspace** — Scratch area for evaluating expressions

### Why This Matters for MXCL

MXCL's Image layer draws on this tradition but grounds it differently:

- State is version-controlled in git (not an opaque binary blob)
- Text files are the source of truth (not objects in memory)
- History is navigable (every change is a commit)

The goal is Smalltalk's liveness and immediacy without sacrificing the benefits of text-based tooling, version control, and collaboration.

### Links

- [Smalltalk on Wikipedia](https://en.wikipedia.org/wiki/Smalltalk)
- [Pharo](https://pharo.org/) — Modern open-source Smalltalk
- [Squeak](https://squeak.org/) — Open-source Smalltalk descended from Apple's implementation
- [The Early History of Smalltalk](http://worrydream.com/EarlyHistoryOfSmalltalk/) — Alan Kay's retrospective

---

## Local-First Software

### Definition

**Local-first software** is a set of design principles for applications that:

1. Work offline (your device is the primary, not a thin client)
2. Keep your data on your devices (not trapped in someone's cloud)
3. Enable collaboration without requiring a central server
4. Provide longevity (your data outlives any company or service)

The term and principles were articulated by Ink & Switch in their 2019 essay "Local-First Software: You Own Your Data, in Spite of the Cloud."

### Why This Matters for MXCL

MXCL's Image layer is explicitly local-first. "Local" might mean distributed across your machines, but it's still *yours*. The git-grounded persistence model means your data is in files you control, with history you can inspect, in formats that don't depend on any service continuing to exist.

Collaboration is opt-in and controlled, not cloud-by-default. CRDTs at the geometry layer provide the technical foundation for sync without central servers.

### Links

- [Local-First Software essay](https://www.inkandswitch.com/local-first/) — The foundational essay by Ink & Switch
- [Ink & Switch](https://www.inkandswitch.com/) — Research lab exploring these ideas
- [Local-First Web Development](https://localfirstweb.dev/) — Community resources

---

## Further Reading

### Programming Language Theory

- **Structure and Interpretation of Computer Programs** (Abelson, Sussman) — The classic introduction to computation via Scheme
- **Essentials of Programming Languages** (Friedman, Wand) — Interpreters and language implementation
- **Lisp in Small Pieces** (Queinnec) — Deep dive into Lisp implementation techniques

### Distributed Systems

- **Designing Data-Intensive Applications** (Kleppmann) — Modern distributed systems overview
- **A Note on Distributed Computing** (Waldo et al.) — Classic paper on why distribution isn't transparent

### Personal Computing History

- **The Early History of Smalltalk** (Kay) — Origins of the Dynabook vision
- **As We May Think** (Bush, 1945) — The Memex and augmented intellect
- **Augmenting Human Intellect** (Engelbart, 1962) — The conceptual framework

