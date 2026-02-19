# MXCL TL;DR

**Quick summaries for busy people**

This document provides condensed overviews of the MXCL research agenda tailored to different audiences. Each assumes domain expertise and skips background explanation.

--- 

## For General Audiences

MXCL is a personal computing platform — not an app, not a service, but infrastructure you own.

It's a programming language where the boundaries between code, data, and running computation dissolve: objects control their own evaluation, continuations can be captured and moved, system topology is a live object you program.

It's designed to stay coherent across scale: the same model whether you're writing a one-liner or coordinating a cluster. And it's designed to stay yours: local-first, git-grounded, no platform dependency.

### A slightly longer version

MXCL is an experiment in personal computing infrastructure.

At the language level, it's a Lisp where objects and operatives are unified — an object receives its arguments unevaluated and controls what happens next. This means metaprogramming, control flow, and object dispatch are the same mechanism.

At the runtime level, computation is continuation-based: naturally suspendable, serializable, and distributable. A script, a service, and a distributed system are points on a continuum, not different paradigms requiring different tools.

At the environment level, it's a live system you inhabit — inspectable, hackable, version-controlled. Smalltalk's liveness without the binary blob; Unix's text files without the impedance mismatch.

The ambition is a computing platform that stays coherent as it scales: from a REPL on your laptop to a supervised cluster across machines, all in one model, all under your control.

---

## For PL Researchers

MXCL's foundation (Layer 0) combines three properties: homoiconicity (s-expressions), no reserved words (builtins are environment bindings), and content-addressed definitions (identity is hash of structure, names are local metadata). Parameters are represented positionally in hashed structure (de Bruijn-adjacent); human-readable names are metadata in the Image layer. This creates a substrate where code has no privileged human language at the structural level — an architectural choice with implications for distributed code mobility and cross-linguistic collaboration.

MXCL unifies objects and operatives: an object *is* a fexpr, receiving arguments unevaluated and controlling their evaluation. The object system factors into roles (behavior), classes (factories binding role compositions to representation types), and instances (the operatives). Representation flexibility — an object's storage is orthogonal to its protocol — enables transparent remote references. A meta-circular MOP validates the model's expressiveness.

Evaluation is incremental CPS with queue-based scheduling. Rather than whole-program transformation, each reduction step produces continuations placed in a queue. Delimited continuations emerge structurally — no shift/reset required. Operatives return continuation lists, not values, giving user-level code explicit control over scheduling. Combined with objects-as-operatives, an object can capture, store, transform, and release continuations — the object protocol subsumes the concurrency protocol. A Machine is a single queue (an actor); a Strand coordinates Machines cooperatively.

Effects are continuations the Strand intercepts. A Host continuation escapes to an effect handler, which returns continuations to be enqueued. Capabilities bind effects to Strands at construction — structural authority, not runtime checks. Channels (term streams, not byte streams) unify I/O. This follows E/ocap principles with the addition that the trust boundary aligns with the evaluation boundary.

System topology is a first-class reactive object: nodes are Strands, edges are Channels, geometric operations (scaling, deformation, repair, symmetry) map to distributed systems concerns. CRDT vertices act as propagators at the geometry level, providing eventual consistency transparent to language semantics. An Image layer — Smalltalk-style liveness grounded in text and git — surfaces the HCI research: can humans actually inhabit this?

---

## For Capabilities Folks

Content-addressed code means verifiable code identity. When participants need to agree they're running "the same protocol," the hash IS the proof. Not "trust me, this is the right version" — `#a8f3b2c` or it isn't. No name-squatting attack surface. Names are social engineering vectors in trustless environments; content-addressing eliminates them. The audit trail is the hash trail — you can prove exactly what was executed.

Continuations are serializable data, and the code in them is content-addressed. Protocol state migrates between participants, and the receiver can verify exactly what computation they're being asked to continue. Capture it, move it to another machine, resume it — with cryptographic proof of code identity. This isn't "we wrote it carefully" — the structure enforces it. (More detail in the Verifiable Multi-Party Computation document.)

Structural capability security with no ambient authority. A Strand gets its effect bindings at construction — that's the trust boundary. Not runtime checks, not ACLs, not "the coordinator promises to delete logs." If you don't have the capability reference, you can't express the operation. The security model is the same shape as the computation model.

Machines share nothing. A Machine is a single CPS queue — it's an actor. No shared memory, no locks, no races on mutable state. All communication is explicit message passing through Channels. This is the trust model your protocols already assume, but with language-level isolation guarantees rather than "we wrote it carefully."

Channels are typed term streams, not byte streams. Protocol messages are first-class structured data — the same stuff the language computes with. Homoiconicity means messages can be inspected, transformed, validated by the same machinery that runs the program. No serialization boundary where things get lost or misrepresented.

Geometry layer does coordination without central authority. Nodes are Strands, edges are Channels, CRDT vertices handle distributed state convergence. The topology itself is an object you can programmatically construct, monitor, and repair. Participants coordinate through the structure, not through a trusted third party holding the state.

Formalization is a goal, not a handwave. The operative/object semantics are intended to get a vau calculus treatment. The MOP is meta-circular — defined in terms of itself — which forces internal consistency. This isn't "built on vibes."

---

## For Perl Core Hackers

It's a Lisp, but the object system is baked in from the start rather than bolted on. Objects can control whether and when their arguments get evaluated — think of it like prototypes that actually work, or macros that are just methods. An object can inspect the syntax it was handed, transform it, eval some parts, skip others. This means control structures, DSLs, and lazy evaluation are all just method calls.

The object model is roles all the way down. Roles define behavior, classes wire roles together with a representation type, instances are the actual things. The representation is pluggable — an object doesn't have to be a hashref. Could be a scalar, could be an array, could be a handle to something on another machine. Behavior and storage are separate concerns. You've seen this before with bless and Raku's object system; MXCL makes it load-bearing.

Concurrency without shared state. Each little runtime (we call it a Machine) has its own execution queue and shares nothing with other Machines. No threads fighting over variables, no locks, no "is this module thread-safe" questions. Communication happens through explicit message passing. If you want to coordinate, you send messages. This is how Erlang works, but integrated into the object system — an object can hold onto suspended computations and release them later.

Effects handle all the impure stuff — I/O, network, filesystem, TTY. Your code runs pure until it needs the outside world, then it yields to an effect handler which does the dirty work. This makes it obvious where the side effects are, and you can swap handlers for testing or sandboxing. A program that only has the TTY effect literally cannot touch the network.

Capabilities control what a runtime can do. When you spin up a Machine, you give it access to specific effects. No ambient authority — if you didn't grant network access, there's no way to sneak it in later. Security is structural, not "check permissions at runtime and hope you covered all the paths."

System topology is programmable. You describe your deployment — these processes, connected by these channels, with this supervision strategy — and that description is live code, not a config file. It can react to failures, scale up, redistribute work. Same language for your app logic and your ops logic.

The development environment is Smalltalk-inspired but grounded in text files and git. Everything is live and inspectable, but your code lives in files you can grep, diff, and check into version control. History is commits, not "undo in the image."

The practical goal: something you could use as a shell, as a scripting language, as a way to coordinate distributed systems, without having to context-switch between different paradigms and tools. One coherent model from interactive one-liners to supervised clusters.

---

## For Perl Ops Folks

Think of it as programmable infrastructure that actually stays programmable.

Your system topology — machines, services, connections between them — is a live object you interact with, not a static config file you hope gets applied correctly. You define nodes (processes, containers, machines), connect them with channels (like pipes, but structured data), and the whole thing is code you can inspect, modify, and react to at runtime.

Configuration distribution uses CRDTs — data structures that merge cleanly without central coordination. Push config to multiple nodes, they sync up eventually, no conflicts, no "which version wins" drama. Nodes can be offline, come back, catch up. No config management server that becomes a single point of failure.

Supervision is built in. Define what your topology should look like, and the system maintains it. Node dies? Supervisor notices, restarts it, reconnects the channels. Network partitions? The topology knows it's deformed and can repair itself when connectivity returns. You write the repair logic in the same language as everything else.

Scales naturally. Same model whether you're managing one box, a handful of cloud instances, or a cluster. A single-machine setup is just a simple topology. Add nodes to scale, the shape grows. The abstractions don't break when you cross machine boundaries — a channel between two local processes works the same as a channel between two continents.

Capabilities handle permissions structurally. When you create a node, you grant it specific abilities — this one can touch the filesystem, that one can hit the network, this other one gets nothing. No ambient authority, no "oops, that script had more access than I meant to give it." If a node wasn't granted network access, there's no code path that gets it network access.

The Image is your control plane. Smalltalk-style environment where everything is live and inspectable, but backed by text files and git. Browse your running topology, inspect node state, push changes, watch them propagate. History is version-controlled — you can see what changed, when, roll back if needed. It's a workspace, not a dashboard.

Interactive down to scripting up to orchestration. Write a quick one-liner to poke at a running system. Build it up into a script. Evolve that into a full supervision tree. Same language, same tools, same mental model. No boundary where you suddenly need to switch to YAML and Terraform and hope they agree about what your infrastructure looks like.

The pitch: infrastructure as code, but the code stays live. You're not generating configs and throwing them over a wall. You're running the infrastructure.

---

## For Tinkerers

It's turtles all the way down and you can poke any of them.

Objects control their own evaluation. When you call a method, the object receives the raw syntax — unevaluated — and decides what to do with it. Eval some arguments, skip others, transform the whole expression into something else. Every object is potentially its own little language. Want to build a control structure? It's just a method. Want an object that interprets its arguments as a query language? Go ahead. The boundary between "code" and "DSL" dissolves.

Code is data is code. S-expressions — everything is lists. Your program is a data structure you can traverse, transform, and reassemble. Write code that writes code that writes code. Macros aren't a special subsystem, they're just objects that happen to return syntax. And since definitions are content-addressed (identity is a hash), names are just local bindings — you can call things whatever you want, the hash is the truth.

Continuations are save states. At any point in execution, you can capture "everything that was going to happen next" as a first-class value. Store it. Clone it. Run it later. Run it twice. It's like having save/load for your program's execution. Objects can collect these, trade them around, build weird control flow that doesn't exist in normal languages. Coroutines, backtracking, speculative execution — all just patterns over captured continuations.

The object system defines itself. The meta-object protocol — the thing that explains what classes and methods are — is written using classes and methods. You can reach in and change how objects work while standing on the objects you're changing. It's Bootstrap paradox as a programming model.

Channels are structured data, not byte soup. When processes talk to each other, they're sending actual terms — the same stuff the language computes with. Intercept a channel, you can inspect the messages as data structures, transform them, inject your own. Protocol analysis becomes "put a thing in the middle that pattern-matches on the traffic." Think of it as Wireshark but you can write handlers in the same language as everything else.

Build weird distributed contraptions. The topology layer lets you wire up processes across machines into arbitrary graphs. Spin up nodes, connect them with channels, watch data flow around. Build a distributed state machine. Build a gossip network. Build something with no name that only makes sense to you. The supervision system will keep it alive while you poke at it.

Everything is inspectable. The Image gives you a live view into the running system — objects, channels, topology. Poke at things in the REPL, see what happens. It's a playground that happens to also be the real system.

Honestly, the practical applications exist, but the real point is: it's a weird little universe with consistent rules, and you can tunnel down as far as you want.

---

## For Local-First People

Your data lives on your devices. Sync happens without central servers. Collaboration is opt-in, not cloud-by-default.

CRDTs at the infrastructure layer. The geometry has vertices that accumulate state from multiple sources and merge conflict-free. Your nodes can disconnect, work offline, reconnect, and converge — no coordination server required. The sync guarantees come from the substrate, not from application logic you have to get right every time.

Channels carry structured data between nodes. Not byte streams you have to serialize and parse — actual terms, the same stuff the language computes with. When nodes sync, they're exchanging meaningful data structures, not opaque blobs.

The topology is a reactive object. Your system is a graph of nodes and edges that you can inspect, modify, and subscribe to. Node goes offline? The geometry knows. Comes back? Reconnects. You can write repair logic in the same language as everything else.

Capabilities control sharing. When you give someone access to part of your system, you give them specific capabilities — not ambient access to everything. Collaboration means "I'm granting you this capability" not "I'm uploading to a server you also have an account on."

Git-grounded persistence. The Image layer stores state in text files with version history. Every modification is a commit. You can see what changed, when, and roll back. Your data isn't in a proprietary format or a cloud database — it's files you control, diffable and mergeable.

"Local" can mean distributed. Your personal computing environment might span your laptop, your phone, a home server, a VPS. It's still *yours*. The system doesn't care about machine boundaries; it cares about capability boundaries. Your stuff is local to you, not local to a device.

No platform dependency. The runtime doesn't need anyone's cloud. It runs on your hardware. If a company disappears, your system keeps working. The protocols are the system — not someone's service implementing the protocols.

The Image is your environment. Live, inspectable, hackable. Not an app someone else controls — a workspace you own. Smalltalk's liveness, but with files and git underneath so you're never locked in.

This is personal computing infrastructure. Not "productivity software" — the substrate for building your own tools, your own workflows, your own collaborative spaces. Ownership all the way down.

---

## For [Next Audience]

*To be written.*
