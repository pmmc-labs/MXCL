#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed dispatch on Str: (str-term method ...args)
# Dispatches through the Str role which composes Str-specific methods with ORD and EQ.

my $source = q[
    (diag "concatenation (~)")
    (is ("hello" ~ " world") "hello world" "... string concatenation")
    (is ("" ~ "x")           "x"           "... concat empty prefix")
    (is ("x" ~ "")           "x"           "... concat empty suffix")
    (is ("a" ~ "b")          "ab"          "... concat two chars")

    (diag "chained concatenation (nested, since ~ is binary)")
    (is (("a" ~ "b") ~ "c") "abc"    "... left-nested concat: (a~b)~c = abc")
    (is ("a" ~ ("b" ~ "c")) "abc"    "... right-nested concat: a~(b~c) = abc")
    (is (("He" ~ "ll") ~ "o") "Hello" "... (He~ll)~o = Hello")

    (diag "concatenation with coercion")
    (is ("count: " ~ 42)   "count: 42"   "... concatenate string with number")
    (is ("bool: "  ~ true) "bool: true"  "... concatenate string with bool")

    (diag "equality")
    (ok      ("abc" == "abc") "... abc == abc")
    (ok (not ("abc" == "def")) "... not abc == def")
    (ok      ("" == "")       "... empty string == empty string")

    (diag "inequality (derived from EQ via !=)")
    (ok      ("abc" != "def") "... abc != def")
    (ok (not ("abc" != "abc")) "... not abc != abc")

    (diag "lexicographic ordering: > (primitive)")
    (ok      ("b" > "a") "... b > a")
    (ok (not ("a" > "b")) "... not a > b")
    (ok (not ("a" > "a")) "... not a > a")

    (diag "lexicographic ordering: < (derived from ORD)")
    (ok      ("a" < "b") "... a < b")
    (ok (not ("b" < "a")) "... not b < a")
    (ok (not ("a" < "a")) "... not a < a")

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
