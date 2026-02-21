# Tapes

Machines run "Tapes", which are an abstraction around the continuation queue, 
and can be used in a number of ways. 
    
## Code Loader/Sequencer

- Spliced Tape : Concatenates one or more tapes together
    - prelude inclusion
    - module loading    
    
## Concurrency mechanism

- "Mix" tapes : preemptive quota-based interleaving of N tapes 
    - Homogeninous execution - same code, different data
        - parallelizing `for` loops

- Backup Tapes : FP style "apply to all" functional composition `(@f . @g)` 
    - Heterogenious execution - different code, different data
        
- Tree Tapes - Tape as scheduler and supervisor
    - Tapes can have child tapes, which inherit quotas, etc. 
    - Tapes can "supervise" child tapes
    - Tree structure can be static or dynamic
    
## Execution receipt 

- Explicitly not a "proof"     

- The execution trace can be hashed to provide a receipt
    - Hash should include source code, env, MXCL version, etc. 
