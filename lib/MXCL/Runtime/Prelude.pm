
use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Prelude {

    # requires `bind` operative

    our $BASE_CORE_FUNCTIONS = q[
        (bind eq? (n m) ...)

        (bind nil?    (t) ...)
        (bind bool?   (t) ...)
        (bind num?    (t) ...)
        (bind str?    (t) ...)
        (bind sym?    (t) ...)
        (bind lambda? (t) ...)
        (bind array?  (t) ...)
        (bind ref?    (t) ...)
        (bind opaque? (t) ...)
        (bind role?   (t) ...)

        (bind not (n m) ...)
        (bind and (n m) ...)
        (bind or  (n m) ...)

        (bind do    (@) ...)
        (bind if    (cond if-true if-false) ...)
        (bind while (cond body) ...)

        (bind let    (name value) ...)
        (bind define (name params body) ...)
        (bind role   (@) ...)

        (bind lambda      (params body) ...)
        (bind make-opaque (role)  ...)
        (bind make-ref    (value) ...)
        (bind make-role   (@) ...)
        (bind make-array  (@) ...)
        (bind make-hash   (@) ...)
    ];

    # requires `bind`, 'define', `requires`

    our $BASE_ABSTRACT_ROLES = q[

        (role <EQ>
            (requires ==)
            (define != (n m) (not (n == m))))

        (role <ORD> (does <EQ>)
            (requires >)
            (define >= (n m) ((n > m) || (n == m)))
            (define <  (n m) (not ((n > m) || (n == m))))
            (define <= (n m) (not (n > m))))
    ];

    our $BASE_CORE_ROLES = q[

        (role Bool (does <EQ>)
            (bind   == (n m) ...)
            (define && (n m) (and n m))
            (define || (n m) (or n m)))

        (role Num (does <ORD>)
            (bind == (n m) ...)
            (bind >  (n m) ...)
            (bind +  (n m) ...)
            (bind -  (n m) ...)
            (bind *  (n m) ...)
            (bind /  (n m) ...)
            (bind %  (n m) ...))

        (role Str (does <ORD>)
            (bind == (n m) ...)
            (bind >  (n m) ...)
            (bind ~  (n m) ...))

        (role Ref
            (bind get  (r)   ...)
            (bind set! (r v) ...))

        (role Array
            (bind length (a)   ...)
            (bind at     (a i) ...))

        (role Hash
            (bind length (h)   ...)
            (bind at     (h k) ...))

        (role Role (does <EQ>)
            (define == (r1 r2) (eq? r1 r2))
            (bind   +  (r1 r2) ...))

    ];


}
