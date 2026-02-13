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

my $env = $traits->Trait(
    '==' => $traits->Defined($eq),
    'MXCL::Term::Num' => $traits->Defined(
            $traits->Trait(
            '+'  => $traits->Defined($add),
            '-'  => $traits->Defined($sub),
            '*'  => $traits->Defined($mul),
            '/'  => $traits->Defined($div),
            '%'  => $traits->Defined($mod),
        )
    ),
    '$ten' => $traits->Defined(
        $terms->Opaque(
            $traits->Trait(
                'add'  => $traits->Defined(
                    lift_native_applicative(
                        '$ten:add',
                        [{ name => 'self' }, { name => 'm', coerce => 'numify' }],
                        'Num',
                        sub ($self, $m) { 10 + $m }
                    )
                )
            )
        )
    ),
);

my $exprs = $compiler->compile(q[
    ($ten add (4 * 5))
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
