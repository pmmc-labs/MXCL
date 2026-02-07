#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Compiler;

my $arena = MXCL::Arena->new;

my $compiler = MXCL::Compiler->new(
    alloc  => MXCL::Allocator::Terms->new( arena => $arena ),
    parser => MXCL::Parser->new,
);

my $exprs = $compiler->compile(q[
    ( (1 2 3 4) (1 2 3 4) (1 2 3 4) (1 2 3 4) )
]);

say $_->to_string foreach @$exprs;

diag "Arena:";
diag "  - allocated = ", $arena->num_allocated;
diag "  - alive     = ", $arena->num_pointers;

pass('...shh');

done_testing;
