#!perl

use v5.42;
use experimental qw[ class ];

use Data::Dumper qw[ Dumper ];
use List::Util qw[ max min ];
use Time::HiRes ();

use MXCL::Context;
use MXCL::Runtime;

my $context = MXCL::Context->new;
my $runtime = MXCL::Runtime->new( context => $context );

my %timings;

my $start_compile = [Time::HiRes::gettimeofday];
my $exprs = $context->compile_source(q[

    (let foo 10)
    (let bar 100)

    (do
        ; testing the comments
        (let foo 20)
        (let bar 30) ; do they work correctly
    )

    (foo + bar)

    ; even as the last thing?

]);
$timings{compile} += Time::HiRes::tv_interval( $start_compile );

say "PROGRAM:";
say $_->pprint foreach @$exprs;

my $start_run = [Time::HiRes::gettimeofday];
my $result = $context->evaluate( $runtime->base_scope, $exprs );
$timings{execute} += Time::HiRes::tv_interval( $start_run );

my $arena = $context->arena;
my $gen = $arena->generations->[-1];
say sprintf q[
RESULT: %s

TIMING:
-------------------------------------------------
 compile (ms) : %.03f
 execute (ms) : %.03f
-------------------------------------------------

ARENA:
-- cache ----------------------------------------
   alive : %d
    hits : %d
  misses : %d
-- times ----------------------------------------
    hits (ms) : %.03f
  misses (ms) : %.03f
 hashing (ms) : %.03f
.................................................
     MD5 (ms) : %.03f
-------------------------------------------------]
=>  ($result ? $result->stack->pprint : 'UNDEFINED'),
    (map { $_ * 1000 } @timings{qw[ compile execute ]}),
    (map { defined $_ ? $_ : 0 } $gen->{statz}->@{qw[ alive hits misses ]}),
    (map { $_ * 1000 } $gen->{timez}->@{qw[ hits misses hashing MD5 ]}),
;


__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 1000)
