#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];


my $result = test_mxcl(q[

(define Point (x y)
    (make-opaque
        (<EQ> + (make-role
            (let $x (make-ref x))
            (let $y (make-ref y))

            (define == (p o)
                (and
                    (($x get) == (o get-x))
                    (($y get) == (o get-y))
                )
            )

            (define get-x  (p)   ($x get))
            (define set-x! (p x) ($x set! x))

            (define get-y  (p)   ($y get))
            (define set-y! (p y) ($y set! y))

            (define clear (p)
                (do
                    ($x set! 0)
                    ($y set! 0)
                    ()))
        ))
    )
)

(let p (Point 10 20))
(let p2 (Point 10 20))

(is (p get-x) 10 "... get-x returns 10")
(is (p get-y) 20 "... get-y returns 20")

(is (p2 get-x) 10 "... p2 get-x returns 10")
(is (p2 get-y) 20 "... p2 get-y returns 20")

(ok (p == p2) "... p and p2 are equal")

(p clear)

(is (p get-x) 0 "... get-x returns 0")
(is (p get-y) 0 "... get-y returns 0")

(ok (p != p2) "... p and p2 are no longer equal")

(is (p2 get-x) 10 "... p2 get-x still returns 10")
(is (p2 get-y) 20 "... p2 get-y still returns 20")

(p2 set-x! 0)
(p2 set-y! 0)

(ok (p == p2) "... p and p2 are equal")

]);

diag($result ? $result->stack->pprint : 'UNDEFINED');

done_testing;

__END__
