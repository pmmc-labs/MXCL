# TODO

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

## Traits

- add methods to check for state of the trait (resolved, still requires, etc)

- add provenance tracking 
    - flatten a list of all traits that were included (recursively)
    - do NOT include this in the hash
    - figure out the details for Alias/Exclude on this

- does the trait hold a ref to the things it is made from?

### Slots

- turn the Slot interface into something like the Option type
    - add get(), get_or_else() type methods
    
- Slots is where we can slip in JIT stuff
    - we can replace a node with an equivalent compiled node
        - this is where zk proofs could come in handy

- handle Alias, and the other thing 
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


<!----------------------------------------------------------------------------->
