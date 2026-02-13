#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Context;

my $ctx = MXCL::Context->new;

my $arena    = $ctx->arena;
my $terms    = $ctx->terms;
my $konts    = $ctx->kontinues;
my $refs     = $ctx->refs;
my $traits   = $ctx->traits;
my $natives  = $ctx->natives;
my $compiler = $ctx->compiler;
my $machine  = $ctx->machine;

sub lift_native_applicative ($name, $params, $returns, $impl) {
    return $natives->Applicative(
        name      => $name,
        signature => $params,
        returns   => $returns,
        impl      => $impl,
    )
}

my $bool_eq  = lift_native_applicative('bool:eq', [{ name => 'n', coerce => 'boolify' }, { name => 'm', coerce => 'boolify' }], 'Bool', sub ($n, $m) { $n == $m });
my $bool_ne  = lift_native_applicative('bool:ne', [{ name => 'n', coerce => 'boolify' }, { name => 'm', coerce => 'boolify' }], 'Bool', sub ($n, $m) { $n != $m });

my $num_eq   = lift_native_applicative('num:eq', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n == $m });
my $num_ne   = lift_native_applicative('num:ne', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n != $m });
my $num_gt   = lift_native_applicative('num:gt', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n >  $m });
my $num_ge   = lift_native_applicative('num:ge', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n >= $m });
my $num_lt   = lift_native_applicative('num:lt', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n <  $m });
my $num_le   = lift_native_applicative('num:le', [{ name => 'n', coerce => 'numify' }, { name => 'm', coerce => 'numify' }], 'Bool', sub ($n, $m) { $n <= $m });

my $str_eq   = lift_native_applicative('str:eq', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n == $m });
my $str_ne   = lift_native_applicative('str:ne', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n != $m });
my $str_gt   = lift_native_applicative('str:gt', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n >  $m });
my $str_ge   = lift_native_applicative('str:ge', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n >= $m });
my $str_lt   = lift_native_applicative('str:lt', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n <  $m });
my $str_le   = lift_native_applicative('str:le', [{ name => 'n', coerce => 'stringify' }, { name => 'm', coerce => 'stringify' }], 'Bool', sub ($n, $m) { $n <= $m });

# ... CORE trait signatures

my $EQUALITY = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Defined(
        $natives->Operative(
            name => 'EQUALITY::ne',
            signature => [
                { name => 'n' },
                { name => 'm' },
            ],
            impl => sub ($ctx, $n, $m) {
                $konts->EvalExpr($ctx,
                    # (not (n == m))
                    $terms->List($terms->Sym('not'), $terms->List( $n, $terms->Sym('=='), $m )),
                    $terms->Nil
                )
            }
        )
    )
);

my $ORDERED = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Required,
    '>'  => $traits->Required,
    '>=' => $traits->Required,
    '<'  => $traits->Required,
    '<=' => $traits->Required,
);

# ... Operative Functors

my $EQ = $natives->Operative(
    name      => 'EQ::create',
    signature => [ { name => 'T' } ],
    impl      => sub ($env, $t) {
        return $konts->Return( $env, $terms->List(
            $traits->Compose($EQUALITY, $t)
        ))
    }
);

my $ORD = $natives->Operative(
    name      => 'ORD::create',
    signature => [ { name => 'T' } ],
    impl      => sub ($env, $t) {
        return $konts->Return( $env, $terms->List(
            $traits->Compose($ORDERED, $t)
        ))
    }
);

# ... composed core traits ....

my $Bool = $traits->Compose(
    $EQUALITY,
    $traits->Trait(
        '==' => $traits->Defined($bool_eq),
        #'!=' => $traits->Defined($bool_ne),
    )
);

my $Num = $traits->Compose(
    $ORDERED,
    $traits->Compose(
        $EQUALITY,
        $traits->Trait(
            '==' => $traits->Defined($num_eq),
            #'!=' => $traits->Defined($num_ne),
            '>'  => $traits->Defined($num_gt),
            '>=' => $traits->Defined($num_ge),
            '<'  => $traits->Defined($num_lt),
            '<=' => $traits->Defined($num_le),
        )
    )
);

my $Str = $traits->Compose(
    $ORDERED,
    $traits->Compose(
        $EQUALITY,
        $traits->Trait(
            '==' => $traits->Defined($str_eq),
            #'!=' => $traits->Defined($str_ne),
            '>'  => $traits->Defined($str_gt),
            '>=' => $traits->Defined($str_ge),
            '<'  => $traits->Defined($str_lt),
            '<=' => $traits->Defined($str_le),
        )
    )
);


say $EQUALITY->stringify;
say $Bool->stringify;
say $Num->stringify;
say $Str->stringify;

pass('...shhh');

done_testing;

