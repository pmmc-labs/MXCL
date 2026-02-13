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

my $machine = MXCL::Machine->new( context => $ctx );

my $add = $natives->Applicative(
    name      => 'add',
    signature => [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }],
    returns   => 'Num',
    impl      => sub ($n, $m) { $n + $m }
);

my $mul = $natives->Applicative(
    name      => 'mul',
    signature => [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }],
    returns   => 'Num',
    impl      => sub ($n, $m) { $n * $m }
);

my $eq = $natives->Applicative(
    name      => 'eq',
    signature => [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }],
    returns   => 'Bool',
    impl      => sub ($n, $m) { $n == $m }
);

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

my $numeric = $traits->Trait(
    '+'   => $add,
    '*'   => $mul,
    'eq?' => $eq,
);

my $env = $traits->Trait(
    'if'     => $traits->Defined($if),
    'lambda' => $traits->Defined($lambda),
    'eq?'    => $traits->Defined($eq),
    '+'      => $traits->Defined($add),
    '*'      => $traits->Defined($mul),
    'gorch'  => $traits->Defined( $refs->Ref( $terms->Num(100) )),
    'foo' => $traits->Defined(
        $terms->Opaque(
            $traits->Trait(
                bar => $traits->Defined(
                    $natives->Applicative(
                        name      => 'foo:bar',
                        signature => [{ name => 'self' }],
                        returns   => 'Str',
                        impl      => sub ($) { "BAR" }
                    )
                ),
                baz => $traits->Defined(
                        $natives->Applicative(
                        name      => 'foo:baz',
                        signature => [{ name => 'self' }],
                        returns   => 'Str',
                        impl      => sub ($) { "BAZ" }
                    )
                )
            )
        )
    ),
    'MXCL::Term::Ref' => $traits->Defined(
        $traits->Trait(
            'set!' => $traits->Defined(
                $natives->Applicative(
                    name      => 'foo:baz',
                    signature => [{ name => 'ref' }, { name => 'value' }],
                    impl      => sub ($ref, $value) { $refs->SetRef( $ref, $value ) }
                )
            ),
            'get' => $traits->Defined(
                $natives->Applicative(
                    name      => 'foo:baz',
                    signature => [{ name => 'ref' }],
                    impl      => sub ($ref) { $refs->Deref( $ref ) }
                )
            ),
        )
    )
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
