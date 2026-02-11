#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Environments;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Traits;

use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;

my $arena  = MXCL::Arena->new;
my $terms  = MXCL::Allocator::Terms->new( arena => $arena );
my $envs   = MXCL::Allocator::Environments->new( arena => $arena );
my $konts  = MXCL::Allocator::Kontinues->new( arena => $arena );
my $traits = MXCL::Allocator::Traits->new( arena => $arena );

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


my $env = $traits->Trait('main::',
    '==' => $eq,
    'MXCL::Term::Num' => $traits->Trait('Numeric',
        '+'  => $add,
        '-'  => $sub,
        '*'  => $mul,
        '/'  => $div,
        '%'  => $mod,
    ),
    '$ten' => $terms->Opaque($traits->Trait('Numeric',
        'add'  => lift_native_applicative_method($terms, [qw[ self m ]], sub ($self, $m) { 10 + $m }, 'Num')
    )),
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
