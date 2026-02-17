#!perl

use v5.42;
use experimental qw[ class ];

use MXCL::Context;
use MXCL::Runtime;

my $context = MXCL::Context->new;
my $runtime = MXCL::Runtime->new( context => $context );

my $exprs = $context->compile_source(q[

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 2)

]);

say "COMPILER:";
say $_->pprint foreach @$exprs;

say "RUNNING:";
my $result = $context->evaluate( $runtime->base_scope, $exprs );

say "RESULT:";
say $result ? $result->stack->pprint : 'UNDEFINED';


__END__


