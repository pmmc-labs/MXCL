#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- basic construction --

my $n42 = $terms->Num(42);
ok defined($n42), 'Num(42) returns a term';

# -- isa --

isa_ok $n42, 'MXCL::Term::Num';

# -- type --

is $n42->type, 'Num', '->type returns Num';

# -- value --

is $n42->value, 42, '->value returns 42';

# -- interning --

my $n42b = $terms->Num(42);
is refaddr($n42), refaddr($n42b), 'Num(42) called twice gives same refaddr';

# -- different values are different refs --

my $n99 = $terms->Num(99);
isnt refaddr($n42), refaddr($n99), 'Num(42) and Num(99) are different refs';
isnt $n42->hash, $n99->hash, 'Num(42) and Num(99) have different hashes';

# -- eq --

ok  $n42->eq($n42b), 'Num(42) eq Num(42)';
ok !$n42->eq($n99),  'Num(42) not-eq Num(99)';

# -- various values --

my $zero = $terms->Num(0);
is $zero->value, 0, 'Num(0) ->value is 0';

my $neg = $terms->Num(-7);
is $neg->value, -7, 'Num(-7) ->value is -7';

my $float = $terms->Num(3.14);
is $float->value, 3.14, 'Num(3.14) ->value is 3.14';

done_testing;
