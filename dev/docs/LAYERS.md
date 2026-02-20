
# The Layers of MXCL

This document provides a brief summary of the layers of MXCL and how they build
upon one another. 

> LEGEND:
> [ ] = not started
> [-] = WIP
> [x] = done

<!----------------------------------------------------------------------------->
## Layer 0: Term Structure
<!----------------------------------------------------------------------------->

Layer 0 defines the structure of the terms used within MXCL. This layer is 
purely about data, albiet code represented as data.

[x] Homoiconicity
    [x] code is data
    [x] the code is built entirely from S-Expressions
[x] Zero Keywords
    [x] there are no special forms in the `Parser`
    [x] the `Compiler` produces core terms only
    [x] semantics come from the environment, not the parser
[x] Content-Addressing
    [x] all terms are hash-consed by their contents
    [x] structural identify is hash identity
    [x] terms are interned and deduplicated
[-] Term metadata
    [-] not included in the hashing
    [x] Arena generation
    [ ] related Token/Compound(s)

<!----------------------------------------------------------------------------->
## Layer 1: Role Substrate
<!----------------------------------------------------------------------------->

Layer 1 provides a substrate for Role composition using terms defined in 
Layer 0. 

[x] Communitivity & Associativity
    [x] role composition is order independent
[-] Role Operations
    [x] Union: composing two roles together
    [x] Conflicts: detecting conflicts during composition
    [-] Resolution: explicit override (forces an ordering)

<!----------------------------------------------------------------------------->
## Layer 2: Callables, Environments & Scopes
<!----------------------------------------------------------------------------->

Layer 2 provides a set of callable terms, each of which is either an 
Operative (args are not evaluted) or Applicative (args are evaluated). 
These can be used as functions in the environment, or methods of a Role. 

This layer also provides the Environment and Scope abstractions using roles
as the name lookup mechanism, and the environment operations are implemented
as role operations.

[x] Environments & Scopes
    [x] deriving scopes
    [x] name resolution
    [x] fixed-point for recursion
[x] Operatives
    [x] arguments are unevaluated
    [x] returns a list of continuation objects
    [ ] can be user defined
[x] Applicatives
    [x] arguments are evaluated
    [x] returns a term  
    [x] can be user defined
[x] Opaque
    [x] an Operative wrapped around a Role
    [x] dispatches based on first argument
    
[-] Callable Terms
    [x] Applicative
        [x] Lambda: user defined applicative function
        [x] Native: native applicative function
    [-] Operative 
        [-] FExpr: user defined operative function
        [x] Native: native operative function
        [x] Opaque: instance as operative
 
<!----------------------------------------------------------------------------->
## Layer 3: MOP
<!----------------------------------------------------------------------------->
    
Layer 3 builds upon the previous layers to provide a meta-circular object 
system with a complete MOP. It also uses the Role substrate to provide a
role for each of the core literal terms, and MXCL autoboxes it accordingly.

[x] Foundational Roles
    [x] EQ, ORD
[-] Autoboxed core Terms
    [x] core terms can be called as an object
    [x] Bool
    [-] Num
    [-] Str 
    [x] Ref 
    [-] Array
    [-] Hash

[ ] The classic MOP bootstrap
    [ ] Class isa Object
    [ ] Object isa Class
    [ ] Class instance-of Object
[ ] Object/Metaclass system 
    [ ] constructing classes & roles 
    [ ] creating instances
    [ ] introspection via metaclasses
    [ ] class/role construction via metaclasses

[-] Mutable objects
    [-] using the Ref terms to create mutable objects

[ ] Operatives for Generics?

<!----------------------------------------------------------------------------->
## Layer 4: Machine & Contexts
<!----------------------------------------------------------------------------->

Layer 4 is the machine which runs this code, and the Context interface which 
provides access to the runtime. 

[x] Continuation Queue Machine
    [x] incrementally compiles expressions to continations
    [x] passes temporary values through local stack in continuation
    [-] Queue as Turing-Tape analogy
        [-] linearity
        [-] atomicity of steps
        [-] correct continuation chaining 
[-] Kontinue Terms
    [ ] first-class, exposed in the language
    [x] content addressed 
[x] Step until Host
    [x] runs until a `Host` continuation is reaches, then returns
[-] Builtin mechanisms
    [-] `defer` to handle resource cleanup on scope exit
    [ ] `return` for non-local returns
    [-] `try/catch` and `throw` for exceptions

[ ] Objects as Schedulers
    [ ] object stores continutations for later execution
    [ ] Generators, etc. 
 
<!----------------------------------------------------------------------------->
## Layer 5: Capabilities, Channels & Effects
<!----------------------------------------------------------------------------->

Layer 5 introduces the Capabilities and Effects. Effects are resources outside
of the Machine, such as a TTY to print and read from. Capabilities are the way 
to manage access to those resources via the execution environment. Channels are 
the primary abstraction for I/O. 

[ ] Effects system 
    [ ] `Host` continuations trigger effects 
    [ ] Effects provide access to outside resources
[ ] Capability system 
    [ ] Composes effects and binds to environment
    [ ] Composes channels for I/O 
[ ] Channel system
    [ ] handles all I/O as Terms
    
<!----------------------------------------------------------------------------->
## Layer 6: Concurrency, Strands & Actors
<!----------------------------------------------------------------------------->
    
Layer 6 is where we add concurrency by introducing the Strand abstraction. 
Strands are capable of running multiple machines concurrently. It uses the 
capabilities system to construct machines and any effects they require. 

[ ] Concurrency
    [ ] Runs machines cooperatively (yield at `Host` boundary)
    [ ] Runs machines pre-emptively (w/ step quota)
    [ ] Timers to sleep/pause strands
    [ ] Watchers to notify when child strands exit
    [ ] continutions sent to another strand and returned

The Actor System needs to be designed, but some questions are:

- Mailboxes managed via Effects?
- Mailboxes as Channels?
- Fully Object-Oriented?
- Promises? Futures?
- Where do continuations play a role?
- What about content-addressing?

    
    
    
    
    
    
    
    
    
    
    
    
