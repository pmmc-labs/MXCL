#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- construction --

my $a = $terms->Num(1);
my $b = $terms->Num(2);
my $c = $terms->Num(3);

my $arr = $terms->Array($a, $b, $c);

ok defined($arr), 'Array($a, $b, $c) returns a defined value';

# -- isa checks --

isa_ok $arr, 'MXCL::Term::Array';
isa_ok $arr, 'MXCL::Term';

# -- type --

is $arr->type, 'Array', '->type returns Array';

# -- length --

is $arr->length, 3, '->length returns 3';

# -- at --

is refaddr($arr->at(0)), refaddr($a), '->at(0) returns $a';
is refaddr($arr->at(1)), refaddr($b), '->at(1) returns $b';
is refaddr($arr->at(2)), refaddr($c), '->at(2) returns $c';

# -- empty array --

my $empty = $terms->Array();
isa_ok $empty, 'MXCL::Term::Array';
is $empty->length, 0, 'empty Array has length 0';

# -- interning: same elements -> same refaddr --

my $arr2 = $terms->Array($a, $b, $c);
is refaddr($arr), refaddr($arr2), 'same elements produces same refaddr (interning)';

# -- different elements -> different ref --

my $d = $terms->Num(99);
my $arr3 = $terms->Array($a, $b, $d);
isnt refaddr($arr), refaddr($arr3), 'different elements produces different ref';

done_testing;
