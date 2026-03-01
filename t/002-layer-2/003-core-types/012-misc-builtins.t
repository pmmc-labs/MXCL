#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Builtin list functions: map, grep, reduce -- operating on quoted cons lists.
# These are purely recursive MXCL-defined functions from the Prelude.

my $source = q[

    (diag "testing join function")
    (is (join ", " (list 10 20)) "10, 20" "... got the expected string")
    (is (join ", " +[ 10 20 ]) "10, 20" "... got the expected string")
    (is (join ", " 10) "10" "... got the expected string")
    (is (join ", " ()) "" "... got the expected string")

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
