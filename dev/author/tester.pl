#!perl

use v5.42;
use experimental qw[ class ];

use Data::Dumper qw[ Dumper ];
use List::Util qw[ max min ];
use Time::HiRes ();

use MXCL::Context;
use MXCL::Debugger;

my $context = MXCL::Context->new;

my %timings;

my $start_compile = [Time::HiRes::gettimeofday];
my $exprs = $context->compile_source(q[

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 5)

]);
$timings{compile} += Time::HiRes::tv_interval( $start_compile );

say "PROGRAM:";
say $_->pprint foreach @$exprs;

my $start_run = [Time::HiRes::gettimeofday];
my $result = $context->evaluate( $context->base_scope, $exprs, load_prelude => true );
$timings{execute} += Time::HiRes::tv_interval( $start_run );

say sprintf q[
RESULT: %s

TIMING:
-------------------------------------------------
 compile (ms) : %.03f
 execute (ms) : %.03f
-------------------------------------------------]
=>  ($result ? $result->stack->pprint : 'UNDEFINED'),
    (map { $_ * 1000 } @timings{qw[ compile execute ]}),
;

my $arena = $context->arena;

foreach my $commit ($arena->commit_log->@*) {
    say $commit->pprint;
}

#my $debugger = MXCL::Debugger->new;
#say $_ foreach (
#    $debugger->arena_term_stat_table($arena)->@*,
#    $debugger->arena_timing_stat_table($arena)->@*,
#    $debugger->arena_type_table($arena, sort_by_alive => true)->@*,
#    $debugger->arena_hash_table($arena, show_types => true)->@*,
#);



__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 1000)


# foreach my ($i, $tape) (indexed $context->tape->tapes->@*) {
#     say '-' x 120;
#     say "TAPE[ $i ]";
#     say '-' x 120;
#     say "QUEUE:";
#     say join "\n" => map $_->pprint, $tape->queue->@*;
#     say '-' x 120;
#     say "TRACE:";
#     say join "\n" => map $_->pprint, reverse $tape->trace->@*;
# }

