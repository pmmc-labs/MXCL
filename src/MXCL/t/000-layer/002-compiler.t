#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Environments;
use MXCL::Compiler;

my $arena = MXCL::Arena->new;

my $compiler = MXCL::Compiler->new(
    alloc  => MXCL::Allocator::Terms->new( arena => $arena ),
    parser => MXCL::Parser->new,
);

my $envs = MXCL::Allocator::Environments->new( arena => $arena );

my $exprs = $compiler->compile(q[
    ( (1 2 3 4) (1 2 3 4) (1 2 3 4) (1 2 3 4) )
]);

my $env = $envs->Env();

push @$exprs => my $obj1 = $compiler->alloc->Opaque($env);
push @$exprs => my $obj2 = $compiler->alloc->Opaque($env);

my $list = $exprs->[0]->head;
say "YO:", $list->to_string;

say $_->to_string foreach @$exprs;

ok !($obj1->eq($obj2)), '... obj1 and obj2 are not equal';
isnt $obj1->hash, $obj2->hash, '... obj1 and obj2 are not the same hashes';
ok $obj1->env->eq($obj2->env), '... obj1 and obj2 envs are equal';
is $obj1->env->hash, $obj2->env->hash, '... obj1 and obj2 envs are the same hashes';

my $array1 = $compiler->alloc->Array( $compiler->alloc->Num(1), $compiler->alloc->Num(2), $compiler->alloc->Num(3) );
my $array2 = $compiler->alloc->Array( $compiler->alloc->Num(1), $compiler->alloc->Num(2), $compiler->alloc->Num(3) );
my $array3 = $compiler->alloc->Array( $compiler->alloc->Num(1), $compiler->alloc->Num(2), $compiler->alloc->Num(30) );

say $array1->to_string;
say $array2->to_string;
say $array3->to_string;

is $array1->hash, $array2->hash, '... these arrays are equal';
ok $array1->eq($array2), '... these arrays are equal';
isnt $array1->hash, $array3->hash, '... these arrays are NOT equal';
ok !($array1->eq($array3)), '... these arrays are NOT equal';

diag "ARENA:";
diag format_stats('Terms',  $arena->stats);
diag format_stats('Hashes', $arena->hashs);

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
