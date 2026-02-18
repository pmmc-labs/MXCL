#!perl

use v5.42;
use experimental qw[ class ];

use Data::Dumper qw[ Dumper ];
use Time::HiRes qw[ time ];

use MXCL::Context;
use MXCL::Runtime;

my $context = MXCL::Context->new;
my $runtime = MXCL::Runtime->new( context => $context );

my $exprs = $context->compile_source(q[

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 500)

]);

say "COMPILER:";
say $_->pprint foreach @$exprs;

say "RUNNING:";
my $start  = time;
my $result = $context->evaluate( $runtime->base_scope, $exprs );
my $timing =  $start - time;
say ">>> RUNTIME: ", $timing;

say "RESULT:";
say $result ? $result->stack->pprint : 'UNDEFINED';

my $arena = $context->arena;

say "ARENA:";
my $gen = $arena->generations->[-1];
say sprintf q[
GEN - %s
-------------------------------------------------
 alive: %d
  hits: %d
misses: %d
-------------------------------------------------
] => $gen->{label},
    map { defined $_ ? $_ : 0 } $gen->{statz}->@{qw[ alive hits misses ]};


__END__


