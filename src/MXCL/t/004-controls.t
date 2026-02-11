#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Context;
use MXCL::Machine;

my $ctx = MXCL::Context->new;

my $arena    = $ctx->arena;
my $terms    = $ctx->terms;
my $konts    = $ctx->kontinues;
my $traits   = $ctx->traits;
my $compiler = $ctx->compiler;

my $machine = MXCL::Machine->new( context => $ctx );

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

my $numeric = $traits->Trait(
    '+'   => $traits->Defined($add),
    '*'   => $traits->Defined($mul),
    'eq?' => $traits->Defined($eq),
);

my $env = $traits->Trait(
    'if'     => $traits->Defined($if),
    'lambda' => $traits->Defined($lambda),

    'eq?' => $traits->Defined($eq),
    '+'   => $traits->Defined($add),
    '*'   => $traits->Defined($mul),

    'MXCL::Term::Num' => $traits->Defined(
        $traits->Compose(
            $numeric,
            $traits->Trait(
                'add' => $traits->Defined($add),
                'mul' => $traits->Defined($mul),
            )
        )
    )
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
