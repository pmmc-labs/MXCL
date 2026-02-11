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

my $add = $terms->NativeApplicative(
    $terms->Cons($terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value + $m->value ) }
);

my $mul = $terms->NativeApplicative(
    $terms->Cons($terms->Sym('n'), $terms->Sym('m')),
    sub ($n, $m) { $terms->Num( $n->value * $m->value ) }
);

my $numeric = $traits->Trait(
    '+' => $traits->Defined($add),
    '*' => $traits->Defined($mul),
);

my $env = $traits->Trait(
    '+' => $traits->Defined($add),
    '*' => $traits->Defined($mul),
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
    ((+ 5 5) + (* 5 4))
]);

diag "COMPILER:";
diag $_->pprint foreach @$exprs;
diag $_->stringify foreach @$exprs;

diag "ARENA:";
diag format_stats('Terms',  $arena->stats);
#diag format_stats('Hashes', $arena->hashs);

diag "RUNNING:";
my $result = $machine->run( $env, $exprs );

diag "RESULT:";
diag ($result ? $result->stack->stringify : 'UNDEFINED');

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
