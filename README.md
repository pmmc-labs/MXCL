
# PMMC Labs

## TODO 


- the old Machine, formerly a Strand, should just be the capabilities object
    - the distinction didn't make enough sense to justify another layer in the hierarchy
    - and it can be done horizontally with composition
    
- create a new layer called Runtime
    - it is capabilities + machine/strand merged
    - keep it minimal for now, just enough to bootstrap things
        - and later ...
        - move the timers stuff into it's own object
            - maybe the watchers too
        - make Runtime use those objects

- once we have the Runtime 
    - we can set up our root env, and our class hierachy stable reference
    - we create the root env
            
    - bootstrap the basic MOP
        - make Object and Class knot tied
        - stick it in the heirarchy
    
    - implement the full MOP
        - it is basically sophisticated environment construction mechanism sitting on top of the simple opaque objects
