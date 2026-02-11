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

my $machine = MXCL::Machine->new(
    traits    => $traits,
    terms     => $terms,
    kontinues => $konts,
);

sub lift_native_applicative ($alloc, $params, $body, $returns) {
    return $alloc->NativeApplicative(
        $alloc->List( map $alloc->Sym($_), @$params ),
        sub (@args) { $alloc->$returns( $body->( map $_->value, @args ) ) }
    )
}

sub lift_native_applicative_method ($alloc, $params, $body, $returns) {
    return $alloc->NativeApplicative(
        $alloc->List( map $alloc->Sym($_), @$params ),
        sub ($self, @args) { $alloc->$returns( $body->( $self, map $_->value, @args ) ) }
    )
}

my $add = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n + $m }, 'Num');
my $sub = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n - $m }, 'Num');
my $mul = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n * $m }, 'Num');
my $div = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n / $m }, 'Num');
my $mod = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n % $m }, 'Num');

my $eq  = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n == $m }, 'Bool');


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
    '$ten' => $traits->Defined($terms->Opaque($traits->Trait(
        'add'  => $traits->Defined(lift_native_applicative_method($terms, [qw[ self m ]], sub ($self, $m) { 10 + $m }, 'Num'))
    ))),
);

my $exprs = $compiler->compile(q[
    ($ten add (4 * 5))
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

diag "TRACE:";
diag join "\n" => map { $_->to_string, $_->env->to_string } $machine->trace->@*;

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
