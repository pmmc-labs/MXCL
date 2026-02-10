#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Environments;
use MXCL::Allocator::Kontinues;

use MXCL::Parser;
use MXCL::Compiler;

use MXCL::Machine;

my $arena = MXCL::Arena->new;

my $terms = MXCL::Allocator::Terms->new( arena => $arena );
my $konts = MXCL::Allocator::Kontinues->new( arena => $arena );
my $envs  = MXCL::Allocator::Environments->new( arena => $arena );

my $compiler = MXCL::Compiler->new(
    alloc  => $terms,
    parser => MXCL::Parser->new,
);

my $machine = MXCL::Machine->new(
    environs  => $envs,
    terms     => $terms,
    kontinues => $konts,
);

sub lift_native_applicative ($alloc, $params, $body, $returns) {
    return $alloc->NativeApplicative(
        $alloc->List( map $alloc->Sym($_), @$params ),
        sub (@args) { $alloc->$returns( $body->( map $_->value, @args ) ) }
    )
}

my $add = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n + $m }, 'Num');

my $mul = $terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value * $m->value ) }
);

my $eq = $terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $n->value == $m->value ? $terms->True : $terms->False }
);

my $if = $terms->NativeOperative(
    $terms->List(
        $terms->Sym('env'),
        $terms->Sym('cond'),
        $terms->Sym('if-true'),
        $terms->Sym('if-false')
    ),
    sub ($env, $cond, $if_true, $if_false) {
        # NOTE: this probably needs to derive an Env
        return (
            $konts->IfElse( $env, $cond, $if_true, $if_false, $terms->Nil ),
            $konts->EvalExpr( $env, $cond, $terms->Nil ),
        )
    }
);

my $lambda = $terms->NativeOperative(
    $terms->List(
        $terms->Sym('params'),
        $terms->Sym('body'),
    ),
    sub ($env, $params, $body) {
        return $konts->Return(
            $env,
            $terms->List( $terms->Lambda( $params, $body, $env ) )
        );
    }
);

my $numeric = $envs->Env(
    '+'   => $add,
    '*'   => $mul,
    'eq?' => $eq,
);

my $env = $envs->Env(
    'if'     => $if,
    'lambda' => $lambda,

    'eq?' => $eq,
    '+'   => $add,
    '*'   => $mul,

    'MXCL::Term::Num' => $terms->Opaque($envs->Env(
        $numeric,
        'add' => $add,
        'mul' => $mul,
        '=='  => $eq,
    ))
);

my $exprs = $compiler->compile(q[
    ((lambda (x y) (x + y)) 10 20)
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
