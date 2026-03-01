#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[


    (diag "let tests")
    (let my-num 42)
    (is my-num                      42      "... let binds number")

    (let my-str "hello")
    (is my-str                      "hello" "... let binds string")

    (let computed (10 + 20))
    (is computed                    30      "... let evaluates expression")

    (diag "define tests")
    (define add-one (x) (x + 1))
    (is (add-one 5)                 6       "... define creates callable function")

    (define add (x y) (x + y))
    (is (add 3 4)                   7       "... define with multiple args")

    (define greet (name) ("Hello, " ~ name))
    (is (greet "World")             "Hello, World" "... define with string operations")

    (diag "define with body expressions")
    (define complex (x)
        (do
            (let doubled (x * 2))
            (doubled + 1)))
    (is (complex 5)                 11      "... define with do block body")

    (diag "Recursive define")
    (define factorial (n)
        (if (n <=  1)
            1
            (n * (factorial (n - 1)))))
    (is (factorial 0)               1       "... factorial 0")
    (is (factorial 1)               1       "... factorial 1")
    (is (factorial 5)               120     "... factorial 5")

    (diag "lambda tests")
    (let identity (lambda (x) x))
    (is (identity 42)               42      "... lambda identity function")

    (let adder (lambda (a b) (a + b)))
    (is (adder 10 20)               30      "... lambda with multiple args")

    (diag "Closures")
    (define make-adder (n)
        (lambda (x) (x + n)))
    (let add-5 (make-adder 5))
    (let add-10 (make-adder 10))
    (is (add-5 3)                   8       "... closure captures n=5")
    (is (add-10 3)                  13      "... closure captures n=10")

    (done-testing)
];

my $context = MXCL::Context->new->initialize;
try {
    my $result  = $context->evaluate(
        $context->base_scope,
        $context->compile_source($source)
    );
} catch ($e) {
    BAIL_OUT($e);
}

