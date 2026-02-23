


── ARENA ───────────────────────────────────────────────────────────────────────
   alive : 1209
    hits : 480
  misses : 729



### │ Types               │
────┼─────────────────────┼─────────────────────────────────────────────────────
367 │ Cons                │       
206 │ Sym                 │       
140 │ Return              │       
 80 │ Apply::Expr         │       
 76 │ Slot::Defined       │       
 54 │ Eval::Rest          │       
 44 │ Apply::Applicative  │       
 35 │ Role                │       
 34 │ Native::Applicative │       
 32 │ Eval::Head          │       
 25 │ Eval::Expr          │       
 24 │ Scope::Leave        │       
 14 │ Num                 │       
 14 │ Native::Operative   │       
 12 │ Scope::Enter        │       
 12 │ IfElse              │       
 11 │ Discard             │       
 10 │ Apply::Operative    │       
  7 │ Define              │       
  3 │ Slot::Required      │       
  2 │ Bool                │       
  2 │ Tag                 │       
  2 │ Host                │       
  1 │ Lambda              │       
  1 │ Nil                 │       
  1 │ Str                 │       














```
0b1e0e1e │ Int    10
7564b7e3 │ Sym    "Foo"
1edc5815 │ Cons   ( #7564b7e3 #0b1e0e1e )
0818ff85 │ Lambda ( #b77723a5 #f13d876f )
bcac42de │ Str    "Hello World"
```




```
 > lambda      │ Lambda   │ 0b1e0e1e │ 001 |        
    > name     │ Sym      │ 7564b7e3 │ 001 |    
    > params   │ Cons     │ 1edc5815 │ 001 |        
        > x    │ Sym      │ 0818ff85 │ 001 | Num                 
        > y    │ Sym      │ bcac42de │ 001 | Num                 
    > body     │ Cons     │ 12acd310 │ 001 |        
        > x    │ Sym      │ 991d224d │ 001 | Box[Num]                
        > +    │ Sym      │ 01ae4300 │ 001 | Native[Num,Num;Num]                    
        > y    │ Sym      │ 236d0f7c │ 001 | Num       
    > env      │ Scope    │ b22a467a │ 001 |        
            
```

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ SCOPE: { foo, bar } + Base                                                     564b7e3a│
├───┬──────────────────────┬────────────────────────────────────────────────────┬────────┤
│002│ foo                  │ "FOO"                                              │e6269c9f│
│002│ bar                  │ "BAR"                                              │a344ea9e│
├───┼──────────────────────┼────────────────────────────────────────────────────┼────────┤
│001│ while                │ native:[while]                                     │0b1e0e1e│
│001│ or                   │ native:[or]                                        │7564b7e3│
│001│ opaque?              │ native:[opaque?]                                   │1edc5815│
│001│ lambda               │ native:[lambda]                                    │0818ff85│
│001│ sym?                 │ native:[sym?]                                      │bcac42de│
│001│ bool?                │ native:[bool?]                                     │12acd310│
│001│ do                   │ native:[do]                                        │991d224d│
│001│ and                  │ native:[and]                                       │01ae4300│
│001│ num?                 │ native:[num?]                                      │236d0f7c│
│001│ nil?                 │ native:[nil?]                                      │b22a467a│
│001│ define               │ native:[define]                                    │d41625c5│
│001│ array?               │ native:[array?]                                    │ef7e482a│
│001│ make-array           │ native:[make-array]                                │698a74ad│
│001│ lambda?              │ native:[lambda?]                                   │f849accd│
│001│ str?                 │ native:[str?]                                      │b77723a5│
│001│ ref?                 │ native:[ref?]                                      │d2c924ae│
│001│ eq?                  │ native:[eq?]                                       │b9c18bd0│
├───┼──────────────────────┼────────────────────────────────────────────────────┼────────┤
│001│ MXCL::Term::Bool     │ Bool:EQ{ !=, &&, ==, || }                          │f13d876f│
│001│ MXCL::Term::Str      │ Str:EQ::ORD{ !=, <, <=, ==, >, >=, ~ }             │3a2a2c4f│
│001│ MXCL::Term::Num      │ Num:EQ::ORD{ !=, %, *, +, -, /, <, <=, ==, >, >= } │084c0e0b│
└───┴──────────────────────┴────────────────────────────────────────────────────┴────────┘
```
