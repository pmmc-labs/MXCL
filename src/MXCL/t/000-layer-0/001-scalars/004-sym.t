#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- basic construction --

my $foo = $terms->Sym("foo");
ok defined($foo), 'Sym("foo") returns a term';

# -- isa --

isa_ok $foo, 'MXCL::Term::Sym';

# -- type --

is $foo->type, 'Sym', '->type returns Sym';

# -- value --

is $foo->value, "foo", '->value returns "foo"';

# -- interning --

my $foo2 = $terms->Sym("foo");
is refaddr($foo), refaddr($foo2), 'same symbol gives same refaddr';

# -- different symbols are different refs --

my $bar = $terms->Sym("bar");
isnt refaddr($foo), refaddr($bar), 'different symbols are different refs';

# -- eq --

ok  $foo->eq($foo2), 'Sym("foo") eq Sym("foo")';
ok !$foo->eq($bar),  'Sym("foo") not-eq Sym("bar")';

# -- Sym("42") is NOT the same as Num(42) --

my $sym42 = $terms->Sym("42");
my $num42 = $terms->Num(42);
isnt refaddr($sym42), refaddr($num42), 'Sym("42") and Num(42) are different refs';
ok !$sym42->eq($num42), 'Sym("42") not-eq Num(42)';

done_testing;
