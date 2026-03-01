#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed method dispatch on Num: (num-term .method ...args)

my $source = q[
    (diag ".abs")
    (is (5   .abs) 5  "... 5.abs = 5")
    (is (-5  .abs) 5  "... -5.abs = 5")
    (is (0   .abs) 0  "... 0.abs = 0")

    (diag ".int (truncation towards zero)")
    (is (3.9  .int) 3  "... 3.9.int = 3")
    (is (3.1  .int) 3  "... 3.1.int = 3")
    (is (-3.9 .int) -3 "... -3.9.int = -3")
    (is (0.9  .int) 0  "... 0.9.int = 0")

    (diag ".sqrt")
    (is (4   .sqrt) 2.0 "... 4.sqrt = 2.0")
    (is (9   .sqrt) 3.0 "... 9.sqrt = 3.0")
    (is (0   .sqrt) 0.0 "... 0.sqrt = 0.0")
    (is (1   .sqrt) 1.0 "... 1.sqrt = 1.0")

    (diag ".chr (codepoint to character)")
    (is (65 .chr) "A" "... 65.chr = A")
    (is (97 .chr) "a" "... 97.chr = a")
    (is (48 .chr) "0" "... 48.chr = 0")

    (diag ".cos and .sin (basic spot checks)")
    (is (0 .cos) 1.0 "... cos(0) = 1.0")
    (is (0 .sin) 0.0 "... sin(0) = 0.0")

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
