
use v5.42;
use experimental qw[ class ];

class MXCL::Runtime::Prelude {
    our $BASE_CORE_FUNCTIONS = q[
        (bind eq? (n m) "eq?")

        (bind nil?    (t) "nil?")
        (bind bool?   (t) "bool?")
        (bind num?    (t) "num?")
        (bind str?    (t) "str?")
        (bind sym?    (t) "sym?")
        (bind lambda? (t) "lambda?")
        (bind array?  (t) "array?")
        (bind ref?    (t) "ref?")
        (bind opaque? (t) "opaque?")
        (bind role?   (t) "role?")

        (bind not (n m) "not")
        (bind and (n m) "and")
        (bind or  (n m) "or")

        (bind do    (@)                     "do")
        (bind if    (cond if-true if-false) "if")
        (bind while (cond body)             "while")

        (bind let     (name value) "let")
        (bind define  (name params body) "define")
        (bind require (name) "require")
        (bind with    (role) "with")
        (bind role    (@) "role")

        (bind lambda      (params body) "lambda")
        (bind make-opaque (role)  "make-opaque")
        (bind make-ref    (value) "make-ref")
        (bind make-role   (@)     "make-role")
        (bind make-array  (@)     "make-array")
        (bind make-hash   (@)     "make-hash")
    ];

    our $BASE_ABSTRACT_ROLES = q[

        (role <EQ> ()
            (require ==)
            (define != (n m) (not (n == m))))

        (role <ORD> (with <EQ>)
            (require >)
            (define >= (n m) ((n > m) || (n == m)))
            (define <  (n m) (not ((n > m) || (n == m))))
            (define <= (n m) (not (n > m))))
    ];

    our $BASE_CORE_ROLES = q[

        (role Bool (with <EQ>)
            (bind   == (n m) "Bool::==")
            (define && (n m) (and n m))
            (define || (n m) (or n m)))

        (role Num (with <ORD>)
            (bind == (n m) "Num::==")
            (bind >  (n m) "Num::>")
            (bind +  (n m) "Num::+")
            (bind -  (n m) "Num::-")
            (bind *  (n m) "Num::*")
            (bind /  (n m) "Num::/")
            (bind %  (n m) "Num::%"))

        (role Str (with <ORD>)
            (bind == (n m) "Str::==")
            (bind >  (n m) "Str::>")
            (bind ~  (n m) "Str::~"))

        (role Ref ()
            (bind get  (r)   "Ref::get")
            (bind set! (r v) "Ref::set"))

        (role Array ()
            (bind length (a)   "Array::length")
            (bind at     (a i) "Array::at"))

        (role Hash ()
            (bind length (h)   "Hash::length")
            (bind at     (h k) "Hash::at"))

        (role Role (with <EQ>)
            (define == (r1 r2) (eq? r1 r2)))

    ];


    method source {
        join "\n" =>
        $BASE_CORE_FUNCTIONS,
        $BASE_ABSTRACT_ROLES,
        $BASE_CORE_ROLES,
    }

}
