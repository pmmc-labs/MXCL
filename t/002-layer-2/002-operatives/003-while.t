#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# while: operative that re-evaluates its condition each iteration and runs
# body until the condition becomes false. Mutable state is via Ref.

my $source = q[
    (diag "basic countdown: ref reaches zero")
    (let x (make-ref 10))
    (while ((x .get) > 0)
        (x .set! ((x .get) - 1)))
    (is (x .get) 0 "... countdown from 10 reaches 0")

    (diag "never executes body when condition is initially false")
    (let touched (make-ref 0))
    (while false
        (touched .set! 1))
    (is (touched .get) 0 "... while false: body never executes")

    (diag "body runs exactly n times")
    (let n     (make-ref 5))
    (let count (make-ref 0))
    (while ((n .get) > 0)
        (do
            (count .set! ((count .get) + 1))
            (n .set! ((n .get) - 1))))
    (is (count .get) 5 "... body runs exactly 5 times")

    (diag "accumulate sum via while")
    (let i   (make-ref 1))
    (let sum (make-ref 0))
    (while ((i .get) <= 4)
        (do
            (sum .set! ((sum .get) + (i .get)))
            (i   .set! ((i .get) + 1))))
    (is (sum .get) 10 "... while summing 1..4 = 10")

    (diag "condition references accumulating state")
    (let xr (make-ref 1))
    (while ((xr .get) < 100)
        (xr .set! ((xr .get) * 2)))
    (ok ((xr .get) >= 100) "... x doubled until >= 100")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}
