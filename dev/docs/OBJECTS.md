# OBJECTS

## MOP

- The classic MOP bootstrap
    - Class isa Object
    - Object isa Class
    - Class instance-of Object
- Object/Metaclass system 
    - constructing classes & roles 
    - creating instances
    - introspection via metaclasses
    - class/role construction via metaclasses

## Mutable objects

- using the Ref terms to create mutable objects
- Using `object.become` to change state

## Operatives for ...

- Generics 
    - use operatives to create typed containers (see also - Zig)
- ADTs
    - given ADT definition, generate roles, functions, opagues, etc.
- Class creation
    - declarative syntax sugar for classes, etc. 

```

(class ^Point ($x $y) :does <EQ>

    (define ->x  (p)   ($x ->))
    (define ->x! (p x) ($x <- x))

    (define ->y  (p)   ($y ->))
    (define ->y! (p y) ($y <- y))

    (define clear (p)
        (do ($x <- 0)
            ($y <- 0)))    

    (define equal-to (p o)
        (and (($x ->) == (o ->x))
             (($y ->) == (o ->y))))
)

```
