# MXCL and Verifiable Multi-Party Computation

**Trustless Coordination Through Structure**

---

## The Problem

When untrusting parties coordinate computation — privacy protocols, multi-party transactions, decentralized coordination — they face a fundamental question: how do you know the other participants are running the code they claim to be running?

Traditional answers involve:
- Trusted coordinators (but then you've centralized trust)
- Reputation systems (but names can be squatted, impersonated)
- Code audits (but you're auditing a *name*, not what's actually executing)

The gap between "the code you audited" and "the code actually running" is a trust assumption. In adversarial environments, that assumption is an attack surface.

---

## MXCL's Approach

MXCL combines several properties that, together, create infrastructure for verifiable multi-party computation:

**Content-addressed code.** A definition's identity is the hash of its structure. The hash IS the code. When participants agree to run `#a8f3b2c`, there's no ambiguity about what that means — it's the code that hashes to `#a8f3b2c`. Names disappear; structural identity remains.

**Serializable continuations.** A continuation captures "the rest of the computation" as data — environment, stack, what-to-do-next. Continuations can be serialized, moved between machines, and resumed elsewhere.

**Capability security.** A computation context (Strand) receives its capabilities at construction. No ambient authority — if you weren't granted an effect, you can't invoke it. The bounds of what a computation can do are structural, not checked at runtime.

**Machine isolation.** Each Machine is an actor: single queue, no shared state. Communication is explicit via Channels. The trust model the code assumes matches the trust model the runtime enforces.

---

## What These Buy You Together

### Verifiable Code Identity

When participants need to agree they're executing the same protocol, content-addressing makes that concrete:

```
Participant A: "I'm running the CoinJoin protocol"
Participant B: "Which one?"
Participant A: "#7f2a9c3..."
Participant B: [verifies hash] "Same."
```

No name-squatting. No "trust me, this is v2.1." No social engineering via naming. The hash is the identity, and the hash is verifiable.

### Verifiable Protocol State Migration

Continuations can move between participants. Content-addressing means the code *inside* that continuation is also verifiable:

```
A captures continuation C (protocol state so far)
A sends C to B
B inspects C:
  - Code hashes to known protocol: ✓
  - Environment contains expected bindings: ✓
  - Capabilities are appropriately bounded: ✓
B resumes C
```

The receiver can verify exactly what computation they're being asked to continue. "Protocol state migration" becomes "verifiable handoff of auditable computation."

### Audit Trail as Hash Trail

For post-hoc analysis, dispute resolution, or debugging:

```
T=0: A invoked #a1b2c3 with args [...]
T=1: Yielded continuation #d4e5f6
T=2: B resumed #d4e5f6
T=3: Yielded continuation #g7h8i9 to C
...
```

Every step references code by hash. The transcript proves what was executed, not just what was *supposed* to be executed.

### Semantic Equivalence Across Implementations

Different participants might have different optimizations, different local tooling, different environments. But if the core protocol logic hashes the same, they're provably running the same computation. Interoperability becomes structural, not social.

---

## Capability Security in Trustless Contexts

Content-addressing proves *what* code is running. Capabilities bound *what it can do*.

A Strand constructed with only `(network-send, hash-verify)` capabilities cannot:
- Access the filesystem
- Read other participants' state
- Invoke effects it wasn't granted

This isn't a sandbox bolted on — it's the construction model. You don't audit "does this code try to do bad things?" You construct the context so bad things aren't expressible.

For multi-party protocols, each participant can verify:
- The code (content-addressed)
- The bounds (capability set)
- The state (continuation contents)

Without trusting the other participants to be honest about any of these.

---

## Channels as Verifiable Communication

Channels carry terms, not byte streams. Protocol messages are structured data — the same stuff the language computes with.

This means:
- Messages are inspectable (not opaque blobs to deserialize)
- Transformations are transparent (same language, same tooling)
- Interception and analysis use the same primitives as computation

For protocol analysis: put a computation in the middle that pattern-matches on traffic, verifies message structure, logs hashes. It's Wireshark, but with structural understanding.

---

## What This Doesn't Do

MXCL provides infrastructure, not magic:

- **Doesn't solve consensus.** Participants still need to agree on which hash to run, when to start, how to handle failures.
- **Doesn't provide anonymity.** Content-addressing is about integrity, not privacy. (Though it composes with privacy techniques.)
- **Doesn't replace cryptographic proofs.** For some protocols, you need ZK proofs, signatures, commitments. MXCL is the substrate those run on, not a replacement.

---

## Connection to Existing Work

**CoinJoin and collaborative transactions:** Protocol state that moves between participants, with each participant verifying they're continuing the expected protocol.

**Multi-party computation:** Verifiable code identity + capability bounds + isolated execution = infrastructure for MPC protocols where participants don't trust each other.

**Smart contracts:** Content-addressed code is already the norm (Ethereum addresses are hashes). MXCL extends this to the execution model — not just "the code at this address" but "the continuation with this state."

**Decentralized coordination:** CRDT geometry layer provides convergence without central authority. Content-addressed code provides agreement on what computation means.

---

## Lineage

Content-addressed code draws from **Unison** (hash-based identity) and the broader content-addressed storage tradition (**IPFS**, **Git**).

Capability security draws from the **E language** and object-capability literature (**Mark Miller** et al.).

The specific combination — content-addressed code + serializable continuations + capabilities + actor isolation — as infrastructure for verifiable multi-party computation, emerges from conversations with **Yuval Kogman** about trustless coordination in privacy protocols.

---

## Further Reading

- [MXCL Research Agenda](/mxcl-research-agenda.md) — Layer 0 (Term Structure), Layer 4 (Capabilities)
- [MXCL TL;DR — For Yuval](/mxcl-tldr.md#for-yuval) — Condensed version
- [Unison Language](https://www.unison-lang.org/) — Content-addressed code
- [E Language](http://erights.org/) — Capability security
- [Object-Capability Model](https://en.wikipedia.org/wiki/Object-capability_model) — Background
