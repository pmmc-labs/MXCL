#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[

    (diag "lambda? predicate tests")
    (ok (lambda? (lambda (x) x))    "... lambda is lambda")
    (ok (lambda? (lambda (x y) (+ x y))) "... multi-arg lambda is lambda")
    (ok (not (lambda? 42))          "... number is not lambda")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result  = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}

