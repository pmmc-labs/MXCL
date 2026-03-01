#!perl

use v5.42;

use Test::More;
use MXCL::Context;

# Autoboxed method dispatch on Array: (array-term .method ...args)
# Arrays are constructed with +[...] syntax.

my $source = q[
    (diag "construction and .length")
    (let a +[1 2 3])
    (is (a .length) 3 "... +[1 2 3].length = 3")

    (let empty +[])
    (is (empty .length) 0 "... +[].length = 0")

    (let single +["x"])
    (is (single .length) 1 "... +[x].length = 1")

    (diag ".at (zero-indexed)")
    (let a2 +[10 20 30])
    (is (a2 .at 0) 10 "... at(0) = 10")
    (is (a2 .at 1) 20 "... at(1) = 20")
    (is (a2 .at 2) 30 "... at(2) = 30")

    (diag ".reverse")
    (let ar  +[1 2 3])
    (let r   (ar .reverse))
    (is (r .at 0) 3 "... reverse[0] = 3")
    (is (r .at 1) 2 "... reverse[1] = 2")
    (is (r .at 2) 1 "... reverse[2] = 1")

    (diag ".push (appends a single element)")
    (let ap  +[1 2])
    (let ap2 (ap .push 3))
    (is (ap2 .length) 3  "... push increases length")
    (is (ap2 .at 2)   3  "... push appends element")

    (diag ".unshift (prepends a single element)")
    (let au  +[2 3])
    (let au2 (au .unshift 1))
    (is (au2 .length) 3  "... unshift increases length")
    (is (au2 .at 0)   1  "... unshift prepends element")
    (is (au2 .at 1)   2  "... unshift shifts original first")

    (diag ".splice (offset, length)")
    (let as  +[1 2 3 4 5])
    (let s   (as .splice 1 3))
    (is (s .length) 3  "... splice(1,3) returns 3 elements")
    (is (s .at 0)   2  "... splice[0] = 2")
    (is (s .at 1)   3  "... splice[1] = 3")
    (is (s .at 2)   4  "... splice[2] = 4")

    (diag ".join")
    (let aj +["a" "b" "c"])
    (is (aj .join ",") "a,b,c" "... array.join(,) = a,b,c")
    (is (aj .join "-") "a-b-c" "... array.join(-) = a-b-c")
    (is (aj .join "")  "abc"   "... array.join() = abc")

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
