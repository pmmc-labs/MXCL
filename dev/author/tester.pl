#!perl

use v5.42;
use experimental qw[ class ];

use Data::Dumper qw[ Dumper ];
use List::Util qw[ max min uniq ];
use Time::HiRes ();

use MXCL::Context;
use MXCL::Debugger;

my $context = MXCL::Context->new->initialize;

my %timings;

my $start_compile = [Time::HiRes::gettimeofday];
my $exprs = $context->compile_source(q[

(", " .join +[ 1 2 3 ])


]);
$timings{compile} += Time::HiRes::tv_interval( $start_compile );

say "PROGRAM:";
say $_->pprint foreach @$exprs;

my $start_run = [Time::HiRes::gettimeofday];
my $result = $context->evaluate( $context->base_scope, $exprs );
$timings{execute} += Time::HiRes::tv_interval( $start_run );

say sprintf q[
RESULT: %s

TIMING:
-------------------------------------------------
 compile (ms) : %.03f
 execute (ms) : %.03f
-------------------------------------------------]
=>  ($result ? $result->stack->head->pprint : 'UNDEFINED'),
    (map { $_ * 1000 } @timings{qw[ compile execute ]}),
;



__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 10)


