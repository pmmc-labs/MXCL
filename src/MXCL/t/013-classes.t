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
    (((lambda (x y) (x + y)) 10 20) != 30)
]);

diag "COMPILER:";
diag $_->pprint foreach @$exprs;

diag "RUNNING:";
my $result = $context->evaluate( $runtime->base_scope, $exprs );


diag "RESULT:";
diag $result ? $result->stack->pprint : 'UNDEFINED';

diag "TRACE:";
diag join "\n" => map { $_->pprint, $_->env->pprint } $context->machine->trace->@*;

pass('...shh');

done_testing;


