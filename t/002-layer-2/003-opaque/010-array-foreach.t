#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Array .foreach: calls f on each element for side effects, returns nil.
# We observe effects by accumulating into a Ref.

my $source = q[
    (diag "basic accumulation")
    (let sum (make-ref 0))
    (+[1 2 3] .foreach (-> (x)
        (sum .set! ((sum .get) + x))))
    (is (sum .get) 6 "... foreach accumulates sum 1+2+3 = 6")

    (diag "all elements visited")
    (let count (make-ref 0))
    (+[10 20 30 40 50] .foreach (-> (x)
        (count .set! ((count .get) + 1))))
    (is (count .get) 5 "... foreach visits all 5 elements")

    (diag "foreach on empty array does nothing")
    (let touched (make-ref 0))
    (+[] .foreach (-> (x)
        (touched .set! 1)))
    (is (touched .get) 0 "... foreach on +[] never calls f")

    (diag "foreach on single element")
    (let seen (make-ref 0))
    (+[42] .foreach (-> (x)
        (seen .set! x)))
    (is (seen .get) 42 "... foreach on single element visits it")

    (diag "foreach visits in order (track last seen)")
    (let last (make-ref 0))
    (+[1 2 3] .foreach (-> (x)
        (last .set! x)))
    (is (last .get) 3 "... foreach visits in order, last = 3")

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
