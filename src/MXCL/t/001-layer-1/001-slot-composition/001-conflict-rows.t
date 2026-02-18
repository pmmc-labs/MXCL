#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

my $x    = $terms->Sym('x');
my $req  = $roles->Required($x);
my $def1 = $roles->Defined($x, $terms->Str('v1'));
my $def2 = $roles->Defined($x, $terms->Str('v2'));
my $def3 = $roles->Defined($x, $terms->Str('v3'));
my $def4 = $roles->Defined($x, $terms->Str('v4'));
my $c    = $roles->Conflict($def1, $def2);  # used in S6, S7, S8, S9
my $c1   = $roles->Conflict($def1, $def2);  # same object as $c (content-addressed)
my $c2   = $roles->Conflict($def3, $def4);  # used in S10

# S6: Required + Conflict -> Conflict (unchanged)
# Required is the identity element; result is the same Conflict object
subtest 'S6: Required + Conflict => Conflict (unchanged)' => sub {
    my $result = $roles->MergeSlot($req, $c);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result), refaddr($c), '... same refaddr as the input Conflict (Required is identity)';
};

# S7: Conflict + Required -> Conflict (unchanged)
# Mirror of S6; Required on the right is also identity
subtest 'S7: Conflict + Required => Conflict (unchanged)' => sub {
    my $result = $roles->MergeSlot($c, $req);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result), refaddr($c), '... same refaddr as the input Conflict (Required is identity)';
};

# S8: Defined + Conflict -> Conflict (wraps: Con(Def, Con))
# A new Conflict is created with the Defined on the lhs and the existing Conflict on the rhs
subtest 'S8: Defined + Conflict => Conflict (wraps)' => sub {
    my $result = $roles->MergeSlot($def3, $c);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result->lhs), refaddr($def3), '... lhs is the input Defined';
    is refaddr($result->rhs), refaddr($c),    '... rhs is the input Conflict';
    is $result->ident->value, 'x',            '... ident->value is "x"';
};

# S9: Conflict + Defined -> Conflict (wraps: Con(Con, Def))
# Mirror of S8; the existing Conflict lands on the lhs
subtest 'S9: Conflict + Defined => Conflict (wraps)' => sub {
    my $result = $roles->MergeSlot($c, $def3);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result->lhs), refaddr($c),    '... lhs is the input Conflict';
    is refaddr($result->rhs), refaddr($def3), '... rhs is the input Defined';
    is $result->ident->value, 'x',            '... ident->value is "x"';
};

# S10: Conflict + Conflict -> Conflict (wraps both: Con(Con1, Con2))
# Both existing Conflict nodes are wrapped in a new Conflict
subtest 'S10: Conflict + Conflict => Conflict (wraps both)' => sub {
    # verify $c and $c1 are the same interned object
    is refaddr($c), refaddr($c1), '... $c and $c1 are the same interned object';

    my $result = $roles->MergeSlot($c1, $c2);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result->lhs), refaddr($c1), '... lhs is the first input Conflict';
    is refaddr($result->rhs), refaddr($c2), '... rhs is the second input Conflict';
    is $result->ident->value, 'x',          '... ident->value is "x"';

    # verify the overall 4-leaf structure at depth 2
    isa_ok $result->lhs, 'MXCL::Term::Role::Slot::Conflict', '... lhs is a Conflict';
    isa_ok $result->rhs, 'MXCL::Term::Role::Slot::Conflict', '... rhs is a Conflict';
    is refaddr($result->lhs->lhs), refaddr($def1), '... lhs->lhs is def1';
    is refaddr($result->lhs->rhs), refaddr($def2), '... lhs->rhs is def2';
    is refaddr($result->rhs->lhs), refaddr($def3), '... rhs->lhs is def3';
    is refaddr($result->rhs->rhs), refaddr($def4), '... rhs->rhs is def4';
};

done_testing;
