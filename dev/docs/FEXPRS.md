# FEXPRS


```
;; named fexpr
(fexpr my-if (cond if-true if-false) $ctx
    ($ctx in-scope 
        ($ctx conditional cond if-true if-false)))
    
;; anon fexpr
(let (my-if (~> (cond if-true if-false) $ctx
                ($ctx in-scope 
                    ($ctx conditional cond if-true if-false)))))
    
```



```











```
