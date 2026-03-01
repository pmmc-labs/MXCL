#!perl

use v5.42;

use Test::More;
use MXCL::Context;

my $source = q[
    (diag "do sequences expressions; later exprs see names bound by earlier ones")
    (do
        (let a 1)
        (let b 2)
        (is a 1 "... a visible to later exprs in do block")
        (is b 2 "... b visible to later exprs in do block"))

    (diag "a function defined inside do is callable within the same do block")
    (do
        (define square (x) (x * x))
        (is (square 4) 16 "... square defined and callable within do")
        (is (square 7) 49 "... square 7 = 49"))

    (diag "nested do blocks compose correctly")
    (let outer 10)
    (do
        (let mid 20)
        (do
            (let inner 30)
            (is (outer + mid)   30 "... outer + mid = 30")
            (is (mid + inner)   50 "... mid + inner = 50")
            (is (outer + inner) 40 "... outer + inner = 40")))

    (diag "do passes the result of the last expression upward")
    (is (do (let tmp 41) (tmp + 1)) 42
        "... do returns the value of its last expression")

    (diag "do with simple value sequences")
    (is (do 1 2 3)                  3 "... do returns last value")
    (is (do (1 + 1) (2 + 2) (3 + 3)) 6 "... do evaluates all, returns last")

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
