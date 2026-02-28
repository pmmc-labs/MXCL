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


(let x (make-ref 10))
(while ((x .get) > 0)
    (do
        (x .set! ((x .get) - 1))
        (print (x .get))
        (print "\n")))



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
=>  ($result ? do {
        my $stack = $result->stack;
        ($stack isa MXCL::Term::Cons ? $stack->head->pprint : '()');
    } : 'UNDEFINED'),
    (map { $_ * 1000 } @timings{qw[ compile execute ]}),
;



__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 10)


