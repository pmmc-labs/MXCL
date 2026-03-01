#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Builtin list functions: map, grep, reduce -- operating on quoted cons lists.
# These are purely recursive MXCL-defined functions from the Prelude.

my $source = q[
    (diag "map: transforms each element")
    (let result (map (-> (x) (x * 2)) '(1 2 3)))
    (is (head result)               2 "... map[0] = 2")
    (is (head (tail result))        4 "... map[1] = 4")
    (is (head (tail (tail result))) 6 "... map[2] = 6")
    (ok (nil? (tail (tail (tail result)))) "... map result is nil-terminated")

    (diag "map on empty list returns nil")
    (let result2 (map (-> (x) (x * 2)) '()))
    (ok (nil? result2) "... map on empty list returns nil")

    (diag "grep: filters elements matching predicate")
    (let result3 (grep (-> (x) (x > 2)) '(1 2 3 4 5)))
    (is (head result3)               3 "... grep[0] = 3")
    (is (head (tail result3))        4 "... grep[1] = 4")
    (is (head (tail (tail result3))) 5 "... grep[2] = 5")
    (ok (nil? (tail (tail (tail result3)))) "... grep result is nil-terminated")

    (diag "grep: no matches returns nil")
    (let result4 (grep (-> (x) (x > 10)) '(1 2 3)))
    (ok (nil? result4) "... grep with no matches returns nil")

    (diag "grep: all elements match")
    (let result5 (grep (-> (x) (x > 0)) '(1 2 3)))
    (is (head result5)               1 "... all-match grep[0] = 1")
    (is (head (tail result5))        2 "... all-match grep[1] = 2")
    (is (head (tail (tail result5))) 3 "... all-match grep[2] = 3")

    (diag "reduce: folds with initial accumulator")
    (let result6 (reduce 0 (-> (n m) (n + m)) '(1 2 3 4)))
    (is result6 10 "... reduce sum of 1..4 = 10")

    (let result7 (reduce 1 (-> (n m) (n * m)) '(1 2 3 4 5)))
    (is result7 120 "... reduce product of 1..5 = 120")

    (diag "reduce on empty list returns accumulator")
    (let result8 (reduce 42 (-> (n m) (n + m)) '()))
    (is result8 42 "... reduce on empty list returns initial accumulator")

    (diag "chained map + grep + reduce")
    (let result9
        (reduce 0
            (-> (n m) (n + m))
            (grep  (-> (x) (x > 5))
            (map   (-> (x) (x * 2))
                   '(1 2 3 4)))))
    (is result9 14 "... map(*2) |> grep(>5) |> reduce(+) on (1 2 3 4) = 14")

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
