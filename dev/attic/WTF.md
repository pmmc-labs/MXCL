# What Is MXCL, Actually?

An honest exploration of what this project is, what it isn't, and where it might go.

---

## The Elephant in the Room

Let's acknowledge what everyone is thinking: **this looks like a solution looking for a problem**.

A language with fexprs/operatives? Serializable continuations? Content-addressed code? Capability-based effects? CRDTs? This reads like a comp-sci feature wishlist. The kind of thing that gets written up in papers, presented at conferences, and never used for anything real.

We know. We're thinking it too.

But here's the thing: we have historical precedent, and the gift of hindsight. We can steal what was good and learn from what was bad. And sometimes what looks like a "solution looking for a problem" turns out to be infrastructure that enables things that weren't possible before.

Unix was a solution looking for a problem. The web was a research project. Git was Linus scratching an itch.

Maybe MXCL is just an interesting research project. Maybe it becomes something more. We're exploring.

---

## What We're Stealing

### From Scheme/Kernel
The idea that evaluation itself can be programmable. Operatives (fexprs done right) mean you can define your own syntax, your own control flow, your own evaluation semantics. Not as a special compiler feature — as a library.

### From Smalltalk/Genera
The live environment. Everything is inspectable, modifiable, running. No distinction between "development" and "production" — just computation you can see and touch. The debugger isn't a separate tool; it's just another view into the same system.

### From Unison
Content-addressed code. The hash is the identity. No more dependency hell, no more "works on my machine," no more hoping environments match. If the hash matches, the behavior matches.

### From the E Language
Capability security. Code can only do what you explicitly grant. Not sandboxing bolted on after the fact — it's the foundation. This is what makes safe composition of untrusted code possible.

### From Erlang/OTP
The actor model and "let it crash" philosophy. Distributed by default, failure as a normal part of operation, supervision trees that keep systems running.

### From Local-First/CRDTs
Data (and computation) that you own. Works offline, syncs when connected, no central authority required. Your stuff is yours.

### From Perl
Ergonomics. TIMTOWTDI. The understanding that programming is a human activity, not a mathematical one. Sometimes you want terse. Sometimes you want verbose. The language should get out of your way.

---

## What We're Learning From

### Smalltalk's Parallel Universe Problem
Smalltalk was (is) incredible. It's also an island. To use it, you abandon your existing tools, workflows, and interoperability. You move into the Smalltalk world entirely, or not at all.

MXCL stays git-grounded. Text files. Terminal interface. Standard version control. You can use your editor, your shell, your existing tools. No parallel universe required.

### Genera's Proprietary Hardware
The Lisp Machines were the most sophisticated development environments ever built. They required specialized, expensive, proprietary hardware. When commodity hardware caught up in raw performance, the ecosystem collapsed.

MXCL runs on commodity hardware. The VM is portable. No special silicon required.

### LightTable's Radical Departure
Chris Granger's LightTable pushed hard on live programming, inline evaluation, visual code exploration. It was exciting. It also discovered that showing functions individually "introduces cognitive load through loss of locality." Radical departures from text can backfire.

MXCL keeps text as the primary representation. The Image layer can add visualization, but the foundation stays familiar.

### HyperCard's Island Stacks
HyperCard achieved something remarkable — roughly 1 in 3 Mac users built something with it. But stacks were islands. They couldn't easily share code, build on each other, form an ecosystem.

MXCL's content-addressed code means sharing is fundamental. Not sharing "files that might work" — sharing exact computations, definitions, behaviors.

---

## The Swiss Army Chainsaw

Perl was famously called the "Swiss Army Chainsaw" — brutally effective, perhaps dangerous, definitely not elegant, but gets the job done when nothing else will.

Matt always preferred that framing to "Swiss Army Knife." A knife is a tool. A chainsaw is a *force*.

If Perl is a Swiss Army Chainsaw, then MXCL is a **build-your-own-swiss-army-chainsaw kit**.

You're not getting a fixed set of tools. You're getting the means to build whatever tools you need:

- Need a logic programming mode? Define operatives that manage backtracking.
- Need a reactive system? Define operatives that track dependencies.
- Need a query language? Define operatives over collections.
- Need something that doesn't exist yet? Build it.

The operative system means the language is never "finished." It grows to fit the problem, not the other way around.

---

## What Could Actually Be Built?

We should be concrete. What does MXCL enable that's hard otherwise?

### Personal automation that scales

Most automation has a ceiling. Shell script → Python script → distributed system with Celery/Redis/Kubernetes → ops nightmare.

MXCL thesis: start with a REPL expression, scale to a cluster, without rewriting. The continuation model means "run this elsewhere" is the same semantics as "run this here."

### Code you can actually share

Current state of code sharing:
- Hope dependency versions match
- Hope environments match  
- Hope implicit assumptions match
- Give up and containerize everything

With content-addressed code, the hash is the identity. You're not sharing "code that should work" — you're sharing the exact computation.

### Safe composition of untrusted code

This is the blocker for malleable software. You want to run plugins, extensions, user customizations. You can't trust them not to trash your system or steal your data.

Capability effects make this tractable. Code can only do what you grant. Not as a sandbox — as the foundation.

### Computation you can inspect and modify

In production, computation is opaque. Something breaks, you add logging, redeploy, wait for it to happen again.

With serializable continuations, the computation itself is data. Examine it, serialize it, ship it somewhere else, resume with modifications. Smalltalk debugger power for distributed systems.

### Local-first applications with computation

The local-first movement (Ink & Switch, Automerge, etc.) has solved data sync with CRDTs. But computation is still centralized — your data syncs, but the logic lives on someone's server.

MXCL's Geometry layer extends this to computation itself. Your code, your data, your execution — all yours, all syncing, all under your control.

---

## What MXCL Is Not

**Not a replacement for Python/JS/Go for everyday scripting.** Those languages won. They have ecosystems, libraries, momentum. We're not competing for "write a quick script to process some files."

**Not an academic exercise in language design.** The features aren't chosen for elegance or theoretical interest. They serve a unified thesis: computation should be first-class, portable, inspectable, and ownable.

**Not a finished product.** This is exploration. The agenda is ambitious on purpose. Ideas will drop off. Better, simpler ideas will replace complex ones. This is a new project, and we're figuring it out as we go.

---

## The Research Angle

Yes, MXCL is a valid research tool. The combination creates novel territory:

- **Distributed systems**: Serializable continuations + CRDTs is underexplored
- **Language design**: Operatives as a practical mechanism, not just theory
- **Security**: Capabilities as a real-world permission model
- **HCI**: Live programming for distributed computation

But good research tools become real tools. Unix started as research. The web started as research. We're not building a toy — we're building infrastructure we want to use ourselves.

---

## The Real Risk

The risk isn't "is this useful?" — it's **"can this be communicated and adopted?"**

Smalltalk was useful. Genera was incredibly useful. They lost because:
- Required too much buy-in upfront
- Couldn't interoperate with the mainstream
- Community couldn't reach critical mass

MXCL's mitigations — git-grounded, text files, familiar REPL, Perlish ergonomics — are aimed squarely at this. Whether they're enough is the real question.

---

## The Personal Angle

This project brings together ideas that Matt and I shared over twenty years. Conversations about what languages could be, what computing should be, what was wrong with the status quo and how it might be fixed.

Matt's not here to build it with me. But the ideas we developed together are. MXCL is, in part, an attempt to realize some of what we imagined.

That doesn't make it good or useful. It makes it personal. The two aren't the same, and we shouldn't pretend they are.

But sometimes personal projects turn into something more. And sometimes the only way to find out is to build.

---

## So What Is MXCL?

It's a build-your-own-swiss-army-chainsaw kit.

It's an attempt to realize the Dynabook software environment that was promised but never shipped.

It's infrastructure for the kind of "malleable software" that researchers keep reaching for but can't quite build on current foundations.

It's a research project that might become a practical platform, because the research *is* building the practical platform.

It's a twenty-year conversation, finally getting written down in code.

It's exploration. We'll see where it goes.
