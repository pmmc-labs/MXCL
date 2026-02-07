#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Parser;

my $parser = MXCL::Parser->new;

my $compounds = $parser->parse(q[
     ( 1 2 3 4 )
     [ 1 2 3 4 ]
    @[ 1 2 3 4 ]
     { 1 2 3 4 }
    %{ 1 2 3 4 }
    (lambda (x y) (+ x y))
]);

say $_->to_string foreach @$compounds;


done_testing;
