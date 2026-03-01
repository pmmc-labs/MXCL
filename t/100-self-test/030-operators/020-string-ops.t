#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[

    (diag "String concatenation tests (infix)")
    (is ("hello" ~  " world")    "hello world"   "... concatenate two strings")
    (is ("foo" ~  "bar")         "foobar"        "... concatenate without space")
    (is (""  ~ "test")           "test"          "... concatenate with empty string")
    (is ("test" ~  "")           "test"          "... concatenate to empty string")
    (is (""  ~ "")               ""              "... concatenate two empty strings")
    (is ("a" ~  ("b" ~ "c"))     "abc"           "... nested concatenation")

    (diag "String concatenation with coercion (infix)")
    (is ("count: " ~ 42)        "count: 42"     "... concatenate string with number")
    (is ("bool: " ~ true)       "bool: true"    "... concatenate string with bool")

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

