#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "inner scope can see bindings from the outer scope")
    (let x 1)
    (do
        (is x 1 "... inner scope sees outer x = 1"))

    (diag "bindings made inside a do block are visible to later exprs in the same block")
    (do
        (let y 99)
        (is y 99 "... y visible to later exprs within the same do block"))

    (diag "multiple nested do blocks each see their parent scope")
    (let outer 10)
    (do
        (let mid 20)
        (do
            (is outer 10 "... inner-inner sees outer = 10")
            (is mid   20 "... inner-inner sees mid = 20")))

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
