#!perl

use v5.42;

use Test::More;
use Test::MXCL qw[ test_mxcl ];


my $result = test_mxcl(q[

    (let Greeter (role
            (define hello ($) "Hello World")
            (define bye   ($) "Goodbye!")))

    (let greeter (make-opaque Greeter))

    ((greeter hello) ~ ("/" ~ (greeter bye)))

]);

say($result ? $result->stack->pprint : 'UNDEFINED');

done_testing;

