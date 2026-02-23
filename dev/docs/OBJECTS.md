# OBJECTS

## Syntax Ideas



```
(class ^Point (<EQ>  <SHOW>)
    (object ($self $x $y)
        (define ->x  ()  ($x ->))
        (define ->x! (x) ($x <- x))

        (define ->y  ()  ($y ->))
        (define ->y! (y) ($y <- y))

        (define clear ()
            (do ($self ->x! 0)
                ($self ->y! 0)))    

        (define equal-to (o)
            (and (($x ->) == (o ->x))
                 (($y ->) == (o ->y))))
                 
        (define show ()
            (((("(" ~ $x) ~ ",") ~ $y) ~ ")"))
    )
)

```

## Role operators

-  `A | B` for union
-  `A & B` for intersection
-  `A - B` for difference
-  `A ^ B` for symmetric difference

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
