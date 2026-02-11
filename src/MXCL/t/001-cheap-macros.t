#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Arena;
use MXCL::Allocator::Terms;

my $arena = MXCL::Arena->new;
my $terms = MXCL::Allocator::Terms->new( arena => $arena );

my $adder = $terms->Lambda(
    $terms->List( $terms->Sym('x'), $terms->Sym('y') ),
    $terms->List( $terms->Sym('+'), $terms->Sym('x'), $terms->Sym('y') ),
    $terms->Nil # fake the Env for now
);

is "(${adder} 10 20)", "((lambda (x y) (+ x y)) 10 20)", '... macros';

pass('... shhh');

done_testing;
