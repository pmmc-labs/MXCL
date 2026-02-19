# TODO

<!----------------------------------------------------------------------------->

## Scopes

- Scope composition needs refinement too
    - add Required methods for params
    - add Required methods for recursive calls
    - if we traverse the tree we can find free variables
        - and choose to not add recursive name if not needed
        - and maybe only include the Defined values that are needed?
    - we can just deal with Conflicts as shadows
        - or we could Exclude the params/recursive names from 
          the parent before we compose them, to ensure no conflicts
            - that said, I kinda like the Conflict as Override thing
    - there can be no Absent methods at this point
    - and Alias does not really make a lot of sense
    
- Machine needs to handle things other than Defined in composed Scopes
    - Conflicts 
        - these hold both values
            - send all reads to the right one
        - this keeps the trait composition clean
    - Absent
        - should probably throw an error
    - Required
        - unsatisfied requirements are bad
    - Excluded
    - Alias 
        - not sure these makes a lot of sense here
            - and would be unlikely to be returned from Lookup
            - as they would have already been resolved

<!----------------------------------------------------------------------------->

## Traits

- Trait composition is hackish at best for now
    - only does union
    - need difference, etc. 

- lookup() should return Absent if it finds nothing

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

- handle Alias, Exclude and the other thing 
    - see TODOs

<!----------------------------------------------------------------------------->

## Context

- add Builder to construct Kontinue queues with

- consider adding the queue into this
    - it would make a single point to serialize
    - and one place to have serialization logic
        - even if we allow seperate serialization

- think about commits, etc. 

<!----------------------------------------------------------------------------->

## Arena
    
- add a way to walk the hashes

- fix generation tracking data
    - it was the old stats collection, repurposed
    - works for now, but needs improvement

<!----------------------------------------------------------------------------->

## Machine

- Applicatives should get the ctx variable as the first arg
    - this will allow it to do allocation, etc. 
    - the lifted native subs should never see it

- What is the Eval::TOS for?
    - I can't find why/where we added it for
    
- Need to think about a Drop-Stack/End-Statement kontinue
    - see the `do` builtin for a comment explaining 

<!----------------------------------------------------------------------------->

## Natives

- Currently we support a very sloppy varargs for the `do` builtin
    - this needs fixing, and perhaps a bit of a "signature spec" as well


<!----------------------------------------------------------------------------->

## Parser

- strip comments
- switch the sugar around a bit
    - @[] becomes +[]
    - %{} becomes +{}
    - {} stays as is
    - remove the tuple parsing
    
- add generation metadata 
    - see Arena TODO below
    
<!----------------------------------------------------------------------------->    
    
## Compiler

- handle the parser changes

<!----------------------------------------------------------------------------->

## Terms

- Remove all the Tuple references, we have immutable Arrays
- Remove all the Pair references, we don't need them
- Create a Hash term

- standardize on `->unbox` name for all unboxing methods

<!----------------------------------------------------------------------------->

