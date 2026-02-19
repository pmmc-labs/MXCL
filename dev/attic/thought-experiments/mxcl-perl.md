# A Perlish Language on MXCL

**Revisiting early Perl 6 ideas with a principled runtime**

---

## Introduction

In 2005, the Pugs project brought together ideas that were ahead of their time: a meta-object protocol with roles as foundational, grammars as first-class language constructs, continuations surfaced through gather/take, and the PIL (Pugs Intermediate Language) as a language-agnostic compilation target. The vision was ambitious — a modern language that kept Perl's pragmatic spirit while gaining principled foundations.

Twenty years later, much of that vision remains compelling. But some things are clearer now: which ideas proved essential, which added complexity without proportional value, and what was missing entirely (capability security, a coherent concurrency story, a principled effect system).

This document explores what a Perlish language might look like if built on the MXCL runtime substrate. Not a full Perl replacement, not a reimplementation of Raku — something more focused. A language that captures the good ideas from that era, benefits from two decades of hindsight, and runs on a principled foundation designed for distributed, capability-secure computing.

Call it a thought experiment. Call it unfinished business.

---

## What Made Early Perl 6 Compelling

### Roles as Foundational

The early Perl 6 object model — and Moose, which brought those ideas to Perl 5 — treated roles as the primary unit of behavior composition. Classes existed mainly to instantiate objects, not to define behavior hierarchies.

This was the right call. Roles compose cleanly where inheritance doesn't. Roles separate "what it can do" from "what it is." Roles make mixins principled rather than ad-hoc.

### Representation Flexibility

Perl 5's `bless` could make any reference into an object — a hash, an array, a scalar, a glob. This was seen as a wart, but it contained wisdom: an object's storage should be orthogonal to its interface.

Early Perl 6 formalized this. A class could specify its representation type independently of its roles. An object backed by an array could satisfy the same interface as one backed by a hash.

### Grammars as First-Class

Perl's regex tradition evolved into grammars — recursive, composable, object-oriented parsing. A grammar was a class; rules were methods; parsing produced structured match objects.

This collapsed the distance between "parsing" and "programming." You could define a language's syntax in the same language you used to process it.

### Continuations via gather/take

Lazy sequences without callbacks:

```
my @evens = gather {
    for 0..Inf -> $n {
        take $n if $n %% 2;
    }
};
```

This is delimited continuations with a friendly face. The `take` captures "the rest of the computation" and yields a value; the consumer resumes when it wants more. No explicit continuation objects, no CPS transforms in user code — just a natural way to express lazy, demand-driven computation.

### Multi-Method Dispatch

Functions dispatching on the types of multiple arguments, not just the invocant:

```
multi sub process(Str $s, Int $n) { ... }
multi sub process(Int $n, Str $s) { ... }
```

This generalized method dispatch to arbitrary signatures, making many patterns (visitor, double-dispatch) fall out naturally.

### Gradual Typing

Types as documentation and optimization hints, not straightjackets. You could write untyped code when prototyping, add types where they helped, and the language would use them when present.

### Meta-Object Protocol

The object system was defined in terms of itself. You could ask a class about its methods, roles, and attributes. You could intercept object construction, method dispatch, attribute access. The system was open to introspection and extension.

---

## What Was Missing or Got Complicated

### Concurrency

Perl 6's concurrency story evolved through multiple models — threads, supplies, promises, channels, hyper operators. Powerful, but complex. And no isolation guarantees — shared mutable state was still possible.

### Security

No capability model. Code could access anything it could name. Sandboxing required external mechanisms.

### Effects

I/O was implicit. Side effects could happen anywhere. Testing and reasoning about effectful code required discipline, not language support.

### Scope

The language kept growing. Every good idea got included. The specification became enormous. The "Perl 6 is finished" date kept receding.

### Implementation Fragmentation

Multiple implementations (Pugs, Rakudo, Niecza, others) with different subsets and semantics. The PIL/Parrot vision of a shared substrate never fully materialized.

---

## The MXCL Substrate

MXCL provides a runtime model with clear layers:

**Machine** — Isolated computation unit. Single-threaded, shares nothing. Has a CPS continuation queue, processes one message/turn at a time.

**Strand** — Coordinates multiple Machines cooperatively. The boundary between pure computation and the outside world.

**Effects** — All impurity goes through effect handlers. I/O, network, time — explicitly mediated, swappable, testable.

**Capabilities** — Authority is structural. A Machine can only invoke effects it was granted at construction. No ambient access.

**Channels** — Typed term streams connecting Machines. Communication is explicit, capability-controlled.

**Geometry** — System topology as a first-class reactive object. Nodes, edges, scaling, failure, repair.

And at the language level:

**Operatives** — Objects that control evaluation of their arguments. Macros and control structures unified with methods.

**First-Class Continuations** — Capturable, serializable, movable.

**Meta-Circular MOP** — Roles, classes, objects defined in terms of themselves.

**Homoiconicity** — Code is data, data is code. Metaprogramming is just programming.

---

## The Mapping: Perlish Semantics on MXCL

### Object System

This is where MXCL is already Perlish. The object model descends from Moose and early Perl 6 work:

| Concept | Implementation |
|---------|----------------|
| Roles | Composable behavior units, first-class |
| Classes | Factories binding roles to representation |
| Objects | Instances with representation + composed behavior |
| Representation flexibility | Object storage orthogonal to interface |
| MOP | Meta-circular, introspectable, extensible |

No adaptation needed — this is the foundation.

### gather/take and Lazy Sequences

MXCL has first-class delimited continuations. gather/take compiles to:

- `gather` establishes a continuation delimiter
- `take` captures the continuation and yields a value
- The consumer resumes the continuation when requesting the next value

The Perlish syntax hides the continuation mechanics, just as it did in Perl 6:

```
my @primes = gather {
    for candidates() -> $n {
        take $n if is_prime($n);
    }
};
```

Underneath, this is continuation capture and resumption. On top, it's just a loop that yields values.

### Grammars

Grammars are objects. Rules are operative methods — they receive their arguments unevaluated and control parsing.

The homoiconicity helps: grammar rules can inspect and transform syntax. Match objects are terms. A grammar action can build an AST by returning terms from rule methods.

```
grammar JSON {
    rule TOP { <value> }
    rule value { <object> | <array> | <string> | <number> | ... }
    rule object { '{' <pair>* % ',' '}' }
    ...
}
```

This compiles to operative methods that parse input and produce terms. The MXCL substrate doesn't care about "parsing" — it's just objects returning terms.

### Multi-Method Dispatch

Multi dispatch is method resolution with multiple candidates. The MOP handles this: when you call a multi, the dispatcher examines argument types and selects the most specific candidate.

This could be implemented as:
- Multis are objects with a dispatch table
- The dispatch method is an operative (receives arguments, inspects their types before deciding what to call)
- Ambiguity is a runtime error; no match falls through to a default or fails

### Gradual Typing

Types are represented as objects. A typed variable is a container with a type constraint. Type checking happens at assignment (optionally at call boundaries).

The MOP provides introspection: you can ask a value for its type, ask a type for its constraints. Types can be added incrementally; untyped code works with `Any`.

### Context Sensitivity (Limited)

Classic Perl context sensitivity (scalar vs list) was powerful but confusing. A Perlish-on-MXCL could offer a limited version:

- Operatives receive their arguments unevaluated
- An operative can inspect calling context before deciding behavior
- But context is explicit, not inferred from punctuation

This preserves the power (DWIM behavior) while making it traceable (you can see what the operative does).

### Sigils (Optional)

Sigils (`$scalar`, `@array`, `%hash`) are syntactic, not semantic. A Perlish surface syntax could include them for familiarity:

```
my $count = 0;
my @items = 1, 2, 3;
my %lookup = (a => 1, b => 2);
```

These compile to MXCL terms with appropriate container types. The sigils aid readability and provide hints; the runtime doesn't require them.

---

## What MXCL Adds That Perl 6 Lacked

### Actor Isolation

Perl 6's concurrency allowed shared state. MXCL doesn't. Each Machine is isolated; communication is via Channels.

This is a different model, but arguably better for distributed systems and security:

```
my $worker = spawn {
    receive -> $msg {
        # process in isolation
        reply process($msg);
    }
};

$worker.send($work);
```

The worker can't access the parent's variables. Data crosses the boundary explicitly. Races on shared state are impossible.

### Capability Security

Perl trusts all code equally. MXCL doesn't.

A Perlish-on-MXCL would inherit capability security:

```
my $sandbox = spawn(:capabilities<>) {
    # no I/O, no network, no filesystem
    # can only compute and reply
    ...
};
```

Untrusted code gets limited capabilities. The language enforces it structurally.

### Effect System

I/O in Perl 6 is implicit — `say` just prints, `slurp` just reads. Testing requires mocking globals.

MXCL makes effects explicit:

```
sub log-message($msg) does IO {
    say $msg;
}
```

The `does IO` is a declaration that this code uses the I/O effect. The runtime enforces it; the capability system gates it; testing can substitute effect handlers.

### Distributed Computing

MXCL's geometry layer provides:
- Topology as code
- Supervision and restart
- CRDT vertices for distributed state
- Channels across machine boundaries

A Perlish-on-MXCL inherits this:

```
my $cluster = geometry {
    node(:workers, 4) -> $worker {
        # worker code
    }
    supervise :restart;
};

$cluster.scale(:workers, 8);  # add workers
```

This doesn't exist in Perl 6. You'd have to build it from primitives.

### Continuation Mobility

Continuations in MXCL are serializable. Computation can checkpoint, migrate, resume elsewhere.

```
my $checkpoint = capture-continuation();
save-to-disk($checkpoint);
# later, possibly on another machine
restore-from-disk($checkpoint).resume();
```

Perl 6's gather/take used continuations internally but didn't expose them. MXCL could surface this power for advanced use cases (workflow engines, distributed computation, speculation).

---

## What It Would Feel Like

The goal is a language that feels Perlish — pragmatic, expressive, DWIM — but runs on principled foundations.

**Familiar surface:**
```
role Describable {
    method describe() { ... }
}

class Person does Describable {
    has $.name;
    has $.age;
    
    method describe() {
        "$.name, age $.age"
    }
}

my $p = Person.new(name => 'Alice', age => 30);
say $p.describe;
```

**Lazy sequences:**
```
my @fibs = gather {
    my ($a, $b) = 0, 1;
    loop {
        take $a;
        ($a, $b) = ($b, $a + $b);
    }
};

say @fibs[0..9];  # 0 1 1 2 3 5 8 13 21 34
```

**Isolated concurrency:**
```
my @workers = (^4).map: {
    spawn {
        receive -> $task {
            reply process($task);
        }
    }
};

my @results = @tasks.map: -> $task {
    @workers.pick.send($task).result
};
```

**Capability-restricted sandbox:**
```
my $untrusted = spawn(:capabilities<compute>) {
    receive -> $code {
        reply eval($code);
    }
};

# $untrusted can compute but can't do I/O
```

**Topology management:**
```
my $service = geometry {
    node(:frontend, 2) -> { ... }
    node(:backend, 4)  -> { ... }
    
    connect :frontend, :backend, :channel<requests>;
    
    supervise :restart, :max-restarts(3);
};
```

It looks like Perl. It has Perl's expressiveness. But underneath, you get isolation, capabilities, effects, and distribution.

---

## Scope Discipline

The lesson of Perl 6: scope kills. The language took 15 years partly because it kept growing.

A Perlish-on-MXCL should be intentionally limited:

**Include:**
- Roles, classes, objects with MOP
- Basic types: scalars, arrays, hashes, sets
- Multi-method dispatch
- gather/take (lazy sequences)
- Grammars (parsing)
- Pattern matching
- Actor-based concurrency
- Capability security
- Effect system
- Basic I/O, networking

**Exclude or defer:**
- Exotic operators (hyper, meta, reduction) — add later if needed
- Extensive Unicode operators — ASCII is fine
- Multiple dispatch on everything — keep it to methods
- Complex type system — gradual typing is enough
- Macros in full generality — operatives cover most cases

The goal is a language you could implement in a year, not a decade. Useful, not complete.

---

## Relationship to Existing Work

This isn't starting from zero.

**Moose** — The role/class/attribute model is directly descended from this work.

**PIL / Pugs** — The intermediate language ideas, the focus on language-agnostic runtime, the early object model experiments.

**MXCL's MOP** — Already incorporates lessons from Moose and Perl 6 MOP work.

**Raku** — The existence proof that these ideas can work. But also the cautionary tale about scope.

A Perlish-on-MXCL would acknowledge this lineage. It's not a break from the past — it's an attempt to finish something that started twenty years ago, informed by everything learned since.

---

## Open Questions

### Performance

Can a continuation-based runtime be fast enough for practical Perl-style scripting? The JIT story matters here. Unknown without empirical work.

### Community

Who wants this? Perl people who wish the language had evolved differently? Raku people who want a smaller core? Distributed systems people who want a scripting language with good concurrency? Some intersection of these?

### Syntax Details

How Perlish should the syntax be? Full sigils and twigils? Perl 5 compat? Perl 6 compat? Something new that just "feels" Perlish?

### Bootstrapping

How much of the language can be written in itself? Ideally, most of it — the MXCL MOP is already self-hosting. But practical bootstrapping always involves compromises.

### Name

What do you call a thing like this? It's not Perl. It's not Raku. It's something adjacent.

---

## Conclusion

There's an alternate history where the Pugs-era ideas landed on a principled runtime substrate — actors for isolation, capabilities for security, effects for purity, continuations for control flow — and produced a focused, practical language that felt like Perl but ran like something designed for the distributed era.

That didn't happen. But the pieces exist now.

MXCL's runtime provides the substrate. The object model is already Moose/Perl 6 descended. Continuations enable gather/take. Operatives enable grammars. The effect system and capability model provide what Perl never had.

Whether it's worth building a Perlish surface syntax on this substrate is a separate question. But the possibility is there. The mapping is clean. The lessons from twenty years of Perl 6/Raku evolution are available.

Maybe some things are worth revisiting.

---

*This document is speculative. It explores a path not taken and wonders whether the detour would be worth making now.*
