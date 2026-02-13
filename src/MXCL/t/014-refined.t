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
    (define adder (x y)
        (add x y))

    (adder (adder 10 20) (adder 100 204))
]);

diag "COMPILER:";
diag $_->stringify foreach @$exprs;

diag "RUNNING:";
my $result = $context->evaluate( $runtime->base_scope, $exprs );

diag "RESULT:";
diag $result ? $result->stack->stringify : 'UNDEFINED';

pass('...shh');

done_testing;


