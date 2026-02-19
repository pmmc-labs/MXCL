#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

my $nil = $terms->Nil;

# -- List() with no args returns Nil --

my $empty = $terms->List();
is refaddr($empty), refaddr($nil), 'List() with no args returns Nil (same ref)';

# -- List($a) returns Cons($a, Nil) --

my $a = $terms->Num(10);
my $single = $terms->List($a);

isa_ok $single, 'MXCL::Term::Cons';
is refaddr($single->head), refaddr($a), 'List($a)->head is $a';
isa_ok $single->tail, 'MXCL::Term::Nil', 'List($a)->tail is Nil';

# -- List($a, $b, $c) returns nested Cons --

my $b = $terms->Num(20);
my $c = $terms->Num(30);

my $list = $terms->List($a, $b, $c);

isa_ok $list, 'MXCL::Term::Cons';
is refaddr($list->head), refaddr($a), 'first element is $a';

my $rest1 = $list->tail;
isa_ok $rest1, 'MXCL::Term::Cons';
is refaddr($rest1->head), refaddr($b), 'second element is $b';

my $rest2 = $rest1->tail;
isa_ok $rest2, 'MXCL::Term::Cons';
is refaddr($rest2->head), refaddr($c), 'third element is $c';

isa_ok $rest2->tail, 'MXCL::Term::Nil', 'tail after third element is Nil';

# -- Uncons --

my @items = $terms->Uncons($list);
is scalar @items, 3, 'Uncons returns 3 items';
is refaddr($items[0]), refaddr($a), 'Uncons first item is $a';
is refaddr($items[1]), refaddr($b), 'Uncons second item is $b';
is refaddr($items[2]), refaddr($c), 'Uncons third item is $c';

# -- Round-trip: Uncons(List(@items)) returns original items --

my @originals = ($terms->Str("x"), $terms->Str("y"), $terms->Str("z"));
my $roundtrip_list = $terms->List(@originals);
my @recovered = $terms->Uncons($roundtrip_list);

is scalar @recovered, scalar @originals, 'round-trip preserves count';
for my $i (0 .. $#originals) {
    ok $recovered[$i]->eq($originals[$i]),
        "round-trip item $i eq original";
}

# -- Append --

my $list1 = $terms->List($terms->Num(1), $terms->Num(2));
my $list2 = $terms->List($terms->Num(3), $terms->Num(4));

my $appended = $terms->Append($list1, $list2);
my @app_items = $terms->Uncons($appended);

is scalar @app_items, 4, 'Append produces 4 items';
is $app_items[0]->value, 1, 'appended item 0 is 1';
is $app_items[1]->value, 2, 'appended item 1 is 2';
is $app_items[2]->value, 3, 'appended item 2 is 3';
is $app_items[3]->value, 4, 'appended item 3 is 4';

# -- List interning: same terms -> same refaddr --

my $x = $terms->Num(42);
my $y = $terms->Num(43);

my $l1 = $terms->List($x, $y);
my $l2 = $terms->List($x, $y);
is refaddr($l1), refaddr($l2), 'List with same terms produces same refaddr (interning)';

done_testing;
