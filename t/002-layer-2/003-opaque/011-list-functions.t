#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Builtin list functions: map, grep, reduce -- operating on quoted cons lists.
# These are purely recursive MXCL-defined functions from the Prelude.

# --- map: transforms each element ---

test_mxcl(q[
    (let result (map (-> (x) (x * 2)) '(1 2 3)))
    (is (head result)               2 "... map[0] = 2")
    (is (head (tail result))        4 "... map[1] = 4")
    (is (head (tail (tail result))) 6 "... map[2] = 6")
    (ok (nil? (tail (tail (tail result)))) "... map result is nil-terminated")
]);

# --- map on empty list returns nil ---

test_mxcl(q[
    (let result (map (-> (x) (x * 2)) '()))
    (ok (nil? result) "... map on empty list returns nil")
]);

# --- grep: filters elements matching predicate ---

test_mxcl(q[
    (let result (grep (-> (x) (x > 2)) '(1 2 3 4 5)))
    (is (head result)               3 "... grep[0] = 3")
    (is (head (tail result))        4 "... grep[1] = 4")
    (is (head (tail (tail result))) 5 "... grep[2] = 5")
    (ok (nil? (tail (tail (tail result)))) "... grep result is nil-terminated")
]);

# --- grep: no matches returns nil ---

test_mxcl(q[
    (let result (grep (-> (x) (x > 10)) '(1 2 3)))
    (ok (nil? result) "... grep with no matches returns nil")
]);

# --- grep: all elements match ---

test_mxcl(q[
    (let result (grep (-> (x) (x > 0)) '(1 2 3)))
    (is (head result)               1 "... all-match grep[0] = 1")
    (is (head (tail result))        2 "... all-match grep[1] = 2")
    (is (head (tail (tail result))) 3 "... all-match grep[2] = 3")
]);

# --- reduce: folds with initial accumulator ---

test_mxcl(q[
    (let result (reduce 0 (-> (n m) (n + m)) '(1 2 3 4)))
    (is result 10 "... reduce sum of 1..4 = 10")
]);

test_mxcl(q[
    (let result (reduce 1 (-> (n m) (n * m)) '(1 2 3 4 5)))
    (is result 120 "... reduce product of 1..5 = 120")
]);

# --- reduce on empty list returns accumulator ---

test_mxcl(q[
    (let result (reduce 42 (-> (n m) (n + m)) '()))
    (is result 42 "... reduce on empty list returns initial accumulator")
]);

# --- chained map + grep + reduce (from tester.pl example) ---
# map (*2) on (1 2 3 4) => (2 4 6 8)
# grep (>5) => (6 8)
# reduce (+) with acc=0 => 14

test_mxcl(q[
    (let result
        (reduce 0
            (-> (n m) (n + m))
            (grep  (-> (x) (x > 5))
            (map   (-> (x) (x * 2))
                   '(1 2 3 4)))))
    (is result 14 "... map(*2) |> grep(>5) |> reduce(+) on (1 2 3 4) = 14")
]);

done_testing;
