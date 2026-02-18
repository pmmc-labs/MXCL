#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

# -- build test slots --

my $x    = $terms->Sym('x');
my $y    = $terms->Sym('y');
my $def1 = $roles->Defined($x, $terms->Str('v1'));
my $def2 = $roles->Defined($x, $terms->Str('v2'));
my $con  = $roles->Conflict($def1, $def2);

# -- basic construction --

ok defined($con), 'Conflict($def1, $def2) returns a term';

# -- isa checks --

isa_ok $con, 'MXCL::Term::Role::Slot::Conflict';
isa_ok $con, 'MXCL::Term::Role::Slot';
isa_ok $con, 'MXCL::Term';

# -- lhs/rhs accessors --

is refaddr($con->lhs), refaddr($def1), '->lhs returns exact lhs child (refaddr)';
is refaddr($con->rhs), refaddr($def2), '->rhs returns exact rhs child (refaddr)';

# -- ident comes from lhs --

is refaddr($con->ident), refaddr($def1->ident), '->ident refaddr matches lhs->ident';
is refaddr($con->ident), refaddr($x),            '->ident refaddr matches $x';

# -- hash is defined and non-empty --

ok defined($con->hash),  '->hash is defined';
ok length($con->hash),   '->hash is non-empty';

# -- content addressing: same inputs yield same refaddr --

my $con2 = $roles->Conflict($def1, $def2);
is refaddr($con), refaddr($con2), 'same lhs + rhs yields same refaddr (interned)';

# -- order matters: Conflict(A,B) vs Conflict(B,A) have different hashes --

my $con_ba = $roles->Conflict($def2, $def1);
isnt $con->hash, $con_ba->hash, 'Conflict(A,B) and Conflict(B,A) have different hashes';
isnt refaddr($con), refaddr($con_ba), 'Conflict(A,B) and Conflict(B,A) are different objects';

# -- equality --

ok  $con->eq($con2),   '->eq is true for structurally identical Conflicts';
ok !$con->eq($con_ba), '->eq is false when order differs';

my $def3  = $roles->Defined($x, $terms->Str('v3'));
my $con3  = $roles->Conflict($def1, $def3);
ok !$con->eq($con3),   '->eq is false for different rhs';

# -- nested conflict: Conflict(Conflict(A,B), C) --

my $inner   = $roles->Conflict($def1, $def2);
my $def4    = $roles->Defined($x, $terms->Str('v4'));
my $nested  = $roles->Conflict($inner, $def4);

ok defined($nested), 'Conflict(Conflict(A,B), C) constructs successfully';
isa_ok $nested, 'MXCL::Term::Role::Slot::Conflict';
is refaddr($nested->lhs), refaddr($inner), 'nested->lhs is the inner Conflict';
is refaddr($nested->rhs), refaddr($def4),  'nested->rhs is the outer defined slot';
is refaddr($nested->ident), refaddr($x),   'nested->ident is $x (from lhs->ident)';

# -- invariant check: mismatched idents must die --

my $z    = $terms->Sym('z');
my $defz = $roles->Defined($z, $terms->Str('vz'));

eval { $roles->Conflict($def1, $defz) };
ok $@, 'constructing Conflict with mismatched idents dies';
like $@, qr/Conflicted ident must be equal/, 'error message matches expected';

# -- pprint --

my $pp = $con->pprint;
ok defined($pp) && length($pp), '->pprint returns a non-empty string';
like $pp, qr/conflicted:/, '->pprint contains "conflicted:"';

done_testing;
