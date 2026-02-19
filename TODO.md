<!----------------------------------------------------------------------------->
# TODO
<!----------------------------------------------------------------------------->

Lot's of TODOs, XXXs and FIXMEs in the source as well.

<!----------------------------------------------------------------------------->
## Scopes
<!----------------------------------------------------------------------------->

- Scope composition needs refinement
    - add Required methods for params
    - add Required methods for recursive calls
    - if we traverse the tree we can find free variables
        - and choose to not add recursive name if not needed
        - and maybe only include the Defined values that are needed?
    - we can just deal with Conflicts as shadows
        - or we could Exclude the params/recursive names from 
          the parent before we compose them, to ensure no conflicts
            - that said, I kinda like the Conflict as Override thing
    
- Machine needs to handle things other than Defined in composed Scopes
    - Conflicts 
        - these hold both values
            - send all reads to the right one
        - this keeps the trait composition clean
    - Absent
        - should probably throw an error
    - Required
        - unsatisfied requirements are bad

<!----------------------------------------------------------------------------->
## Roles
<!----------------------------------------------------------------------------->

- add methods to check for state of the trait (resolved, still requires, etc)

- add provenance tracking 
    - flatten a list of all traits that were included (recursively)
    - do NOT include this in the hash
    - figure out the details for Alias/Exclude on this

### Slots

- turn the Slot interface into something like the Option type
    - add get(), get_or_else() type methods
    
- Slots is where we can slip in JIT stuff
    - we can replace a node with an equivalent compiled node
        - this is where zk proofs could come in handy

- maybe do Alias, Exclude??

<!----------------------------------------------------------------------------->
## Context
<!----------------------------------------------------------------------------->

- add Builder to construct Kontinue queues with

- consider adding the queue into this
    - it would make a single point to serialize
    - and one place to have serialization logic
        - even if we allow seperate serialization

- think about commits, etc. 

<!----------------------------------------------------------------------------->
## Arena
<!----------------------------------------------------------------------------->
    
- add a way to walk the hashes

- fix generation tracking data
    - it was the old stats collection, repurposed
    - works for now, but needs improvement

<!----------------------------------------------------------------------------->
## Machine
<!----------------------------------------------------------------------------->

- Applicatives should get the ctx variable as the first arg
    - this will allow it to do allocation, etc. 
    - the lifted native subs should never see it

- What is the Eval::TOS for?
    - I can't find why/where we added it for
    
- Add Throw/Catch back in

<!----------------------------------------------------------------------------->
## Natives
<!----------------------------------------------------------------------------->

- Currently we support a very sloppy varargs 
    - this needs fixing, and perhaps a bit of a "signature spec" as well

<!----------------------------------------------------------------------------->
## Parser
<!----------------------------------------------------------------------------->

- switch the sugar around a bit
    - @[] becomes +[]
    - %{} becomes +{}
    - {} stays as is
    - remove the tuple parsing
    
<!----------------------------------------------------------------------------->    
## Compiler
<!----------------------------------------------------------------------------->

- handle the parser changes

<!----------------------------------------------------------------------------->
## Terms
<!----------------------------------------------------------------------------->

- standardize on `->unbox` name for all unboxing methods

<!----------------------------------------------------------------------------->

