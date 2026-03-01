#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Array .map method and -> (lambda alias) syntax.
# .map returns a new Array of the same length with f applied to each element.

my $source = q[
    (diag "-> is an alias for lambda")
    (let double (-> (n) (n * 2)))
    (is (double 3)  6  "... -> lambda: double 3 = 6")
    (is (double 0)  0  "... -> lambda: double 0 = 0")
    (is (double -4) -8 "... -> lambda: double -4 = -8")

    (diag "single-dimensional .map")
    (let a  +[1 2 3])
    (let r  (a .map (-> (n) (n * 2))))
    (is (r .length) 3  "... map preserves length")
    (is (r .at 0)   2  "... map[0] = 2")
    (is (r .at 1)   4  "... map[1] = 4")
    (is (r .at 2)   6  "... map[2] = 6")

    (diag ".map with string transformation")
    (let a2 +["hello" "world"])
    (let r2 (a2 .map (-> (s) (s .uc))))
    (is (r2 .at 0) "HELLO" "... map .uc [0] = HELLO")
    (is (r2 .at 1) "WORLD" "... map .uc [1] = WORLD")

    (diag ".map identity: result equals original element-wise")
    (let a3 +[10 20 30])
    (let r3 (a3 .map (-> (n) n)))
    (is (r3 .at 0) 10 "... identity map [0] = 10")
    (is (r3 .at 1) 20 "... identity map [1] = 20")
    (is (r3 .at 2) 30 "... identity map [2] = 30")

    (diag "nested .map: apply .map to an array of arrays")
    (let matrix +[ +[1 2 3] +[4 5 6] +[7 8 9] ])
    (let result (matrix .map (-> (row) (row .map (-> (x) (x * 2))))))
    (is (result .length) 3 "... outer map preserves row count")
    (let row0 (result .at 0))
    (is (row0 .at 0) 2  "... result[0][0] = 2")
    (is (row0 .at 1) 4  "... result[0][1] = 4")
    (is (row0 .at 2) 6  "... result[0][2] = 6")
    (let row1 (result .at 1))
    (is (row1 .at 0) 8  "... result[1][0] = 8")
    (is (row1 .at 1) 10 "... result[1][1] = 10")
    (is (row1 .at 2) 12 "... result[1][2] = 12")
    (let row2 (result .at 2))
    (is (row2 .at 0) 14 "... result[2][0] = 14")
    (is (row2 .at 1) 16 "... result[2][1] = 16")
    (is (row2 .at 2) 18 "... result[2][2] = 18")

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
