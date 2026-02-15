#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms ];

my $terms = terms;

# -- singleton behavior --

my $t1 = $terms->True;
my $t2 = $terms->True;
is refaddr($t1), refaddr($t2), 'True is a singleton (same refaddr)';

my $f1 = $terms->False;
my $f2 = $terms->False;
is refaddr($f1), refaddr($f2), 'False is a singleton (same refaddr)';

# -- True and False are distinct --

isnt refaddr($t1), refaddr($f1), 'True and False are different refs';
isnt $t1->hash, $f1->hash, 'True and False have different hashes';

# -- Bool() factory --

is refaddr($terms->Bool(1)), refaddr($t1), 'Bool(1) returns True';
is refaddr($terms->Bool(0)), refaddr($f1), 'Bool(0) returns False';

is refaddr($terms->Bool("truthy")), refaddr($t1), 'Bool("truthy") returns True';
is refaddr($terms->Bool("")),       refaddr($f1), 'Bool("") returns False';

# -- isa checks --

isa_ok $t1, 'MXCL::Term::Bool';
isa_ok $f1, 'MXCL::Term::Bool';

# -- type --

is $t1->type, 'Bool', 'True ->type returns Bool';
is $f1->type, 'Bool', 'False ->type returns Bool';

# -- value --

ok  $t1->value, 'True ->value is truthy';
ok !$f1->value, 'False ->value is falsy';

# -- eq --

ok  $t1->eq($terms->True),  'True eq True';
ok  $f1->eq($terms->False), 'False eq False';
ok !$t1->eq($f1),           'True not-eq False';
ok !$f1->eq($t1),           'False not-eq True';

done_testing;
