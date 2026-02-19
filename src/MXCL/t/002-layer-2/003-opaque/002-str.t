#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed dispatch on Str: (str-term method ...args)
# Dispatches through the Str role which composes Str-specific methods with ORD and EQ.

# --- concatenation (~) ---

test_mxcl(q[
    (is ("hello" ~ " world") "hello world" "... string concatenation")
    (is ("" ~ "x")           "x"           "... concat empty prefix")
    (is ("x" ~ "")           "x"           "... concat empty suffix")
    (is ("a" ~ "b")          "ab"          "... concat two chars")
]);

# --- chained concatenation (nested, since ~ is binary) ---

test_mxcl(q[
    (is (("a" ~ "b") ~ "c") "abc"    "... left-nested concat: (a~b)~c = abc")
    (is ("a" ~ ("b" ~ "c")) "abc"    "... right-nested concat: a~(b~c) = abc")
    (is (("He" ~ "ll") ~ "o") "Hello" "... (He~ll)~o = Hello")
]);

# --- equality ---

test_mxcl(q[
    (ok      ("abc" == "abc") "... abc == abc")
    (ok (not ("abc" == "def")) "... not abc == def")
    (ok      ("" == "")       "... empty string == empty string")
]);

# --- inequality (derived from EQ via !=) ---

test_mxcl(q[
    (ok      ("abc" != "def") "... abc != def")
    (ok (not ("abc" != "abc")) "... not abc != abc")
]);

# --- lexicographic ordering: > (primitive) ---

test_mxcl(q[
    (ok      ("b" > "a") "... b > a")
    (ok (not ("a" > "b")) "... not a > b")
    (ok (not ("a" > "a")) "... not a > a")
]);

# --- lexicographic ordering: < (derived from ORD as "not (n > m || n == m)") ---

test_mxcl(q[
    (ok      ("a" < "b") "... a < b")
    (ok (not ("b" < "a")) "... not b < a")
    (ok (not ("a" < "a")) "... not a < a")
]);

done_testing;
