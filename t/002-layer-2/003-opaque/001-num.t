#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed dispatch on Num: (num-term method ...args)
# Dispatches through the Num role which composes Num-specific methods with ORD and EQ.

# --- arithmetic ---

test_mxcl(q[
    (is (1  + 2)   3  "... 1 + 2 = 3")
    (is (10 - 3)   7  "... 10 - 3 = 7")
    (is (3  * 4)  12  "... 3 * 4 = 12")
    (is (10 / 2)   5  "... 10 / 2 = 5")
    (is (10 % 3)   1  "... 10 % 3 = 1")
    (is (0  + 0)   0  "... 0 + 0 = 0")
    (is (5  - 5)   0  "... 5 - 5 = 0")
    (is (7  * 0)   0  "... 7 * 0 = 0")
]);

# --- equality ---

test_mxcl(q[
    (ok      (5 == 5) "... 5 == 5")
    (ok (not (5 == 4)) "... not 5 == 4")
    (ok      (0 == 0) "... 0 == 0")
]);

# --- inequality (derived from EQ via !=) ---

test_mxcl(q[
    (ok      (5 != 4) "... 5 != 4")
    (ok (not (5 != 5)) "... not 5 != 5")
]);

# --- ordering: > (primitive) ---

test_mxcl(q[
    (ok      (5 > 4)  "... 5 > 4")
    (ok (not (4 > 5)) "... not 4 > 5")
    (ok (not (5 > 5)) "... not 5 > 5")
]);

# --- ordering: < (derived from ORD as "not (n > m || n == m)") ---

test_mxcl(q[
    (ok      (4 < 5)  "... 4 < 5")
    (ok (not (5 < 4)) "... not 5 < 4")
    (ok (not (5 < 5)) "... not 5 < 5")
]);

# --- ordering: >= and <= (derived from ORD) ---

test_mxcl(q[
    (ok (5 >= 5)  "... 5 >= 5")
    (ok (5 >= 4)  "... 5 >= 4")
    (ok (not (4 >= 5)) "... not 4 >= 5")

    (ok (5 <= 5)  "... 5 <= 5")
    (ok (4 <= 5)  "... 4 <= 5")
    (ok (not (5 <= 4)) "... not 5 <= 4")
]);

# --- nested / chained arithmetic ---

test_mxcl(q[
    (is ((2 + 3) * 4) 20  "... (2+3)*4 = 20")
    (is ((10 - 4) / 2) 3  "... (10-4)/2 = 3")
    (is ((3 * 3) + (4 * 4)) 25 "... 3^2 + 4^2 = 25")
]);

done_testing;
