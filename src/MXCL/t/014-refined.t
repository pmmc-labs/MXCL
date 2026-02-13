#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Context;
use MXCL::Runtime;

my $ctx = MXCL::Context->new;

my $terms    = $ctx->terms;
my $konts    = $ctx->kontinues;
my $refs     = $ctx->refs;
my $traits   = $ctx->traits;
my $natives  = $ctx->natives;

my $runtime  = MXCL::Runtime->new( context => $ctx );

my $exprs = $ctx->compile_source(q[
    ((lambda (x) (concat "Hello " x)) "World")
]);

diag "COMPILER:";
diag $_->stringify foreach @$exprs;

diag "RUNNING:";
my $result = $ctx->evaluate( $runtime->base_scope, $exprs );

diag "RESULT:";
diag $result ? $result->stack->stringify : 'UNDEFINED';

pass('...shh');

done_testing;


