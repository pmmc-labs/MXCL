# Related work in programming language design that overlaps with MXCL

The technical features MXCL combines—fexprs unified with objects, serializable continuations, content-addressed code, capability security, syntax-free design, and queue-based scheduling—each have established research lineages. **Most strikingly, several projects combine two or three of these features**, suggesting MXCL occupies a genuine design space intersection rather than just aggregating independent ideas.

---

## Systems combining multiple MXCL features

These projects are most worth studying because they've already explored how features interact.

### Kernel + vau calculus (Shutt) — features 1, 5

**John Shutt's Kernel language** unifies fexprs with a syntax-free design in the most rigorous academic treatment available. His key insight: break `lambda` into orthogonal parts—`$vau` (creates operatives that receive unevaluated arguments + environment) and `wrap` (converts operatives to applicatives). This makes `$lambda` a *derived* combiner, not primitive. All special forms become first-class objects that can be passed and stored.

**Must cite:**
- PhD Dissertation: "Fexprs as the basis of Lisp function application; or, $vau: the ultimate abstraction" (WPI, 2010)
- "Revised-1 Report on the Kernel Programming Language" (WPI-CS-TR-05-07)

The dissertation directly addresses Mitchell Wand's influential "The Theory of Fexprs is Trivial" (1998), which argued fexprs break equational reasoning. Shutt shows this applies to source-to-source equivalence, not all reasoning about programs—a crucial distinction.

**Contact:** John Shutt (WPI). Committee included Shriram Krishnamurthi.

### E language (Miller) — features 4, 2, related to 6

**Mark Miller's E** combines deep capability security with distributed object computing and **promise pipelining**—a form of continuation-based asynchronous programming. E's design influenced both JavaScript promises and modern distributed capability systems.

**Must cite:**
- Miller's PhD thesis "Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control" (Johns Hopkins, 2006)—the founding document of the object-capability model
- "Concurrency Among Strangers: Programming in E as Plan Coordination" (TGC 2005)

E demonstrates how capability discipline and continuation-style asynchrony reinforce each other. **Mark Miller is currently Chief Scientist at Agoric** and active on TC39, very accessible.

### Termite Scheme (Germain) — features 2, related to 6

**Termite Scheme** builds Erlang-style actors on Gambit Scheme with **fully serializable continuations**. Messages can contain any first-class value including continuations. Process migration works by capturing the current continuation and spawning a new process on a remote node with that continuation.

**Must cite:**
- "Concurrency Oriented Programming in Termite Scheme" (Scheme Workshop, 2006)

This is the clearest demonstration of continuation serialization enabling distributed process mobility. Related: **Kali Scheme** ("Higher-Order Distributed Objects", TOPLAS 1995) pioneered distributed continuations earlier.

### Multicore OCaml effect handlers — features 2, 6

**OCaml 5's effect handlers** provide the closest existing match to MXCL's queue-based continuation scheduling. Effect handlers capture delimited continuations as first-class values; user-level schedulers explicitly manage a `Queue` of these continuations. The scheduler calls `continue` to resume suspended computations.

**Must cite:**
- "Concurrent System Programming with Effect Handlers" (TFP 2017)—Dolan, Eliopoulos, Hillerström, Madhavapeddy, Sivaramakrishnan
- "Composable Scheduler Activations for Haskell" (JFP 2016)—shows the explicit `enqueue`/`dequeue` design pattern

**Contact:** KC Sivaramakrishnan (now at OpenAI)—the primary researcher on this exact scheduling model. He has extensive publications and is highly active.

### Unison language — features 3, related to 2

**Unison** is the flagship implementation of content-addressed code. Each definition is identified by its **512-bit SHA3 hash**; named parameters are replaced by positional references (like de Bruijn indices) before hashing. Names become separately stored metadata.

The approach enables "typed durable storage"—any value (including functions) can be serialized/deserialized without manual work, since code is identified by hash. This connects to continuation serializability: if code is content-addressed, transmitting closures to other machines becomes straightforward.

**Must cite:**
- Unison documentation on "The Big Idea": https://www.unison-lang.org/docs/the-big-idea/

**Contact:** Paul Chiusano (founder, active on Discord @pchiusano). Heather Miller (CMU) is a visiting researcher.

### Newspeak (Bracha) — feature 4 via architecture

**Newspeak** achieves capability security through architectural means: no static state, no global scope, all names dynamically bound through modules. Classes are first-class, and the module system inherently enforces capability discipline without explicit capability annotations.

**Must cite:**
- "Modules as Objects in Newspeak" (ECOOP 2010, Best Paper)

**Contact:** Gilad Bracha (Dahl-Nygaard Prize 2017), former Java/Dart spec author.

---

## Feature 1: Operatives/fexprs unified with objects

Beyond Shutt's Kernel, several systems explore evaluation control:

### Kraken language — compiled fexprs

**Nathan Braswell's Kraken** demonstrates that fexprs *can* be compiled efficiently via partial evaluation, achieving **70,000x speedup** over naive interpretation. First practical purely functional fexpr-based Lisp with compilation.

**Cite:** "Practical compilation of fexprs using partial evaluation" (arXiv:2303.12254, 2023)

**Contact:** Nathan Braswell—active PhD research directly on fexpr compilation.

### Io language — objects control evaluation

**Io** provides fexpr-like capability through message introspection. Methods access `call message` to get unevaluated arguments, `call sender` to evaluate in the caller's context. No keywords; everything is message passing, including control structures.

**Cite:** http://iolanguage.org/ and Steve Dekorte's papers

### Collapsing Towers of Interpreters (Amin & Rompf)

**Pink and Purple languages** compile reflective towers where semantics can change dynamically—closely related to the 3-Lisp tradition of evaluation control.

**Cite:** "Collapsing Towers of Interpreters" (POPL 2018)

**Contact:** Nada Amin (Harvard)—active researcher on metaprogramming/reflection.

### Historical foundations

- **Brian Cantwell Smith's 3-Lisp** (PhD 1982, POPL 1984)—introduced reflective towers, reification of execution state
- **Kent Pitman "Special Forms in Lisp"** (1980)—the influential argument *against* fexprs that shaped Scheme/Common Lisp; cite for historical context
- **The Art of the Metaobject Protocol** (Kiczales et al., 1991)—MOP allows objects to control dispatch, influenced by Smith's reflection work

---

## Feature 2: Serializable, mobile continuations

### Racket stateless servlets

**Jay McCarthy's work** on Racket's web server provides **production-ready modular serializable continuations**. The approach uses incremental CPS transformation + defunctionalization at compile time—not whole-program CPS.

**Must cite:**
- "Automatically RESTful Web Applications Or, Marking Modular Serializable Continuations" (ICFP 2009)
- "The Two-State Solution: Native and Serializable Continuations Accord" (OOPSLA 2010)—hybrid approach mixing native and serializable continuations

**Contact:** Jay McCarthy (BYU)—active, approachable.

### Queinnec's foundational work

**Christian Queinnec** established the continuation-based web programming paradigm.

**Must cite:** "The Influence of Browsers on Evaluators or, Continuations to Program Web Servers" (ICFP 2000)

### GraalVM Espresso

**Espresso's Continuation API** provides full serializable Java continuations. Continuations implement `Serializable`; the stack is unwound to heap objects for transmission to different JVMs. Supports speculative execution via fork.

**Cite:** https://www.graalvm.org/latest/reference-manual/espresso/continuations/

### Scala Spores — type-safe serializable closures

**Spores** use the type system to ensure closures are serializable for distributed computing. Motivated by Spark serialization errors.

**Cite:** "Spores: A Type-Based Foundation for Closures in the Age of Concurrency and Distribution" (ECOOP 2014)

**Contact:** Heather Miller (CMU), Philipp Haller (KTH Stockholm)—active researchers.

### Oleg Kiselyov's delimcc

**delimcc** for OCaml provides persistent (serializable) delimited continuations as a pure library. Used for CGI programming, probabilistic programming (Hansei), RPC bundling.

**Contact:** Oleg Kiselyov—prolific, very responsive.

---

## Feature 3: Content-addressed code / hash-consing

### de Bruijn indices — foundational

**Must cite:** N.G. de Bruijn, "Lambda Calculus Notation with Nameless Dummies" (1972)—eliminates alpha-equivalence issues so equivalent terms hash identically.

Additional: Bird & Paterson "de Bruijn Notation as a Nested Datatype" (1999) for type-safe encoding.

### Hash-consing techniques

**Must cite:**
- Appel & Shao, "Hash-consing Garbage Collection" (1992)—Standard ML implementation
- Filliâtre & Conchon, "Type-Safe Modular Hash-Consing" (ML Workshop, 2006)

### Nominal techniques — the alternative

**Gabbay & Pitts' nominal sets** provide an alternative to de Bruijn indices using name-swapping rather than nameless representations.

**Must cite:** "A NEW Approach to Abstract Syntax with Variable Binding" (Formal Aspects of Computing, 2002)

**Contact:** Andrew Pitts (Cambridge, amp12@cl.cam.ac.uk)—if you want to discuss trade-offs between approaches.

### Nix/Guix content-addressed derivations

These systems apply content-addressing to build outputs rather than source code, but share philosophical similarities. Tweag's blog series on implementing content-addressed Nix is relevant.

---

## Feature 4: Capability security

### Joe-E — capability-secure Java subset

**Must cite:** "Joe-E: A Security-Oriented Subset of Java" (NDSS 2010)—Mettler, Wagner, Close

**Contact:** David Wagner (UC Berkeley)—excellent academic contact.

### Pony — reference capabilities

**Pony** uses "deny capabilities" at the type level for data-race freedom. Six reference capabilities (`iso`, `trn`, `ref`, `val`, `box`, `tag`) control read/write/sharing.

**Must cite:** "Deny Capabilities for Safe, Fast Actors" (OOPSLA 2015)—Clebsch, Drossopoulou

**Contact:** Sophia Drossopoulou (Imperial College)—also authored formalization of Miller's authority concepts.

### SES/Hardened JavaScript

**Secure ECMAScript** is a standards-track proposal providing capability security via `lockdown()` and `Compartment` isolation. Used in production (MetaMask Snaps, Agoric blockchain).

**Cite:** TC39 proposal at https://github.com/tc39/proposal-ses

### WASI — WebAssembly capabilities

**WASI** requires explicit capability passing; modules receive only granted capabilities. No ambient authority by design.

**Contact:** Lin Clark (Bytecode Alliance), Dan Gohman.

### seL4 and CHERI — capability hardware

**seL4** is a formally verified capability-based microkernel. **CHERI** provides hardware-enforced memory capabilities (Arm Morello board).

**Contact:** Gernot Heiser (UNSW) for seL4; Robert Watson (Cambridge) for CHERI/Capsicum.

### Comprehensive resource

**awesome-ocap** repository: https://github.com/dckc/awesome-ocap — actively maintained capability security resource list.

---

## Feature 5: No keywords / syntax-free core

### Forth

**All words** (including `IF`, `THEN`, `DO`, `LOOP`) are dictionary entries, not reserved. Users can redefine anything.

**Cite:** ANS Forth Standard; "Thinking Forth" by Leo Brodie.

### Smalltalk

Control flow is implemented via message passing—`ifTrue:ifFalse:` is a method on Boolean, not syntax. The entire syntax fits on a postcard.

**Cite:** "The Early History of Smalltalk" (Alan Kay, HOPL).

### Rebol/Red

"Nearly syntax free"—uses dialects (embedded DSLs) sharing lexical structure but with different semantics. The reader produces pure data; evaluation is separate.

**Contact:** Nenad Rakočević (Red creator)—active in community.

### PicoLisp

At the lowest level, *all* functions are fexprs. Single cell data structure; radical minimalism.

**Contact:** Alexander Burger—active development.

---

## Feature 6: Queue-based continuation scheduling

### Concurrent ML

**John Reppy's CML** uses continuation-based implementation where threads enqueue resume continuations with messages. Events are composable abstractions that internally manage continuation queues.

**Must cite:**
- "CML: A higher-order concurrent language" (PLDI 1991)
- "Concurrent Programming in ML" (Cambridge, 1999)

**Contact:** John Reppy (University of Chicago)—definitive expert, still publishing.

### Koka language

**Daan Leijen's Koka** implements async/await, generators, and cooperative concurrency entirely via effect handlers that manage continuations.

**Must cite:**
- "Algebraic Effects for Functional Programming" (MSR-TR-2016)
- "Generalized Evidence Passing for Effect Handlers" (ICFP 2021)

**Contact:** Daan Leijen (Microsoft Research).

### Project Loom (Java)

**Virtual threads** decompose as Thread = continuation + scheduler. Continuations exposed via `jdk.internal.vm.Continuation`, scheduled through ForkJoinPool.

**Cite:** Ron Pressler's "Why Continuations are Coming to Java" (QCon); JEP 444.

### Guile Scheme Fibers

Explicitly builds fibers on delimited continuations (prompts). Scheduler maintains queue of suspended continuations.

**Contact:** Andy Wingo—excellent practical explanations on his blog.

### Foundational papers

- "Threads Yield Continuations" (1998)—Kumar, Bruggeman, Dybvig
- "Engines from Continuations" (1989)—Dybvig, Hieb
- "Obtaining Coroutines with Continuations" (1986)—Haynes, Friedman, Wand

---

## Summary: researchers most worth contacting

| Researcher | Affiliation | Relevance | Features |
|------------|-------------|-----------|----------|
| **KC Sivaramakrishnan** | OpenAI (formerly IIT-M) | Queue-based effect handler scheduling | 2, 6 |
| **Mark Miller** | Agoric | Capability security, distributed objects | 4 |
| **John Reppy** | U Chicago | Continuation-based concurrency | 6 |
| **Jay McCarthy** | BYU | Serializable continuations | 2 |
| **Paul Chiusano** | Unison Computing | Content-addressed code | 3 |
| **Nathan Braswell** | PhD student | Compiled fexprs | 1 |
| **Nada Amin** | Harvard | Reflective towers, staging | 1 |
| **Sophia Drossopoulou** | Imperial College | Capability formalization, Pony | 4 |
| **Gilad Bracha** | F5 | Newspeak, capability via architecture | 4, 5 |

---

## Highest-priority citations

These items should definitely be cited in any academic treatment of MXCL:

1. **Shutt** (2010) — vau calculus dissertation (features 1, 5)
2. **Miller** (2006) — Robust Composition thesis (feature 4)
3. **de Bruijn** (1972) — nameless dummies (feature 3)
4. **Queinnec** (2000) — continuation-based web programming (feature 2)
5. **McCarthy** (2009, 2010) — modular serializable continuations (feature 2)
6. **Reppy** (1991, 1999) — Concurrent ML (feature 6)
7. **Dolan et al.** (2017) — Effect handlers for concurrency (features 2, 6)
8. **Wand** (1998) — "Theory of Fexprs is Trivial" (feature 1, historical critique)
9. **Gabbay & Pitts** (2002) — nominal techniques (feature 3 alternative)
10. **Unison documentation** — content-addressed code in practice (feature 3)

The combination of fexprs-as-objects, serializable continuations, content-addressed definitions, and capability security appears novel. Kernel + E + Unison + Multicore OCaml would be the four systems that, together, cover most of MXCL's design space.