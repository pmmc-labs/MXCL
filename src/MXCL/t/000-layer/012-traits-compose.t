#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Traits;

my $arena  = MXCL::Arena->new;
my $terms  = MXCL::Allocator::Terms->new( arena => $arena );
my $konts  = MXCL::Allocator::Kontinues->new( arena => $arena );
my $traits = MXCL::Allocator::Traits->new( arena => $arena );

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

my $bool_eq  = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n == $m }, 'Bool');
my $bool_ne  = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n != $m }, 'Bool');

my $num_eq   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n == $m }, 'Bool');
my $num_ne   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n != $m }, 'Bool');
my $num_gt   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'Bool');
my $num_ge   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'Bool');
my $num_lt   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'Bool');
my $num_le   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'Bool');

my $str_eq   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n == $m }, 'Bool');
my $str_ne   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n != $m }, 'Bool');
my $str_gt   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'Bool');
my $str_ge   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'Bool');
my $str_lt   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'Bool');
my $str_le   = lift_native_applicative($terms, [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'Bool');

# ... CORE trait signatures

my $EQUALITY = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Required,
);

$my ORDERED = $traits->Trait(
    '==' => $traits->Required,
    '!=' => $traits->Required,
    '>'  => $traits->Required,
    '>=' => $traits->Required,
    '<'  => $traits->Required,
    '<=' => $traits->Required,
);

# ... Operative Functors

my $EQ = $terms->NativeOperative(
    $terms->List( $terms->Sym('T') ),
    sub ($env, $t) {
        return $konts->Return( $env, $terms->List(
            $traits->Compose($EQUALITY, $t)
        ))
    }
);

my $ORD = $terms->NativeOperative(
    $terms->List( $terms->Sym('T') ),
    sub ($env, $t) {
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
        '!=' => $traits->Defined($bool_ne),
    )
);

my $Num = $traits->Compose(
    $ORDERED,
    $traits->Compose(
        $EQUALITY,
        $traits->Trait(
            '==' => $traits->Defined($num_eq),
            '!=' => $traits->Defined($num_ne),
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
            '!=' => $traits->Defined($str_ne),
            '>'  => $traits->Defined($str_gt),
            '>=' => $traits->Defined($str_ge),
            '<'  => $traits->Defined($str_lt),
            '<=' => $traits->Defined($str_le),
        )
    )
);


say $EQUALITY->to_string;
say $Bool->to_string;
say $Num->to_string;
say $Str->to_string;

done_testing;

