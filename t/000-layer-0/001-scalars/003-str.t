#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- basic construction --

my $hello = $terms->Str("hello");
ok defined($hello), 'Str("hello") returns a term';

# -- isa --

isa_ok $hello, 'MXCL::Term::Str';

# -- type --

is $hello->type, 'Str', '->type returns Str';

# -- value --

is $hello->value, "hello", '->value returns "hello"';

# -- interning --

my $hello2 = $terms->Str("hello");
is refaddr($hello), refaddr($hello2), 'same string gives same refaddr';

# -- different strings are different refs --

my $world = $terms->Str("world");
isnt refaddr($hello), refaddr($world), 'different strings are different refs';

# -- empty string --

my $empty = $terms->Str("");
is $empty->value, "", 'empty string ->value is ""';
isa_ok $empty, 'MXCL::Term::Str';

# -- eq --

ok  $hello->eq($hello2), 'Str("hello") eq Str("hello")';
ok !$hello->eq($world),  'Str("hello") not-eq Str("world")';

done_testing;
