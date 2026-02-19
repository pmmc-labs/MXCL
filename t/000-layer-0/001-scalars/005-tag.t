#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- basic construction --

my $foo = $terms->Tag("foo");
ok defined($foo), 'Tag("foo") returns a term';

# -- isa --

isa_ok $foo, 'MXCL::Term::Tag';

# -- type --

is $foo->type, 'Tag', '->type returns Tag';

# -- value --

is $foo->value, "foo", '->value returns "foo"';

# -- interning --

my $foo2 = $terms->Tag("foo");
is refaddr($foo), refaddr($foo2), 'same tag gives same refaddr';

# -- different tags are different refs --

my $bar = $terms->Tag("bar");
isnt refaddr($foo), refaddr($bar), 'different tags are different refs';

# -- eq --

ok  $foo->eq($foo2), 'Tag("foo") eq Tag("foo")';
ok !$foo->eq($bar),  'Tag("foo") not-eq Tag("bar")';

# -- Tag("foo") is NOT the same as Sym("foo") --

my $sym_foo = $terms->Sym("foo");
isnt refaddr($foo), refaddr($sym_foo), 'Tag("foo") and Sym("foo") are different refs';
isnt $foo->hash, $sym_foo->hash, 'Tag("foo") and Sym("foo") have different hashes';
ok !$foo->eq($sym_foo), 'Tag("foo") not-eq Sym("foo")';

done_testing;
