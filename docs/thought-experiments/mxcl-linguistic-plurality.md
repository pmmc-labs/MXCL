# MXCL and Linguistic Plurality

**Code Without Privileged Language**

---

## The Problem

Most programming languages bake English into their grammar. `if`, `while`, `function`, `class`, `return` — these are reserved words. You cannot redefine them. A French-speaking programmer writes `if`; a Japanese-speaking programmer writes `if`. The language itself speaks English.

This is so ubiquitous it's invisible. But it means that at the deepest level — the syntax itself — programming assumes English as the default.

---

## MXCL's Approach

MXCL makes a different set of choices at the foundational layer (Layer 0: Term Structure). Three properties, chosen together, create a substrate where code has no privileged human language:

**Homoiconicity.** Code is s-expressions — nested lists of symbols and literals. The reader produces pure structure. There's no special syntax for control flow, definitions, or declarations; everything is the same shape.

**No keywords.** What looks like syntax (`if`, `define`, `λ`) is actually bindings in the environment. The reader doesn't know what `if` means — it just sees a symbol. Semantics come from the environment, not the parser.

**Content-addressing.** A definition's identity is the hash of its structure (its AST), not its name. Names are metadata — local bindings that point to hashes.

---

## How These Reinforce Each Other

Homoiconicity means there's nothing special about `if` syntactically — it's just the first element of a list. No keywords means `if` is a binding, not a reserved word; you could bind the same operative to `si` or `もし`. Content-addressing means the underlying definition has a structural identity independent of what anyone calls it.

The result: **the code itself has no preferred language. English is not privileged at the structural level.**

---

## Technical Detail

For content-addressing to work across equivalent definitions, parameter names cannot affect the hash. Consider:

```
(λ (amount rate) (× amount rate))   ;; English
(λ (montant taux) (× montant taux)) ;; French
```

These should be the same function. MXCL represents parameters positionally in the hashed structure (similar to de Bruijn indices). The human-readable names are metadata, associated with hashes in the Image layer but not part of the hash itself.

Similarly, comments, docstrings, and type annotations (if added) do not affect the hash. They're metadata bound to hashes, not embedded in them.

---

## What This Enables

Two developers, working in different human languages, can collaborate on the same codebase:

- Each writes in their own language (their environment binds builtins to their preferred names)
- Definitions hash to the same identity regardless of local naming
- Code exchanged via Channels carries hashes, not names
- Each developer's Image displays their local names for shared hashes

The semantic identity (the hash) is shared truth. The names are personal interpretation.

This isn't automatic translation — the system doesn't translate `add` to `ajouter`. It's deeper: the concept of "add" exists as a hash, and each developer binds their own name to it. They're working with the same thing, named differently.

---

## What This Doesn't Do

Layer 0 provides the **building blocks** for linguistic plurality. It doesn't provide:

- Automatic translation of identifiers
- Multilingual documentation systems
- Full internationalization of tooling and error messages

These are Layer 6 (Image) concerns — where the infrastructure meets humans. The Image layer is where linguistic plurality becomes *practical* through tooling, namespace management, and user interface. Layer 0 makes it *possible* by ensuring the substrate doesn't impose a language.

---

## Connection to Plurality

The Plurality vision — technology for collaborative diversity, cooperation across difference — typically focuses on social and political coordination. But the same principles apply to the tools we build with.

A programming language that structurally privileges English is, in a small way, a centralizing force. It assumes a default. It makes some developers guests in their own tools.

MXCL's Layer 0 is an attempt to build infrastructure without that assumption. The diversity of human languages doesn't need to collapse into English at the syntax level. Participants can coordinate through shared structure (hashes, Channels, capabilities) while maintaining their own linguistic context.

Whether this matters in practice — whether developers actually want to program in their native languages, whether tooling can make this seamless — is an empirical question. But the architecture doesn't foreclose it.

---

## Lineage

Content-addressed code draws from **Unison**, which pioneered hash-based identity for "no builds, fearless refactoring." The specific combination with keywordless syntax and homoiconicity, and the emphasis on linguistic plurality as an emergent property, is novel to MXCL.

The broader concern with linguistic diversity in computing has a long history, from early work on non-English programming languages to contemporary efforts around digital sovereignty. MXCL contributes an architectural approach: don't translate the keywords — eliminate them.

---

## Further Reading

- [MXCL Research Agenda](/mxcl-research-agenda.md) — Layer 0: Term Structure
- [Unison Language](https://www.unison-lang.org/) — Content-addressed code
- [Plurality book](https://plurality.net/) — Technology for collaborative diversity
