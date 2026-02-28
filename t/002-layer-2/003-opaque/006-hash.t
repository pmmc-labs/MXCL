#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];

# Autoboxed method dispatch on Hash: (hash-term .method ...args)
# Hashes are constructed with +{key val ...} syntax.

# --- construction and .length ---

test_mxcl(q[
    (let h +{"a" 1 "b" 2 "c" 3})
    (is (h .length) 3 "... +{a b c}.length = 3")

    (let empty +{})
    (is (empty .length) 0 "... +{}.length = 0")
]);

# --- .at ---

test_mxcl(q[
    (let h +{"x" 10 "y" 20})
    (is (h .at "x") 10 "... h.at(x) = 10")
    (is (h .at "y") 20 "... h.at(y) = 20")
]);

# --- .add (returns a new hash with the key set) ---

test_mxcl(q[
    (let h  +{"a" 1})
    (let h2 (h .add "b" 2))
    (is (h2 .length) 2  "... add increases length")
    (is (h2 .at "a") 1  "... original key preserved after add")
    (is (h2 .at "b") 2  "... new key accessible after add")
]);

# --- .delete (returns a new hash without the key) ---

test_mxcl(q[
    (let h  +{"a" 1 "b" 2})
    (let h2 (h .delete "a"))
    (is (h2 .length) 1  "... delete reduces length")
    (is (h2 .at "b") 2  "... remaining key preserved after delete")
]);

# --- .keys ---

test_mxcl(q[
    (let h +{"x" 1})
    (let ks (h .keys))
    (is (head ks) "x" "... single-key hash has key x")
]);

# --- .values ---

test_mxcl(q[
    (let h +{"x" 42})
    (let vs (h .values))
    (is (head vs) 42 "... single-key hash has value 42")
]);

done_testing;
