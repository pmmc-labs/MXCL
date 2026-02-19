#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- singleton behavior --

my $nil1 = $terms->Nil;
my $nil2 = $terms->Nil;

is refaddr($nil1), refaddr($nil2), 'Nil is a singleton (same refaddr)';

# -- isa checks --

isa_ok $nil1, 'MXCL::Term::Nil';
isa_ok $nil1, 'MXCL::Term';

# -- type --

is $nil1->type, 'Nil', '->type returns Nil';

# -- eq --

ok $nil1->eq($nil2), 'Nil eq Nil is true';

# -- hash --

ok defined($nil1->hash), 'Nil has a defined hash';

done_testing;
