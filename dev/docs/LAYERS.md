
# The Layers of MXCL

This document provides a brief summary of the layers of MXCL and how they build
upon one another. 

### LEGEND:

- [ ] = not started
* [ ] = WIP
* [x] = done but needs test
- [x] = done

<!----------------------------------------------------------------------------->
## Layer 0: Term Structure
<!----------------------------------------------------------------------------->

Layer 0 defines the structure of the terms used within MXCL. This layer is 
purely about data, albiet code represented as data.

- Homoiconicity
    - [x] code is data
    - [x] the code is built entirely from S-Expressions
- Zero Keywords
    - [x] there are no special forms in the `Parser`
    - [x] the `Compiler` produces core terms only
    - [x] semantics come from the environment, not the parser
- Content-Addressing
    - [x] all terms are hash-consed by their contents
    - [x] structural identify is hash identity
    - [x] terms are interned and deduplicated
- Arena Audit Trail
    - [x] commit log: ordered chain of snapshots with parent linkage
    - [x] each commit tracks newly allocated terms (`->changed`)
    - [x] each commit optionally snapshots the reachable term set (`->reachable`)
    - [x] `walk`: traverse all committed terms in order, with commit context
    - [x] `reachable_from`: BFS from given roots following term structure
    - [x] `dropped_between`: terms reachable in commit A but not in commit B    

<!----------------------------------------------------------------------------->
## Layer 1: Role Substrate
<!----------------------------------------------------------------------------->

Layer 1 provides a substrate for Role composition using terms defined in 
Layer 0. 

- Communitivity & Associativity
    - [x] role composition is order independent
    - [x] roles hash predictably 
- Role Operations
    - [x] Union: composing two roles together
    - [x] Conflicts: detecting conflicts during composition
    * [ ] Resolution: explicit override (forces an ordering)

<!----------------------------------------------------------------------------->
## Layer 2: Callables, Environments & Scopes
<!----------------------------------------------------------------------------->

Layer 2 provides a set of callable terms, each of which is either an 
Operative (args are not evaluted) or Applicative (args are evaluated). 
These can be used as functions in the environment, or methods of a Role. 

This layer also provides the Environment and Scope abstractions using roles
as the name lookup mechanism, and the environment operations are implemented
as role operations.

- Minimal Bootstrap & Prelude
    * [x] prelude environment (only `bind`) 
    * [x] prelude bootstraping of core language

- Environments & Scopes
    - [x] deriving scopes
    - [x] name resolution
    - [x] fixed-point for recursion
    - [x] Scopes are Roles
        - [x] Conflicts handled on lookup

- Operatives
    - [x] arguments are unevaluated
    - [x] returns a list of continuation objects
    - [x] can be user defined
- Applicatives
    - [x] arguments are evaluated
    - [x] returns a term  
    - [x] can be user defined

- Roles  
    - [x] environment capture
    - [x] compositon operations
- Opaque
    - [x] an Operative wrapped around a Role
    - [x] dispatches based on first argument

- Foundational Roles
    - [x] EQ, ORD

- Core Autoboxed Roles
    - [x] core terms can be called as an object
    - [x] Bool
    - [x] Num
    - [x] Str 
    - [x] Ref 
    - [x] Array
    - [x] Hash
    - [x] Cons

- Callable Term Types
    - Applicative
        - [x] Lambda: user defined applicative function
        - [x] Native: native applicative function
    - Operative 
        - [x] FExpr: user defined operative function
        - [x] Native: native operative function
        - [x] Opaque: instance as operative
 
<!----------------------------------------------------------------------------->
## Layer 3: Machines, Tapes & Contexts
<!----------------------------------------------------------------------------->

Layer 3 is the machine which runs this code, and the Context interface which 
provides access to the runtime. 

- Continuation Queue Machine
    - [x] incrementally compiles expressions to continations
    - [x] passes temporary values through local stack in continuation 
    
- Kontinue Terms
    - [x] content addressed 
    * [ ] first-class, exposed in the language
    
- Step until Host & Errors
    - [x] runs until a `Host` continuation is reached, then returns
    - [ ] Errors captured and passed to host to handle
    
- Builtin mechanisms
    - [x] `if`, `while` to control execution
    - [x] `define`, `let` to handle naming things
    - [ ] `defer` to handle resource cleanup on scope exit
    - [ ] `return` for non-local returns
    - [ ] `try/catch` and `throw` for exceptions
    
- Queue as Turing-Tape analogy enforces
    * [x] linearity
    * [x] atomicity of steps
    * [x] correct continuation chaining
    
- Context
    - [x] centralized access to all the things
    * [x] manages tapes and scopes
    
- Tapes
    - [x] basic sequential tape
    - [x] Spliced tape - chains tapes together
    - [ ] Mix tape - pre-emptive quota-based pseudo-parallelism?
 
 - Runtime Refs
    * [x] addressed by Perl refaddr 
    - ContextRef 
        * [x] can compile code
        * [x] provide access to scopes
        * [x] provide access to tapes
        - [ ] access to allocators?
        - [ ] access to code-generator?
        - [ ] access to machine?
        - [ ] access to runtime?
        - [ ] splicing in new tape?  
        - [ ] tape playback? single step?
    - TapeRef 
        * [x] provide access to trace
        * [x] provide access to step count
        - [ ] provide access to current queue?
 
<!----------------------------------------------------------------------------->
## Layer 4: Object System & MOP
<!----------------------------------------------------------------------------->
    
Layer 4 builds upon the previous layers to provide a meta-circular object 
system with a complete MOP. It also uses the Role substrate to provide a
role for each of the core literal terms, and MXCL autoboxes it accordingly.

- Role Creation & Composition
    * [x] summation
    - [ ] difference
    - [ ] excludes/aliases
    - [ ] override
- Object System & MOP
    - [ ] constructing classes & roles 
    - [ ] creating instances
    - [ ] introspection via metaclasses
    - [ ] class/role constructable via metaclasses
 
<!----------------------------------------------------------------------------->
## Layer $n: Capabilities, Channels & Effects
<!----------------------------------------------------------------------------->

Layer $n introduces the Capabilities and Effects. Effects are resources outside
of the Machine, such as a TTY to print and read from. Capabilities are the way 
to manage access to those resources via the execution environment. Channels are 
the primary abstraction for I/O. 

- Effects system 
    - [ ] `Host` continuations trigger effects 
    - [ ] Effects provide access to outside resources
- Capability system 
    - [ ] Composes effects and binds to environment
    - [ ] Composes channels for I/O 
- Channel system
    - [ ] handles all I/O as Terms
    
