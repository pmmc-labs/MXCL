#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed dispatch on Num: (num-term method ...args)
# Dispatches through the Num role which composes Num-specific methods with ORD and EQ.

my $source = q[
    (diag "arithmetic")
    (is (1  + 2)   3  "... 1 + 2 = 3")
    (is (10 - 3)   7  "... 10 - 3 = 7")
    (is (3  * 4)  12  "... 3 * 4 = 12")
    (is (10 / 2)   5  "... 10 / 2 = 5")
    (is (10 % 3)   1  "... 10 % 3 = 1")
    (is (0  + 0)   0  "... 0 + 0 = 0")
    (is (5  - 5)   0  "... 5 - 5 = 0")
    (is (7  * 0)   0  "... 7 * 0 = 0")

    (diag "float arithmetic")
    (is (1.5 + 2.5) 4    "... 1.5 + 2.5 = 4")
    (is (7 / 2)     3.5  "... 7 / 2 = 3.5")
    (is (1 / 4)     0.25 "... 1 / 4 = 0.25")

    (diag "mixed-sign arithmetic")
    (is (-5 + 10)  5  "... -5 + 10 = 5")
    (is (-3 * 4)  -12 "... -3 * 4 = -12")
    (is (-3 * -4) 12  "... -3 * -4 = 12")

    (diag "equality")
    (ok      (5 == 5) "... 5 == 5")
    (ok (not (5 == 4)) "... not 5 == 4")
    (ok      (0 == 0) "... 0 == 0")

    (diag "inequality (derived from EQ via !=)")
    (ok      (5 != 4) "... 5 != 4")
    (ok (not (5 != 5)) "... not 5 != 5")

    (diag "ordering: > (primitive)")
    (ok      (5 > 4)  "... 5 > 4")
    (ok (not (4 > 5)) "... not 4 > 5")
    (ok (not (5 > 5)) "... not 5 > 5")

    (diag "ordering: < (derived from ORD)")
    (ok      (4 < 5)  "... 4 < 5")
    (ok (not (5 < 4)) "... not 5 < 4")
    (ok (not (5 < 5)) "... not 5 < 5")

    (diag "ordering: >= and <= (derived from ORD)")
    (ok (5 >= 5)  "... 5 >= 5")
    (ok (5 >= 4)  "... 5 >= 4")
    (ok (not (4 >= 5)) "... not 4 >= 5")

    (ok (5 <= 5)  "... 5 <= 5")
    (ok (4 <= 5)  "... 4 <= 5")
    (ok (not (5 <= 4)) "... not 5 <= 4")

    (diag "float comparison")
    (ok (0.1 > 0)   "... 0.1 > 0")
    (ok (0 < 0.1)   "... 0 < 0.1")

    (diag "cross-type coercion")
    (ok (true  == 1) "... true == 1 (coercion)")
    (ok (false == 0) "... false == 0 (coercion)")

    (diag "nested / chained arithmetic")
    (is ((2 + 3) * 4) 20  "... (2+3)*4 = 20")
    (is ((10 - 4) / 2) 3  "... (10-4)/2 = 3")
    (is ((3 * 3) + (4 * 4)) 25 "... 3^2 + 4^2 = 25")

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
