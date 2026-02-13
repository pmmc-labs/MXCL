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
my $natives  = $ctx->natives;
my $compiler = $ctx->compiler;
my $machine  = $ctx->machine;

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

my $exprs = $ctx->compile_source(q[
    ((+ 5 5) + (* 5 4))
]);

diag "COMPILER:";
diag $_->pprint foreach @$exprs;
diag $_->stringify foreach @$exprs;



diag "RUNNING:";
my $result = $ctx->evaluate( $env, $exprs );


diag "RESULT:";
diag ($result ? $result->stack->stringify : 'UNDEFINED');



pass('...shh');

done_testing;


