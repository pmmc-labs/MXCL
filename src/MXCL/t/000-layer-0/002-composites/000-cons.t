#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- construction --

my $nil  = $terms->Nil;
my $head = $terms->Num(1);
my $tail = $terms->Nil;
my $cons = $terms->Cons($head, $tail);

ok defined($cons), 'Cons($head, $tail) returns a defined value';

# -- isa checks --

isa_ok $cons, 'MXCL::Term::Cons';
isa_ok $cons, 'MXCL::Term';

# -- type --

is $cons->type, 'Cons', '->type returns Cons';

# -- accessors --

is refaddr($cons->head), refaddr($head), '->head returns the head term';
is refaddr($cons->tail), refaddr($tail), '->tail returns the tail term';

# -- interning: same head+tail -> same refaddr --

my $cons2 = $terms->Cons($head, $tail);
is refaddr($cons), refaddr($cons2), 'same head+tail produces same refaddr (interning)';

# -- different children -> different ref --

my $other_head = $terms->Num(99);
my $cons3 = $terms->Cons($other_head, $tail);
isnt refaddr($cons), refaddr($cons3), 'different head produces different ref';

my $other_tail = $terms->Cons($terms->Num(5), $nil);
my $cons4 = $terms->Cons($head, $other_tail);
isnt refaddr($cons), refaddr($cons4), 'different tail produces different ref';

# -- manual chain: Cons(Num(1), Cons(Num(2), Nil)) --

my $n1 = $terms->Num(1);
my $n2 = $terms->Num(2);

my $chain = $terms->Cons($n1, $terms->Cons($n2, $nil));

isa_ok $chain, 'MXCL::Term::Cons';
is refaddr($chain->head), refaddr($n1), 'chain head is Num(1)';

my $inner = $chain->tail;
isa_ok $inner, 'MXCL::Term::Cons';
is refaddr($inner->head), refaddr($n2), 'chain tail head is Num(2)';

isa_ok $inner->tail, 'MXCL::Term::Nil', 'chain tail tail is Nil';

# -- uncons on the chain --

my @items = $chain->uncons;
is scalar @items, 2, 'uncons returns 2 items';
is refaddr($items[0]), refaddr($n1), 'uncons first item is Num(1)';
is refaddr($items[1]), refaddr($n2), 'uncons second item is Num(2)';

done_testing;
