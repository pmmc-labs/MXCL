#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Traits;

use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;

my $arena  = MXCL::Arena->new;
my $terms  = MXCL::Allocator::Terms->new( arena => $arena );
my $konts  = MXCL::Allocator::Kontinues->new( arena => $arena );
my $traits = MXCL::Allocator::Traits->new( arena => $arena );

my $compiler = MXCL::Compiler->new(
    alloc  => $terms,
    parser => MXCL::Parser->new,
);

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
my $not = lift_native_applicative($terms, [qw[ n ]], sub ($n) { !$n }, 'Bool');



my $EQUALITY = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Defined(
        $terms->NativeOperative(
            $terms->List( $terms->Sym('n'), $terms->Sym('m') ),
            sub ($env, $n, $m) {
                $konts->EvalExpr($env,
                    # (not (n == m))
                    $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('=='), $m )),
                    $terms->Nil
                )
            }
        )
    )
);

my $env = $traits->Trait(
    'not' => $traits->Defined($not),
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

my $exprs = $compiler->compile(q[
    (10 != 10)
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
