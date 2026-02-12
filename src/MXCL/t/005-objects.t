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
my $refs     = $ctx->refs;
my $traits   = $ctx->traits;
my $compiler = $ctx->compiler;

my $machine = MXCL::Machine->new( context => $ctx );

my $add = $traits->Defined($terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value + $m->value ) }
));

my $mul = $traits->Defined($terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value * $m->value ) }
));

my $eq = $traits->Defined($terms->NativeApplicative(
    $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $n->value == $m->value ? $terms->True : $terms->False }
));

my $if = $traits->Defined($terms->NativeOperative(
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
));

my $lambda = $traits->Defined($terms->NativeOperative(
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
));

my $numeric = $traits->Trait(
    '+'   => $add,
    '*'   => $mul,
    'eq?' => $eq,
);

my $env = $traits->Trait(
    'if'     => $if,
    'lambda' => $lambda,
    'eq?'    => $eq,
    '+'      => $add,
    '*'      => $mul,
    '~'      => $traits->Defined($terms->NativeApplicative(
        $terms->Cons( $terms->Sym('n'), $terms->Sym('m')),
        sub ($n, $m) { $terms->Str( $n->value . $m->value ) }
    )),

    'gorch' => $traits->Defined($refs->Ref( $terms->Num(100) )),

    'foo' => $traits->Defined($terms->Opaque($traits->Trait(
        bar => $terms->NativeApplicative(
            $terms->Nil,
            sub ($self) { $terms->Str("BAR") }
        ),
        baz => $terms->NativeApplicative(
            $terms->Nil,
            sub ($self) { $terms->Str("BAZ") }
        )
    ))),
    'MXCL::Term::Ref' => $traits->Defined($traits->Trait(
        'set!' => $traits->Defined($terms->NativeApplicative(
            $terms->List( $terms->Sym('ref'), $terms->Sym('value') ),
            sub ($ref, $value) { $refs->SetRef( $ref, $value ) }
        )),
        'get' => $traits->Defined($terms->NativeApplicative(
            $terms->List( $terms->Sym('ref') ),
            sub ($ref) { $refs->Deref( $ref ) }
        )),
    ))
);

my $exprs = $compiler->compile(q[
    (+ (gorch get) 10)
    (gorch set! 3000)
    (gorch get)
]);

diag "COMPILER:";
diag $_->stringify foreach @$exprs;

diag "ARENA:";
diag format_stats('Terms',  $arena->typez);
#diag format_stats('Hashes', $arena->hashz);

diag "RUNNING:";
my $result = $machine->run( $env, $exprs );

diag "RESULT:";
diag $result ? $result->stack->stringify : 'UNDEFINED';

diag "ARENA:";
diag format_stats('Terms',  $arena->typez);
#diag format_stats('Hashes', $arena->hashz);

diag "TRACE:";
diag join "\n" => map { $_->stringify, $_->env->stringify } $machine->trace->@*;

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
