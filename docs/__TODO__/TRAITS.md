
```
Trait := {
    $name: Symbol,
    %bindings: Map<Symbol, Slot>
}

Slot := Absent
      | Defined(hash)
      | Required            -- abstract, must be provided
      | Conflict(Set<hash>) -- unresolved, multiple providers
      | Excluded            -- explicitly removed
      | Alias(Symbol, hash) -- renamed reference
      
      
Absent ≤ Required ≤ Defined(h) ≤ ...
Absent ≤ Excluded
Conflict ≤ Defined(h)  -- resolution moves you up


Absent ⊔ x         = x
Required ⊔ Required = Required  
Required ⊔ Defined(h) = Defined(h)  -- requirement satisfied
Defined(h1) ⊔ Defined(h2) = if h1 == h2 then Defined(h1)  -- hash-consing!
                              else Conflict({h1, h2})
Excluded ⊔ Defined(h) = Excluded  -- exclusion wins


Ordering rules:
Absent — bottom element, no binding
↑
Required — must be provided
↑
Defined(hash) — has implementation
↑ ← Conflict branches here
Conflict(h₁,h₂) — needs resolution
↑
Resolved — conflict settled
↑
Checked — capability verified

Values only move upward. Each phase advances slots to a higher level. Rollback = stay at the lower level.

```

```

trait Atom {
    nil?,
    isa?   
}

trait Eq {
    ==, !=    
}

trait Ord {
    <=, <, >=, >
}

trait Number does Atom, Eq, Ord {
    +, -, *, /, %,
    abs, neg,
    ceil, floor
}

trait String  does Atom, Eq, Ord {
    ~, 
    subtring, split, 
    index-of, last-index-of, 
    char-art,
}

trait Boolean does Atom, Eq {
    not, and, or
}

trait Tag does Atom, Eq {
    as-string
}

trait Ref does Atom, Eq {
    get, set!
}

trait Array does Atom, Eq {
    at, length, 
    map, grep, 
    join
}

trait Env does Atom, Eq {
    lookup, 
    extend,
}

```
