#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed method dispatch on Hash: (hash-term .method ...args)
# Hashes are constructed with +{key val ...} syntax.

my $source = q[
    (diag "construction and .length")
    (let h +{"a" 1 "b" 2 "c" 3})
    (is (h .length) 3 "... +{a b c}.length = 3")

    (let empty +{})
    (is (empty .length) 0 "... +{}.length = 0")

    (diag ".at")
    (let h2 +{"x" 10 "y" 20})
    (is (h2 .at "x") 10 "... h.at(x) = 10")
    (is (h2 .at "y") 20 "... h.at(y) = 20")

    (diag ".add (returns a new hash with the key set)")
    (let h3  +{"a" 1})
    (let h3b (h3 .add "b" 2))
    (is (h3b .length) 2  "... add increases length")
    (is (h3b .at "a") 1  "... original key preserved after add")
    (is (h3b .at "b") 2  "... new key accessible after add")

    (diag ".delete (returns a new hash without the key)")
    (let h4  +{"a" 1 "b" 2})
    (let h4b (h4 .delete "a"))
    (is (h4b .length) 1  "... delete reduces length")
    (is (h4b .at "b") 2  "... remaining key preserved after delete")

    (diag ".keys")
    (let h5 +{"x" 1})
    (let ks (h5 .keys))
    (is (head ks) "x" "... single-key hash has key x")

    (diag ".values")
    (let h6 +{"x" 42})
    (let vs (h6 .values))
    (is (head vs) 42 "... single-key hash has value 42")

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
