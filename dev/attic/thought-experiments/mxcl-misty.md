# MXCL as a Runtime Substrate for Capability-Secure Actor Languages

**An exploration of what could be possible**

---

## Introduction

Misty is a capability-secure actor language designed by Douglas Crockford, continuing the lineage of the E programming language. It provides isolated actors communicating via message passing, capability-based security with no ambient authority, and a clean surface syntax intended to be accessible while remaining principled.

MXCL is a research language exploring the intersection of operative semantics, continuation-based execution, and capability security. Its runtime model — organized into Machines, Strands, Effects, and Capabilities — was designed to be general enough to support various programming paradigms while maintaining strong isolation and security properties.

This document explores whether the MXCL runtime model could serve as a substrate for Misty or similar capability-secure actor languages. The question isn't whether one language is better than the other — they have different goals. The question is whether MXCL's foundations are general enough to host languages with different surface semantics while providing useful infrastructure.

---

## The Misty Runtime Model

Misty's computational model requires:

**Actors** — Independent execution contexts with isolated memory. No shared state between actors.

**Message passing** — The only communication between actors. Messages can contain values and actor addresses (capabilities).

**Turns** — An actor processes one message at a time. During a turn, the actor runs to completion. Outgoing messages are held until the turn completes successfully, then released atomically.

**Actor addresses** — Opaque, unforgeable references. If you have one, you can send messages to that actor. You cannot fabricate addresses — you can only receive them through construction, creation, or introduction.

**The `@` object** — Each actor has access to its own capability set, providing functions like `start` (create actors), `stop` (terminate actors), `send` (via the send statement), `receiver` (register message handler), `delay` (schedule future execution), `portal` (distributed bootstrapping), and others.

**Attenuation** — When passing `@` or parts of it to other actors, capabilities can be restricted. A child actor need not receive all the powers of its parent.

**Lifecycle** — Actors can stop themselves, be stopped by their parent (overling), stop due to unhandled errors, or stop due to coupling (when a coupled actor stops).

---

## The MXCL Runtime Model

MXCL's runtime is organized in layers:

**Machine** — The smallest unit of isolated computation. A Machine has a single CPS continuation queue, its own environment, and shares nothing with other Machines. A Machine is, in effect, an actor.

**Strand** — Coordinates one or more Machines cooperatively. The Strand is the boundary between pure computation and the host system. It runs Machines, intercepts effect requests, and delegates to effect handlers.

**Effects** — When a Machine needs the outside world (I/O, network, time), it yields a Host continuation. The Strand intercepts this, delegates to the appropriate effect handler, and enqueues the resulting continuations. Effects are how impurity enters the system.

**Capabilities** — A Machine receives its effect bindings at construction. If a Machine wasn't granted the network effect, there's no code path that gives it network access. Authority is structural.

**Channels** — Communication between Machines happens through Channels, which carry structured terms (not byte streams). A Channel endpoint is a capability — if you have it, you can read or write; if you don't, you can't.

**Geometry** — At a higher layer, system topology is modeled as a graph of nodes (Strands/Machines) and edges (Channels), itself a programmable, reactive object.

---

## The Mapping

The structural correspondence is straightforward:

| Misty Concept | MXCL Substrate |
|---------------|----------------|
| Actor | Machine |
| Actor address object | Channel endpoint or capability reference |
| Message | Term written to a Channel |
| `@` object | Capability set bound to Machine at construction |
| `@.start()` | Strand spawning a new Machine |
| `@.stop()` | Lifecycle effect |
| `@.receiver()` | Channel read handler registration |
| Turn | Execute continuations until queue empties or effect yields |
| Portal | Network effect + capability exchange protocol |
| Coupling | Supervision primitive in Strand |

The alignment is natural because both systems descend from E's object-capability model and share core assumptions: isolation, capability-based authority, message-passing communication.

---

## What Would Need Adaptation

### Turn Semantics and Message Atomicity

Misty specifies that outgoing messages are held during a turn and released atomically upon successful completion. If a turn fails (unhandled error), outgoing messages are discarded.

The MXCL substrate would need to:
- Buffer Channel writes during turn execution
- Flush the buffer only when the turn completes without error
- Discard buffered writes on turn failure

This is a straightforward extension to the Strand's message handling.

### @ Attenuation

Misty automatically attenuates the `@` object when it's assigned, passed as an argument, or included in a data structure. The attenuated version contains only the actor's address, not its full powers.

On MXCL, this would be implemented as:
- The full `@` is a record of capabilities and functions
- Attenuation produces a wrapper containing only the address capability
- The wrapper is what actually gets serialized/transmitted

Capability attenuation is already idiomatic in object-capability systems; this just codifies the automatic case.

### Suppressing MXCL Power

Misty doesn't have:
- First-class continuations
- Operatives (fexprs)
- User-defined evaluation control

MXCL has all of these. The solution is simple: don't expose them.

Misty code would be compiled to MXCL terms that only use applicative calls. The operative machinery runs underneath — `if`, `and`, `or`, etc. are operatives in the substrate — but Misty code never invokes them directly. The continuation queue executes Misty's compiled code; Misty code never captures or manipulates continuations.

This is analogous to how a C program runs on a machine with registers and a stack, but C code doesn't directly manipulate the program counter. The power exists; it's just not surfaced.

### Syntax

Misty has a specific surface syntax with strict formatting rules. MXCL is homoiconic (s-expressions).

A Misty-on-MXCL implementation would:
1. Parse Misty source to an AST
2. Compile the AST to MXCL terms
3. Execute on the MXCL runtime

The syntax layer is entirely separate from the runtime substrate.

---

## What the Substrate Would Provide

Beyond hosting Misty's semantics, the MXCL substrate offers infrastructure that Misty doesn't currently have:

### Formal Effect System

Misty has endowments — capabilities passed to programs at build time that provide I/O access. This works, but it's somewhat ad-hoc.

The MXCL effect system provides a uniform abstraction: all impure operations are effects, effects are intercepted at a known boundary, effect handlers are pluggable. This makes it easy to:
- Swap real I/O for mock I/O in testing
- Add logging or monitoring transparently
- Sandbox untrusted code by restricting effect handlers

A Misty-on-MXCL implementation could map endowments to effect bindings, gaining this infrastructure for free.

### Geometry Layer

Misty has portals for distributed bootstrapping — a way for actors on different machines to discover each other. But there's no programmable model of topology.

MXCL's geometry layer represents system topology as a first-class reactive object. Nodes are Strands/Machines, edges are Channels, and the graph itself supports operations:
- **Scaling** — add nodes and edges
- **Deformation** — model failures and partitions
- **Repair** — supervision and recovery
- **Symmetry** — replication

This enables declarative, reactive management of distributed systems. A Misty program could describe its desired topology, and the geometry layer would maintain it — restarting failed actors, re-establishing connections, scaling resources.

### CRDT Vertices

Misty actors communicate via messages but have no built-in mechanism for distributed state convergence.

MXCL's geometry layer can include CRDT vertices — nodes that accumulate partial information from multiple sources and merge it according to conflict-free semantics. This provides eventual consistency without central coordination, transparent to the actors communicating through those vertices.

For example: distributed configuration, shared counters, or collaborative data structures — all provided by the substrate rather than implemented per-application.

### Continuation Mobility (Optional Exposure)

Misty doesn't expose continuations, but the substrate has them. A future Misty variant — or a different language on the same substrate — could choose to surface them.

Serializable continuations enable:
- Computation migration between machines
- Checkpointing and recovery
- Speculative execution with rollback

The substrate provides the machinery; languages choose whether to expose it.

---

## Hosting Other Languages

If the MXCL substrate can host Misty, it suggests generality. Other capability-secure or actor-oriented languages could potentially target the same runtime:

- **E** — The grandparent of this lineage; should map cleanly
- **Monte** — A capability-secure descendant of E with guards and auditors
- **Erlang/Elixir** (subset) — Actor isolation and message passing, though not capability-secure by default
- **Domain-specific actor languages** — Purpose-built languages for specific distributed systems problems

The value proposition: implement your language semantics once, gain isolation, capabilities, effects, and distributed infrastructure from the substrate.

---

## For Browser/JavaScript Hosting

The MXCL runtime model doesn't require OS-level processes or threads. Machines are logical, not physical.

On a JavaScript host:
- A Strand runs on the JS event loop
- Machines are cooperatively scheduled within a Strand
- Effects wrap browser APIs (DOM, fetch, localStorage, WebRTC, etc.)
- Web Workers could provide true parallelism for separate Strands if needed

This makes the substrate viable for browser-based applications. A Misty-on-MXCL-on-JS stack would provide capability-secure actors in the browser — useful for sandboxing untrusted code, building collaborative applications, or implementing distributed protocols client-side.

---

## Open Questions

### Performance

The MXCL runtime adds abstraction. Incremental CPS transformation, continuation queues, effect interception — these have costs. For Misty's use cases (distributed systems, security-sensitive applications), the overhead may be acceptable. For tight computational loops, it may not be.

Empirical measurement would be needed. Optimization opportunities exist (continuation fusion, effect handler inlining, JIT compilation of hot paths), but the baseline cost is unknown.

### Interoperability

If Misty runs on MXCL, and another language also runs on MXCL, can they interoperate? The substrate provides Channels carrying terms — but term schemas would need alignment. This is solvable but not automatic.

### Fidelity

Does the mapping preserve Misty's semantics exactly? Edge cases around turn boundaries, failure modes, and timing would need careful verification. A formal treatment — or at least extensive test suites — would be necessary to build confidence.

### Value Proposition

Why would Misty want a different substrate? If the MXCL substrate provides useful infrastructure (geometry, CRDTs, effects), that's an argument. If it's just "another way to implement the same thing," it's less compelling.

The strongest case is if the substrate enables capabilities that would be difficult to build from scratch — reactive topology management, continuation mobility, uniform effect handling. Whether these matter for Misty's target use cases is an open question.

---

## Conclusion

The MXCL runtime model — Machines, Strands, Effects, Capabilities — appears structurally compatible with Misty's requirements. The core concepts align: isolated actors, message passing, capability security, no ambient authority.

Hosting Misty on MXCL would require:
- A Misty parser and compiler targeting MXCL terms
- Turn batching for message atomicity
- @ attenuation implemented via capability wrappers
- Suppression of MXCL features (operatives, continuations) at the surface level

In return, the substrate would provide:
- A formal effect system
- Programmable, reactive system topology
- CRDT-based distributed state convergence
- Optional exposure of advanced features (continuation mobility) for future language evolution

Whether this is worth pursuing depends on goals. As a proof of generality for MXCL's runtime model, it's valuable. As practical infrastructure for Misty, it depends on whether the additional capabilities justify the additional abstraction.

Either way, the exploration suggests that well-designed runtime substrates can support multiple surface languages while providing shared infrastructure for the hard problems: isolation, security, distribution, and coordination.

---

*This document is an open exploration, not a proposal. It examines what could be possible, in the hope that thinking through the mapping reveals something useful about both systems.*
