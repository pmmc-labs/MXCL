#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed method dispatch on Str: (str-term .method ...args)

# --- .uc / .lc / .fc ---

test_mxcl(q[
    (is ("hello" .uc) "HELLO" "... hello.uc = HELLO")
    (is ("HELLO" .lc) "hello" "... HELLO.lc = hello")
    (is ("Hello" .fc) "hello" "... Hello.fc = hello")
]);

# --- .ucfirst / .lcfirst ---

test_mxcl(q[
    (is ("hello" .ucfirst) "Hello" "... hello.ucfirst = Hello")
    (is ("HELLO" .lcfirst) "hELLO" "... HELLO.lcfirst = hELLO")
]);

# --- .length ---

test_mxcl(q[
    (is ("hello" .length) 5   "... hello.length = 5")
    (is (""      .length) 0   "... empty.length = 0")
    (is ("a"     .length) 1   "... a.length = 1")
]);

# --- .index / .rindex ---

test_mxcl(q[
    (is ("hello" .index  "l") 2  "... hello.index(l) = 2")
    (is ("hello" .rindex "l") 3  "... hello.rindex(l) = 3")
    (is ("hello" .index  "x") -1 "... hello.index(x) = -1")
]);

# --- .chomp (build a real newline via chr(10)) ---

test_mxcl(q[
    (let newline (10 .chr))
    (is (("hello" ~ newline) .chomp) "hello" "... chomp removes trailing newline")
    (is ("hello"              .chomp) "hello" "... chomp is no-op without newline")
]);

# --- .hex / .oct ---

test_mxcl(q[
    (is ("ff"   .hex) 255 "... ff.hex = 255")
    (is ("10"   .hex) 16  "... 10.hex = 16")
    (is ("0xff" .hex) 255 "... 0xff.hex = 255")
    (is ("10"   .oct) 8   "... 10.oct = 8")
    (is ("077"  .oct) 63  "... 077.oct = 63")
]);

# --- .split (str .split sep) ---

test_mxcl(q[
    (let parts ("a,b,c" .split ","))
    (is (head parts)               "a" "... split head = a")
    (is (head (tail parts))        "b" "... split second = b")
    (is (head (tail (tail parts))) "c" "... split third = c")
]);

# --- .join called on separator (sep .join list) ---

test_mxcl(q[
    (let parts ("a,b,c" .split ","))
    (is ("," .join parts) "a,b,c" "... join round-trips split")
    (is ("-" .join parts) "a-b-c" "... join with different sep")
]);

done_testing;
