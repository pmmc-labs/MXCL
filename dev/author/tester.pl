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

    (let $output (make-channel))
    (let $count  (make-ref 0))
    (let $fails  (make-ref 0))

    (define diag (msg)
        ($output write ("# " ~ msg)))

    (define out (msg)
        ($output write msg))

    (define todo (msg)
        (diag ("TODO:" ~ msg)))

    (define pass (msg)
        (do
            ($count set! (($count get) + 1))
            (out (("ok " ~ ($count get)) ~ (" - " ~ msg)))))

    (define fail (msg)
        (do
            ($count set! (($count get) + 1))
            ($fails set! (($fails get) + 1))
            (out (("not ok " ~ ($count get)) ~ (" - " ~ msg)))))

    (define ok (test msg)
        (if test (pass msg) (fail msg)))

    (define is (got expected msg)
        (do
            (let result (eq? got expected))
            (ok result msg)
            (or result
                (do
                    (diag ("Failed test " ~ msg))
                    (diag ("       got: " ~ got))
                    (diag ("  expected: " ~ expected))))))

    (define done-testing ()
        (if (($fails get) != 0)
            (do (out ("1.." ~ ($count get)))
                (diag (("looks like you failed " ~ ($fails get)) ~
                                (" test(s) of " ~ ($count get)))))
            (out ("1.." ~ ($count get)))))


    (ok true "... this is true")
    (is 10 10 "... these are equal")
    (is 10 20 "... these are equal")
    (done-testing)

    $output

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
=>  ($result ? $result->stack->pprint : 'UNDEFINED'),
    (map { $_ * 1000 } @timings{qw[ compile execute ]}),
;

say join "\n" => map $_->pprint, reverse $result->stack->head->buffer->@*;


__END__

    (define fact (n)
        (if (n == 0)
            1
            (n * (fact (n - 1)))))

    (fact 10)


