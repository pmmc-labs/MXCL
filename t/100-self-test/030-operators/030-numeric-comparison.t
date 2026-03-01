#!perl

use v5.42;
use Test::More;

use MXCL::Context;

my $source = q[

    (diag "Equality (==) tests (infix)")
    (ok (1 == 1)            "... 1 == 1")
    (ok (0 == 0)            "... 0 == 0")
    (ok (-5 == -5)          "... -5 == -5")
    (ok (3.14 == 3.14)      "... 3.14 == 3.14")
    (ok (not (1 == 2))      "... 1 != 2")
    (ok (1 == 1.0)          "... 1 == 1.0 (numeric equality)")
    (ok (true == 1)         "... true == 1 (coercion)")
    (ok (false == 0)        "... false == 0 (coercion)")

    (diag "Inequality (!=) tests (infix)")
    (ok (1 !=  2)            "... 1 != 2")
    (ok (0 !=  1)            "... 0 != 1")
    (ok (-1 !=  1)           "... -1 != 1")
    (ok (not (5 != 5))      "... not (5 != 5)")

    (diag "Less than (<) tests (infix)")
    (ok (1 < 2)             "... 1 < 2")
    (ok (-5 < 0)            "... -5 < 0")
    (ok (0 < 0.1)           "... 0 < 0.1")
    (ok (not (2 < 1))       "... not (2 < 1)")
    (ok (not (1 < 1))       "... not (1 < 1)")

    (diag "Less than or equal (<=) tests (infix)")
    (ok (1 <= 2)            "... 1 <= 2")
    (ok (1 <= 1)            "... 1 <= 1")
    (ok (-1 <= 0)           "... -1 <= 0")
    (ok (not (2 <= 1))      "... not (2 <= 1)")

    (diag "Greater than (>) tests (infix)")
    (ok (2 > 1)             "... 2 > 1")
    (ok (0 > -5)            "... 0 > -5")
    (ok (0.1 > 0)           "... 0.1 > 0")
    (ok (not (1 > 2))       "... not (1 > 2)")
    (ok (not (1 > 1))       "... not (1 > 1)")

    (diag "Greater than or equal (>=) tests (infix)")
    (ok (2 >= 1)            "... 2 >= 1")
    (ok (1 >= 1)            "... 1 >= 1")
    (ok (0 >= -1)           "... 0 >= -1")
    (ok (not (1 >= 2))      "... not (1 >= 2)")

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

