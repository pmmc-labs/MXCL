#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Context;
use MXCL::Runtime;

my $context = MXCL::Context->new;
my $runtime = MXCL::Runtime->new( context => $context );

my $exprs = $context->compile_source(q[

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 10)
]);

diag "COMPILER:";
diag $_->pprint foreach @$exprs;

diag "RUNNING:";
my $result = $context->evaluate( $runtime->base_scope, $exprs );

diag "RESULT:";
diag $result ? $result->stack->pprint : 'UNDEFINED';

pass('...shh');

done_testing;


