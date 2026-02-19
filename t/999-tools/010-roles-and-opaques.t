#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];


my $result = test_mxcl(q[

    ;; NOTE: the <Str> is part of
    ;; the name, nothing actually
    ;; get checked (for now)

    (role Greeter<Str>
        (define hello (x) ("Hello " ~ x))
        (define bye   (x) ("Goodbye " ~ x))
    )

    (let greeter (make-opaque "World" Greeter<Str>))

    ((greeter hello) ~ ("/" ~ (greeter bye)))


]);

say($result ? $result->stack->pprint : 'UNDEFINED');

done_testing;

