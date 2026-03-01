#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Ref: mutable cell created with make-ref, accessed with .get and mutated with .set!

my $source = q[
    (diag ".get on initial value")
    (let r (make-ref 42))
    (is (r .get) 42 "... ref.get returns initial value")

    (let r2 (make-ref "hello"))
    (is (r2 .get) "hello" "... ref.get works for strings")

    (diag ".set! then .get")
    (let r3 (make-ref 0))
    (r3 .set! 99)
    (is (r3 .get) 99 "... ref.get returns updated value after set!")

    (diag "multiple mutations")
    (let r4 (make-ref 1))
    (r4 .set! 2)
    (r4 .set! 3)
    (is (r4 .get) 3 "... ref.get returns last value after multiple set!")

    (diag "ref used as counter")
    (let count (make-ref 0))
    (count .set! ((count .get) + 1))
    (count .set! ((count .get) + 1))
    (count .set! ((count .get) + 1))
    (is (count .get) 3 "... ref used as counter reaches 3")

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
