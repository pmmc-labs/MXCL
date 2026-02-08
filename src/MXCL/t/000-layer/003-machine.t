#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

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

my $add = $terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value + $m->value ) }
);

my $mul = $terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value * $m->value ) }
);

my $numeric = $terms->Env(
    '+' => $add,
    '*' => $mul,
);

my $env = $terms->Env(
    '+' => $add,
    '*' => $mul,
    'MXCL::Term::Num' => $terms->Opaque($terms->Env(
        $numeric,
        'add' => $add,
        'mul' => $mul,
    ))
);

my $exprs = $compiler->compile(q[
    (10 * 20)
]);

diag "COMPILER:";
diag $_->to_string foreach @$exprs;

diag "ARENA:";
diag format_stats('Terms',  $arena->stats);
#diag format_stats('Hashes', $arena->hashs);

diag "RUNNING:";
my $result = $machine->run( $env, $exprs );

diag "RESULT:";
diag $result ? $result->stack->to_string : 'UNDEFINED';

diag "ARENA:";
diag format_stats('Terms',  $arena->stats);
#diag format_stats('Hashes', $arena->hashs);

pass('...shh');

done_testing;

sub format_stats ($what, $stats) {
    join "\n" =>
    ('-' x 60),
    (sprintf '| %-32s | %5s | %4s | %6s |' => $what, qw[ alive hits misses ]),
    ('-' x 60),
    (map {
        sprintf '| %32s | %5d | %4d | %6d |' => @$_
    } sort {
        $b->[1] <=> $a->[1]
    } map {
        [ $_ =~ s/^MXCL\:\:Term\:\://r, $stats->{$_}->@{qw[ alive hits misses ]} ]
    } keys %$stats),
    ('-' x 60)
}
