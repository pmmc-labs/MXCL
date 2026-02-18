#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;

use MXCL::Context;

my $context = MXCL::Context->new;

my $terms = $context->terms;
my $roles = $context->roles;

# ...

my $EQ = $roles->Role(
    $roles->Required( $terms->Sym('==') ),
    $roles->Defined( $terms->Sym('!='), $terms->Str('(not (x == y))') ),
);

my $ORD = $roles->Role(
    $roles->Required( $terms->Sym('==') ),
    $roles->Required( $terms->Sym('<') ),
    $roles->Defined( $terms->Sym('!='), $terms->Str('(not (x == y))') ),
    $roles->Defined( $terms->Sym('>') , $terms->Str('((x != y) and (not (x < y))') ),
    $roles->Defined( $terms->Sym('<='), $terms->Str('((x == y) or (x < y))') ),
    $roles->Defined( $terms->Sym('>='), $terms->Str('((x == y) or (x > y))') ),
);

my $NUM = $roles->Role(
    $roles->Defined( $terms->Sym('=='), $terms->Str('(eq? x y)') ),
    $roles->Defined( $terms->Sym('<'),  $terms->Str('(gt? x y)') ),
    $roles->Defined( $terms->Sym('+'),  $terms->Str('(add x y)') ),
    $roles->Defined( $terms->Sym('-'),  $terms->Str('(sub x y)') ),
    $roles->Defined( $terms->Sym('*'),  $terms->Str('(mul x y)') ),
    $roles->Defined( $terms->Sym('/'),  $terms->Str('(div x y)') ),
    $roles->Defined( $terms->Sym('%'),  $terms->Str('(mod x y)') ),
);

my $STR = $roles->Role(
    $roles->Defined( $terms->Sym('=='), $terms->Str('(eq? x y)') ),
    $roles->Defined( $terms->Sym('<'),  $terms->Str('(gt? x y)') ),
    $roles->Defined( $terms->Sym('~'),  $terms->Str('(concat x y)') ),
);

#diag 'EQ : ', $EQ->pprint;
#diag 'ORD : ', $ORD->pprint;

#diag 'EQ + ORD : ', $roles->Union( $ORD, $EQ )->pprint;
#diag 'ORD + EQ : ', $roles->Union( $EQ, $ORD )->pprint;

ok $roles->Union( $ORD, $EQ )
        ->is_equal( $roles->Union( $EQ, $ORD ) ),
            '... EQ <+> ORD';

#diag 'ORD - EQ : ', $roles->SymmetricDifference( $ORD, $EQ )->pprint;
#diag 'EQ - ORD : ', $roles->SymmetricDifference( $EQ, $ORD )->pprint;

ok $roles->SymmetricDifference( $ORD, $EQ )
        ->is_equal( $roles->SymmetricDifference( $EQ, $ORD ) ),
            '... EQ <-> ORD';

#diag 'ORD > EQ : ', $roles->AsymmetricDifference( $ORD, $EQ )->pprint;
#diag 'EQ > ORD : ', $roles->AsymmetricDifference( $EQ, $ORD )->pprint;

ok $roles->AsymmetricDifference( $ORD, $EQ )
        ->is_equal( $roles->AsymmetricDifference( $EQ, $ORD ) ),
            '... EQ >< ORD';

#diag 'ORD * EQ : ', $roles->Intersection( $ORD, $EQ )->pprint;
#diag 'EQ * ORD : ', $roles->Intersection( $EQ, $ORD )->pprint;

ok $roles->Intersection( $ORD, $EQ )
        ->is_equal( $roles->Intersection( $EQ, $ORD ) ),
            '... EQ <*> ORD';

#diag 'NUM + (ORD + EQ) : ', $roles->Union( $NUM, $roles->Union( $ORD, $EQ ) )->pprint;
#diag 'STR + (ORD + EQ) : ', $roles->Union( $STR, $roles->Union( $ORD, $EQ ) )->pprint;
#diag 'NUM - (ORD + EQ) : ', $roles->Intersection( $NUM, $roles->Union( $ORD, $EQ ) )->pprint;

done_testing;
