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

# ...

is $roles->Union( $ORD, $EQ )->hash,
   $roles->Union( $EQ, $ORD )->hash, '... hashing is order independent';

ok $roles->Union( $ORD, $EQ )
        ->is_equal( $roles->Union( $EQ, $ORD ) ),
            '... EQ <+> ORD';

# ...

is $roles->SymmetricDifference( $ORD, $EQ )->hash,
   $roles->SymmetricDifference( $EQ, $ORD )->hash, '... hashing is order independent';

ok $roles->SymmetricDifference( $ORD, $EQ )
        ->is_equal( $roles->SymmetricDifference( $EQ, $ORD ) ),
            '... EQ <-> ORD';

# ...

is $roles->AsymmetricDifference( $ORD, $EQ )->hash,
   $roles->AsymmetricDifference( $EQ, $ORD )->hash, '... hashing is order independent';

ok $roles->AsymmetricDifference( $ORD, $EQ )
        ->is_equal( $roles->AsymmetricDifference( $EQ, $ORD ) ),
            '... EQ >< ORD';

# ...

is $roles->Intersection( $ORD, $EQ )->hash,
   $roles->Intersection( $EQ, $ORD )->hash, '... hashing is order independent';

ok $roles->Intersection( $ORD, $EQ )
        ->is_equal( $roles->Intersection( $EQ, $ORD ) ),
            '... EQ <*> ORD';

# ...

is $roles->Union( $NUM, $roles->Union( $ORD, $EQ ) )->hash,
   $roles->Union( $NUM, $roles->Union( $EQ, $ORD ) )->hash, '... hashing is order independent';

ok $roles->Union( $NUM, $roles->Union( $ORD, $EQ ) )
        ->is_equal( $roles->Union( $NUM, $roles->Union( $EQ, $ORD ) ) ),
            '... NUM + EQ + ORD';

is $roles->Union( $NUM, $roles->Union( $ORD, $EQ ) )->hash,
   $roles->Union( $ORD, $roles->Union( $EQ, $NUM ) )->hash, '... hashing is order independent';

ok $roles->Union( $NUM, $roles->Union( $ORD, $EQ ) )
        ->is_equal( $roles->Union( $ORD, $roles->Union( $EQ, $NUM ) ) ),
            '... NUM + EQ + ORD';

# ...

is $roles->Union( $STR, $roles->Union( $ORD, $EQ ) )->hash,
   $roles->Union( $STR, $roles->Union( $EQ, $ORD ) )->hash, '... hashing is order independent';

ok $roles->Union( $STR, $roles->Union( $ORD, $EQ ) )
        ->is_equal( $roles->Union( $STR, $roles->Union( $EQ, $ORD ) ) ),
            '... STR + EQ + ORD';

is $roles->Union( $STR, $roles->Union( $ORD, $EQ ) )->hash,
   $roles->Union( $ORD, $roles->Union( $EQ, $STR ) )->hash, '... hashing is order independent';

ok $roles->Union( $STR, $roles->Union( $ORD, $EQ ) )
        ->is_equal( $roles->Union( $ORD, $roles->Union( $EQ, $STR ) ) ),
            '... STR + EQ + ORD';
# ...

done_testing;
