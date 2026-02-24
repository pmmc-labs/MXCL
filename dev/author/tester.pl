#!perl

use v5.42;
use experimental qw[ class ];

use Data::Dumper qw[ Dumper ];
use List::Util qw[ max min uniq ];
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

my $arena   = $context->arena;

my $debugger = MXCL::Debugger->new;
say $_ foreach (
    #debugger->shelve(
        #$debugger->term_tree($result->stack, pprint_width => 60),
        #$debugger->arena_commit_table($arena),
        #$debugger->stack(
            $debugger->stack(
                $debugger->arena_term_stat_table($arena),
                $debugger->arena_timing_stat_table($arena),
            #),
            #$debugger->arena_type_table($arena, sort_by_active => true)
        #)
    )->@*,
    #$debugger->arena_commit_table($arena)->@*,
    #$debugger->arena_hash_table($arena, show_types => true)->@*,
);


__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 1000)


