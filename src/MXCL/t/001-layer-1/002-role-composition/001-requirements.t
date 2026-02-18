#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

# -- fixtures --

my $RA = $roles->Role(
    $roles->Defined($terms->Sym('m1'), $terms->Str('RA::m1')),
    $roles->Defined($terms->Sym('m2'), $terms->Str('RA::m2')),
);

my $RB = $roles->Role(
    $roles->Defined($terms->Sym('m2'), $terms->Str('RB::m2')),
    $roles->Defined($terms->Sym('m3'), $terms->Str('RB::m3')),
);

my $RC = $roles->Role(
    $roles->Defined($terms->Sym('m3'), $terms->Str('RC::m3')),
    $roles->Defined($terms->Sym('m4'), $terms->Str('RC::m4')),
);

my $RReqM1 = $roles->Role(
    $roles->Required($terms->Sym('m1')),
    $roles->Defined($terms->Sym('r1'), $terms->Str('r1:body')),
);

my $RReqM2 = $roles->Role(
    $roles->Required($terms->Sym('m2')),
    $roles->Defined($terms->Sym('r2'), $terms->Str('r2:body')),
);

my $RReqM1M2 = $roles->Role(
    $roles->Required($terms->Sym('m1')),
    $roles->Required($terms->Sym('m2')),
    $roles->Defined($terms->Sym('r12'), $terms->Str('r12:body')),
);

my $RCircA = $roles->Role(
    $roles->Required($terms->Sym('n')),
    $roles->Defined($terms->Sym('m'), $terms->Str('RCircA::m')),
);

my $RCircB = $roles->Role(
    $roles->Required($terms->Sym('m')),
    $roles->Defined($terms->Sym('n'), $terms->Str('RCircB::n')),
);

# -- R3: Requirement met --
# Union(RA, RReqM1): RA provides m1 Defined, which satisfies RReqM1's Required(m1)
# Expected 3 slots, 0 Required: m1 Defined "RA::m1", m2 Defined "RA::m2", r1 Defined "r1:body"

subtest 'R3: Requirement met - Union(RA, RReqM1)' => sub {
    my $result = $roles->Union($RA, $RReqM1);

    is $result->size, 3, '... size is 3';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $r1 = $result->lookup('r1');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($r1), '... r1 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined', '... m1';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Defined', '... m2';
    isa_ok $r1, 'MXCL::Term::Role::Slot::Defined', '... r1';

    is $m1->value->value, 'RA::m1',  '... m1 value is "RA::m1"';
    is $m2->value->value, 'RA::m2',  '... m2 value is "RA::m2"';
    is $r1->value->value, 'r1:body', '... r1 value is "r1:body"';
};

# -- R4: Requirement unmet --
# Union(RB, RReqM1): RB does not provide m1, so Required(m1) propagates
# Expected 4 slots, 1 Required: m1 Required, m2 Defined "RB::m2", m3 Defined "RB::m3", r1 Defined "r1:body"

subtest 'R4: Requirement unmet - Union(RB, RReqM1)' => sub {
    my $result = $roles->Union($RB, $RReqM1);

    is $result->size, 4, '... size is 4';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m3 = $result->lookup('m3');
    my $r1 = $result->lookup('r1');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';
    ok defined($r1), '... r1 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Required', '... m1 is Required (unmet)';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Defined',  '... m2 is Defined';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';
    isa_ok $r1, 'MXCL::Term::Role::Slot::Defined',  '... r1 is Defined';

    is $m2->value->value, 'RB::m2',  '... m2 value is "RB::m2"';
    is $m3->value->value, 'RB::m3',  '... m3 value is "RB::m3"';
    is $r1->value->value, 'r1:body', '... r1 value is "r1:body"';
};

# -- R5: Multiple requirements, all met --
# Union(RA, RReqM1M2): RA provides both m1 and m2, satisfying all requirements
# Expected 3 slots, 0 Required: m1 Defined "RA::m1", m2 Defined "RA::m2", r12 Defined "r12:body"

subtest 'R5: Multiple requirements, all met - Union(RA, RReqM1M2)' => sub {
    my $result = $roles->Union($RA, $RReqM1M2);

    is $result->size, 3, '... size is 3';

    my $m1  = $result->lookup('m1');
    my $m2  = $result->lookup('m2');
    my $r12 = $result->lookup('r12');

    ok defined($m1),  '... m1 slot exists';
    ok defined($m2),  '... m2 slot exists';
    ok defined($r12), '... r12 slot exists';

    isa_ok $m1,  'MXCL::Term::Role::Slot::Defined', '... m1 is Defined';
    isa_ok $m2,  'MXCL::Term::Role::Slot::Defined', '... m2 is Defined';
    isa_ok $r12, 'MXCL::Term::Role::Slot::Defined', '... r12 is Defined';

    is $m1->value->value,  'RA::m1',   '... m1 value is "RA::m1"';
    is $m2->value->value,  'RA::m2',   '... m2 value is "RA::m2"';
    is $r12->value->value, 'r12:body', '... r12 value is "r12:body"';
};

# -- R6: Multiple requirements, none met --
# Union(RC, RReqM1M2): RC provides m3 and m4, neither m1 nor m2 -- both Required propagate
# Expected 5 slots, 2 Required: m1 Required, m2 Required, m3 Defined "RC::m3", m4 Defined "RC::m4", r12 Defined "r12:body"

subtest 'R6: Multiple requirements, none met - Union(RC, RReqM1M2)' => sub {
    my $result = $roles->Union($RC, $RReqM1M2);

    is $result->size, 5, '... size is 5';

    my $m1  = $result->lookup('m1');
    my $m2  = $result->lookup('m2');
    my $m3  = $result->lookup('m3');
    my $m4  = $result->lookup('m4');
    my $r12 = $result->lookup('r12');

    ok defined($m1),  '... m1 slot exists';
    ok defined($m2),  '... m2 slot exists';
    ok defined($m3),  '... m3 slot exists';
    ok defined($m4),  '... m4 slot exists';
    ok defined($r12), '... r12 slot exists';

    isa_ok $m1,  'MXCL::Term::Role::Slot::Required', '... m1 is Required (unmet)';
    isa_ok $m2,  'MXCL::Term::Role::Slot::Required', '... m2 is Required (unmet)';
    isa_ok $m3,  'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';
    isa_ok $m4,  'MXCL::Term::Role::Slot::Defined',  '... m4 is Defined';
    isa_ok $r12, 'MXCL::Term::Role::Slot::Defined',  '... r12 is Defined';

    is $m3->value->value,  'RC::m3',   '... m3 value is "RC::m3"';
    is $m4->value->value,  'RC::m4',   '... m4 value is "RC::m4"';
    is $r12->value->value, 'r12:body', '... r12 value is "r12:body"';
};

# -- R7: Mutual satisfaction (circular requirements) --
# Union(RCircA, RCircB):
#   RCircA: Required(n), Defined(m, "RCircA::m")
#   RCircB: Required(m), Defined(n, "RCircB::n")
# Each satisfies the other's requirement
# Expected 2 slots, 0 Required: m Defined "RCircA::m", n Defined "RCircB::n"

subtest 'R7: Mutual satisfaction - Union(RCircA, RCircB)' => sub {
    my $result = $roles->Union($RCircA, $RCircB);

    is $result->size, 2, '... size is 2';

    my $m = $result->lookup('m');
    my $n = $result->lookup('n');

    ok defined($m), '... m slot exists';
    ok defined($n), '... n slot exists';

    isa_ok $m, 'MXCL::Term::Role::Slot::Defined', '... m is Defined';
    isa_ok $n, 'MXCL::Term::Role::Slot::Defined', '... n is Defined';

    is $m->value->value, 'RCircA::m', '... m value is "RCircA::m"';
    is $n->value->value, 'RCircB::n', '... n value is "RCircB::n"';
};

# -- R8: Requirement meets a conflict (Required is identity, conflict persists) --
# inner = Union(RA, RB):
#   m1: Defined "RA::m1"
#   m2: Conflict(Defined(RA::m2), Defined(RB::m2))
#   m3: Defined "RB::m3"
# Then Union(RReqM2, inner):
#   RReqM2 has Required(m2) and Defined(r2, "r2:body")
#   Required(m2) merged with Conflict(m2) -> Conflict passes through (Required is identity)
# Expected 4 slots: m1 Defined "RA::m1", m2 Conflict, m3 Defined "RB::m3", r2 Defined "r2:body"

subtest 'R8: Requirement meets a conflict - Union(RReqM2, Union(RA, RB))' => sub {
    my $inner  = $roles->Union($RA, $RB);
    my $result = $roles->Union($RReqM2, $inner);

    is $result->size, 4, '... size is 4';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m3 = $result->lookup('m3');
    my $r2 = $result->lookup('r2');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';
    ok defined($r2), '... r2 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',  '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is Conflict (Required is identity)';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';
    isa_ok $r2, 'MXCL::Term::Role::Slot::Defined',  '... r2 is Defined';

    is $m1->value->value, 'RA::m1',  '... m1 value is "RA::m1"';
    is $m3->value->value, 'RB::m3',  '... m3 value is "RB::m3"';
    is $r2->value->value, 'r2:body', '... r2 value is "r2:body"';

    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Defined', '... m2 lhs is Defined';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Defined', '... m2 rhs is Defined';

    is $m2->lhs->value->value, 'RA::m2', '... m2 lhs value is "RA::m2"';
    is $m2->rhs->value->value, 'RB::m2', '... m2 rhs value is "RB::m2"';
};

done_testing;
