#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed method dispatch on Num: (num-term .method ...args)

# --- .abs ---

test_mxcl(q[
    (is (5   .abs) 5  "... 5.abs = 5")
    (is (-5  .abs) 5  "... -5.abs = 5")
    (is (0   .abs) 0  "... 0.abs = 0")
]);

# --- .int (truncation towards zero) ---

test_mxcl(q[
    (is (3.9  .int) 3  "... 3.9.int = 3")
    (is (3.1  .int) 3  "... 3.1.int = 3")
    (is (-3.9 .int) -3 "... -3.9.int = -3")
    (is (0.9  .int) 0  "... 0.9.int = 0")
]);

# --- .sqrt ---

test_mxcl(q[
    (is (4   .sqrt) 2.0 "... 4.sqrt = 2.0")
    (is (9   .sqrt) 3.0 "... 9.sqrt = 3.0")
    (is (0   .sqrt) 0.0 "... 0.sqrt = 0.0")
    (is (1   .sqrt) 1.0 "... 1.sqrt = 1.0")
]);

# --- .chr (codepoint to character) ---

test_mxcl(q[
    (is (65 .chr) "A" "... 65.chr = A")
    (is (97 .chr) "a" "... 97.chr = a")
    (is (48 .chr) "0" "... 48.chr = 0")
]);

# --- .cos and .sin (basic spot checks) ---

test_mxcl(q[
    (is (0 .cos) 1.0 "... cos(0) = 1.0")
    (is (0 .sin) 0.0 "... sin(0) = 0.0")
]);

done_testing;
