#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];


my $result = test_mxcl(q[

(define Point (x y)
    (make-opaque
        (<ORD> +
            (make-role
                (let $x (make-ref x))
                (let $y (make-ref y))

                (define ->x  (p)   ($x get))
                (define ->x! (p x) ($x set! x))

                (define ->y  (p)   ($y get))
                (define ->y! (p y) ($y set! y))

                (define clear (p)
                    (do
                        ($x set! 0)
                        ($y set! 0)
                        ()))

                (define == (p o)
                    (and
                        (($x get) == (o ->x))
                        (($y get) == (o ->y))))

                (define > (p o)
                    (and
                        (($x get) > (o ->x))
                        (($y get) > (o ->y))))
            )
        )
    )
)

(let p (Point 10 20))
(let p2 (Point 10 20))

(is (p ->x) 10 "... ->x returns 10")
(is (p ->y) 20 "... ->y returns 20")

(is (p2 ->x) 10 "... p2 ->x returns 10")
(is (p2 ->y) 20 "... p2 ->y returns 20")

(ok (p == p2) "... p and p2 are equal")

(p clear)

(is (p ->x) 0 "... ->x returns 0")
(is (p ->y) 0 "... ->y returns 0")

(ok (p != p2) "... p and p2 are no longer equal")
(ok (p < p2) "... p is less than p2")
(ok (p2 > p) "... p2 is greater than p")

(is (p2 ->x) 10 "... p2 ->x still returns 10")
(is (p2 ->y) 20 "... p2 ->y still returns 20")

(p2 ->x! 0)
(p2 ->y! 0)

(ok (p == p2) "... p and p2 are equal")
(ok (p >= p2) "... p and p2 are gt equal")
(ok (p <= p2) "... p and p2 are lt equal")

]);

diag($result ? $result->stack->pprint : 'UNDEFINED');

done_testing;

__END__
