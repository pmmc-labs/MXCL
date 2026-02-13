#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Context;

my $ctx = MXCL::Context->new;

my $arena    = $ctx->arena;
my $compiler = $ctx->compiler;

my $exprs = $ctx->compile_source(q[
    ( (1 2 3 4) (1 2 3 4) (1 2 3 4) (1 2 3 4) )
]);

my $env = $ctx->traits->Trait();

push @$exprs => my $obj1 = $ctx->terms->Opaque($env);
push @$exprs => my $obj2 = $ctx->terms->Opaque($env);

my $list = $exprs->[0]->head;
say "YO:", $list->stringify;

say $_->stringify foreach @$exprs;

ok !($obj1->eq($obj2)), '... obj1 and obj2 are not equal';
isnt $obj1->hash, $obj2->hash, '... obj1 and obj2 are not the same hashes';
ok $obj1->env->eq($obj2->env), '... obj1 and obj2 envs are equal';
is $obj1->env->hash, $obj2->env->hash, '... obj1 and obj2 envs are the same hashes';

my $array1 = $ctx->terms->Array( $ctx->terms->Num(1), $ctx->terms->Num(2), $ctx->terms->Num(3) );
my $array2 = $ctx->terms->Array( $ctx->terms->Num(1), $ctx->terms->Num(2), $ctx->terms->Num(3) );
my $array3 = $ctx->terms->Array( $ctx->terms->Num(1), $ctx->terms->Num(2), $ctx->terms->Num(30) );

say $array1->stringify;
say $array2->stringify;
say $array3->stringify;

is $array1->hash, $array2->hash, '... these arrays are equal';
ok $array1->eq($array2), '... these arrays are equal';
isnt $array1->hash, $array3->hash, '... these arrays are NOT equal';
ok !($array1->eq($array3)), '... these arrays are NOT equal';

pass('...shh');

done_testing;


