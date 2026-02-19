#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ arena terms ];

# --- same type and value => same reference ---

my $a = terms->Num(42);
my $b = terms->Num(42);

is refaddr($a), refaddr($b),
    'same type+value yields same reference (content-addressing)';

is $a->hash, $b->hash,
    '... and same hash';

# --- different values => different references ---

my $c = terms->Num(99);

isnt refaddr($a), refaddr($c),
    'different values yield different references';

isnt $a->hash, $c->hash,
    '... and different hashes';

# --- different types, same underlying value => different hashes ---

my $num42 = terms->Num(42);
my $str42 = terms->Str("42");

isnt $num42->hash, $str42->hash,
    'Num(42) and Str("42") have different hashes (type is part of hash)';

isnt refaddr($num42), refaddr($str42),
    '... and different references';

# --- stats tracking: hits increment on duplicate allocation ---

{
    my $fresh_ctx = MXCL::Context->new;
    my $fa = $fresh_ctx->arena;
    my $ft = $fresh_ctx->terms;

    # statz was cleared by the commit in Context ADJUST,
    # so we start with a clean slate for this generation
    my $before = $fa->statz->{hits} // 0;

    $ft->Num(1);
    my $after_first = $fa->statz->{hits} // 0;

    $ft->Num(1);
    my $after_second = $fa->statz->{hits} // 0;

    is $after_second, $after_first + 1,
        'statz hits increments when allocating a duplicate term';
}

# --- nested term hashing: Cons(Num(1), Nil) allocated twice => same ref ---

my $n1   = terms->Num(1);
my $nil  = terms->Nil;

my $cons1 = terms->Cons($n1, $nil);
my $cons2 = terms->Cons($n1, $nil);

is refaddr($cons1), refaddr($cons2),
    'Cons(Num(1), Nil) allocated twice yields same reference';

is $cons1->hash, $cons2->hash,
    '... and same hash';

# --- nested terms with different sub-terms => different hash ---

my $n2    = terms->Num(2);
my $cons3 = terms->Cons($n2, $nil);

isnt refaddr($cons1), refaddr($cons3),
    'Cons with different head yields different reference';

isnt $cons1->hash, $cons3->hash,
    '... and different hash';

done_testing;
