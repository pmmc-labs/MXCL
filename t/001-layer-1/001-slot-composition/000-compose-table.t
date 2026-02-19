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

# S1: Required + Required -> Required
subtest 'S1: Required + Required => Required' => sub {
    my $result = $roles->MergeSlot($req, $req);
    isa_ok $result, 'MXCL::Term::Role::Slot::Required', '... result';
    is refaddr($result), refaddr($req), '... same refaddr as input Required (interned)';
};

# S2: Required + Defined -> Defined
subtest 'S2: Required + Defined => Defined' => sub {
    my $result = $roles->MergeSlot($req, $def1);
    isa_ok $result, 'MXCL::Term::Role::Slot::Defined', '... result';
    is refaddr($result), refaddr($def1), '... same refaddr as input Defined (interned)';
};

# S3: Defined + Required -> Defined
subtest 'S3: Defined + Required => Defined' => sub {
    my $result = $roles->MergeSlot($def1, $req);
    isa_ok $result, 'MXCL::Term::Role::Slot::Defined', '... result';
    is refaddr($result), refaddr($def1), '... same refaddr as input Defined (interned)';
};

# S4: Defined + Defined (same content) -> Defined (idempotent)
subtest 'S4: Defined + Defined (same content) => Defined (idempotent)' => sub {
    my $result = $roles->MergeSlot($def1, $def1);
    isa_ok $result, 'MXCL::Term::Role::Slot::Defined', '... result';
    is refaddr($result), refaddr($def1), '... same refaddr as inputs (idempotent, interned)';
};

# S5: Defined + Defined (different content) -> Conflict
subtest 'S5: Defined + Defined (different content) => Conflict' => sub {
    my $result = $roles->MergeSlot($def1, $def2);
    isa_ok $result, 'MXCL::Term::Role::Slot::Conflict', '... result';
    is refaddr($result->lhs), refaddr($def1), '... lhs is the first Defined';
    is refaddr($result->rhs), refaddr($def2), '... rhs is the second Defined';
    is $result->ident->value, 'x', '... ident->value is "x"';
};

done_testing;
