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

my $hash = $terms->Hash(foo => $a, bar => $b);

ok defined($hash), 'Hash(foo => $a, bar => $b) returns a defined value';

# -- isa checks --

isa_ok $hash, 'MXCL::Term::Hash';
isa_ok $hash, 'MXCL::Term';

# -- type --

is $hash->type, 'Hash', '->type returns Hash';

# -- length --

is $hash->length, 2, '->length returns 2';

# -- get --

is refaddr($hash->get('foo')), refaddr($a), '->get(foo) returns $a';
is refaddr($hash->get('bar')), refaddr($b), '->get(bar) returns $b';

# -- keys (order-independent) --

my @keys = sort $hash->keys;
is_deeply \@keys, [qw(bar foo)], '->keys returns expected key strings';

# -- values --

my @values = sort { refaddr($a) <=> refaddr($b) }  $hash->values;
my @expected = sort { refaddr($a) <=> refaddr($b) } ($a, $b);
is scalar @values, 2, '->values returns 2 values';

# verify both values are present by checking refaddrs
my %got_addrs = map { refaddr($_) => 1 } $hash->values;
ok $got_addrs{ refaddr($a) }, '->values contains $a';
ok $got_addrs{ refaddr($b) }, '->values contains $b';

# -- empty hash --

my $empty = $terms->Hash();
isa_ok $empty, 'MXCL::Term::Hash';
is $empty->length, 0, 'empty Hash has length 0';

# -- interning: same k/v pairs -> same refaddr --

my $hash2 = $terms->Hash(foo => $a, bar => $b);
is refaddr($hash), refaddr($hash2), 'same k/v pairs produces same refaddr (interning)';

# -- interning is key-order independent --

my $hash3 = $terms->Hash(bar => $b, foo => $a);
is refaddr($hash), refaddr($hash3), 'different key order produces same refaddr (arena sorts keys)';

done_testing;
