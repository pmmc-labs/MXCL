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

(require x)

(let scope1 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(let x 10)
(let scope2 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(let x 20)
(let scope3 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(say "------------------------------")
(say scope1)
(say scope2)
(say scope3)
(say "------------------------------")

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

;; -----------------------------------------------------------------------------
;; Scope introspection
;; -----------------------------------------------------------------------------

(require x)

(let scope1 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(let x 10)
(let scope2 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(let x 20)
(let scope3 ((^CTX .current-scope) .difference (^CTX .base-scope)))

(say "------------------------------")
(say scope1)
(say scope2)
(say scope3)
(say "------------------------------")

;; -----------------------------------------------------------------------------
;; some fexpr examples
;; -----------------------------------------------------------------------------


(let unless (~> (cond if-true) (if (not (cond .eval)) (if-true .eval) ())))

(fexpr unless (cond if-true)
    (if (not (cond .eval)) (if-true .eval) ()))

(fexpr unless (cond if-true)
    (if (not (eval cond)) (eval if-true) ()))

;; -----------------------------------------------------------------------------
;; multi-dimensional  array map
;; -----------------------------------------------------------------------------

(+[
   +[ 1 2 3 ]
   +[ 4 5 6 ]
   +[ 7 8 9 ]
] .map
    (-> (a)
        (a .map (-> (x) (x * 2)))))

;; -----------------------------------------------------------------------------
;; single-dimensional array map
;; -----------------------------------------------------------------------------

(+[ 1 2 3 ] .map (-> (n) (n * 2)))

;; -----------------------------------------------------------------------------
;; array foreach for side effects
;; -----------------------------------------------------------------------------

(+[ 1 2 3 ] .foreach (-> (x)
        (do
            (print (("Got: " ~ x) ~ "\n")))))

;; -----------------------------------------------------------------------------
;; built in reduce/grep/map chain
;; -----------------------------------------------------------------------------

(reduce 0 (-> (n m) (n + m)) (grep ( ->(x) (x > 5)) (map ( ->(x) (x * 2)) '(1 2 3 4))))

;; -----------------------------------------------------------------------------
;; while loop with mutable state
;; -----------------------------------------------------------------------------

(let x (make-ref 10))
(while ((x .get) > 0)
    (do
        (x .set! ((x .get) - 1))
        (print (x .get))
        (print "\n")))

;; -----------------------------------------------------------------------------
;; basic recursive factorial
;; -----------------------------------------------------------------------------

(define fact (n)
    (if (n == 0)
        1
        (n * (fact (n - 1)))))

(fact 10)


