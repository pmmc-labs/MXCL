#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];


my $result = test_mxcl(q[

(define Point (x y)
    (make-opaque
        (make-array
            (make-ref x)
            (make-ref y)
        )
        (make-role
            (define get-x (p) ((p at 0) get))
            (define get-y (p) ((p at 1) get))
            (define clear (p)
                (do
                    ((p at 0) set! 0)
                    ((p at 1) set! 0)
                    ()))
        )
    )
)

(let p (Point 10 20))

(is (p get-x) 10 "... get-x returns 10")
(is (p get-y) 20 "... get-y returns 20")

(p clear)

(is (p get-x) 0 "... get-x returns 0")
(is (p get-y) 0 "... get-y returns 0")

]);

diag($result ? $result->stack->pprint : 'UNDEFINED');

done_testing;

__END__
