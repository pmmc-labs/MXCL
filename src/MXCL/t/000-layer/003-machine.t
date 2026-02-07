#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Kontinues;

use MXCL::Parser;
use MXCL::Compiler;

use MXCL::Machine;

my $arena = MXCL::Arena->new;

my $terms = MXCL::Allocator::Terms->new( arena => $arena );
my $konts = MXCL::Allocator::Kontinues->new( arena => $arena );

my $compiler = MXCL::Compiler->new(
    alloc  => $terms,
    parser => MXCL::Parser->new,
);

my $machine = MXCL::Machine->new(
    terms     => $terms,
    kontinues => $konts,
);

my $env = $terms->Env(
    '+' => $terms->NativeApplicative(
        $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
        sub ($n, $m) { $terms->Num( $n->value + $m->value ) }
    ),
    '*' => $terms->NativeApplicative(
        $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
        sub ($n, $m) { $terms->Num( $n->value + $m->value ) }
    )
);

my $exprs = $compiler->compile(q[
    (+ (+ (+ 5 5) (* 5 4)) (* (+ (+ 2 18) (* 3 8)) (+ (+ 100 76) (* 7 6))))
]);

diag "COMPILER:";
diag $_->to_string foreach @$exprs;

diag "ARENA:";
diag "  - allocated = ", $arena->num_allocated;
diag "  - alive     = ", $arena->num_pointers;
{
    diag "  - by Term Type:";
    my $report = $arena->term_report;
    foreach my ($type, $count) (%$report) {
        diag sprintf "     - %4d = %s", $count, $type;
    }
}

diag "RUNNING:";
my $result = $machine->run( $env, $exprs );

diag "RESULT:";
diag $result ? $result->stack->to_string : 'UNDEFINED';

diag "ARENA:";
diag "  - allocated = ", $arena->num_allocated;
diag "  - alive     = ", $arena->num_pointers;
{
    diag "  - by Term Type:";
    my $report = $arena->term_report;
    foreach my ($type, $count) (%$report) {
        diag sprintf "     - %4d = %s", $count, $type;
    }
}

pass('...shh');

done_testing;
