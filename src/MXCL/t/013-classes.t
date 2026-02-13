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
my $natives  = $ctx->natives;
my $compiler = $ctx->compiler;
my $machine  = $ctx->machine;

sub lift_native_applicative ($name, $params, $returns, $impl) {
    return $natives->Applicative(
        name      => $name,
        signature => $params,
        returns   => $returns,
        impl      => $impl,
    )
}

my $add = lift_native_applicative('+', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Num', sub ($n, $m) { $n + $m });
my $sub = lift_native_applicative('-', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Num', sub ($n, $m) { $n - $m });
my $mul = lift_native_applicative('*', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Num', sub ($n, $m) { $n * $m });
my $div = lift_native_applicative('/', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Num', sub ($n, $m) { $n / $m });
my $mod = lift_native_applicative('%', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Num', sub ($n, $m) { $n % $m });

my $eq  = lift_native_applicative('==',  [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n == $m });
my $not = lift_native_applicative('not', [{ name => 'n' } ], 'Bool', sub ($n) { !$n });

my $if = $natives->Operative(
    name => 'if',
    signature => [
        { name => 'ctx'      },
        { name => 'cond'     },
        { name => 'if-true'  },
        { name => 'if-false' },
    ],
    impl => sub ($ctx, $cond, $if_true, $if_false) {
        # NOTE: this probably needs to derive an Env
        return (
            $konts->IfElse( $ctx, $cond, $if_true, $if_false, $terms->Nil ),
            $konts->EvalExpr( $ctx, $cond, $terms->Nil ),
        )
    }
);

my $lambda = $natives->Operative(
    name => 'lambda',
    signature => [
        { name => 'params' },
        { name => 'body'   },
    ],
    impl => sub ($ctx, $params, $body) {
        return $konts->Return(
            $ctx,
            $terms->List( $terms->Lambda( $params, $body, $ctx ) )
        );
    }
);

my $EQUALITY = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Defined(
        $natives->Operative(
            name => '!=',
            signature => [
                { name => 'n' },
                { name => 'm' },
            ],
            impl => sub ($ctx, $n, $m) {
                $konts->EvalExpr($ctx,
                    # (not (n == m))
                    $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('=='), $m )),
                    $terms->Nil
                )
            }
        )
    )
);

my $env = $traits->Trait(
    'lambda' => $traits->Defined($lambda),
    'if'     => $traits->Defined($if),
    'not'    => $traits->Defined($not),
    'MXCL::Term::Num' => $traits->Defined($traits->Compose(
        $EQUALITY,
        $traits->Trait(
            '==' => $traits->Defined($eq),
            '+'  => $traits->Defined($add),
            '-'  => $traits->Defined($sub),
            '*'  => $traits->Defined($mul),
            '/'  => $traits->Defined($div),
            '%'  => $traits->Defined($mod),
        )
    )),
);

$arena->commit_generation('environment initialized');

my $exprs = $ctx->compile_source(q[
    ((lambda (x y) (x + y)) 10 20)
]);

diag "COMPILER:";
diag $_->stringify foreach @$exprs;



diag "RUNNING:";
my $result = $ctx->evaluate( $env, $exprs );


diag "RESULT:";
diag $result ? $result->stack->stringify : 'UNDEFINED';



diag "TRACE:";
diag join "\n" => map { $_->stringify, $_->env->stringify } $machine->trace->@*;

pass('...shh');

done_testing;


