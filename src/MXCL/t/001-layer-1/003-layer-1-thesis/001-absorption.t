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

my $RB2 = $roles->Role(   # alias for clarity
    $roles->Defined($terms->Sym('m2'), $terms->Str('RB::m2')),
    $roles->Defined($terms->Sym('m3'), $terms->Str('RB::m3')),
);

my $RC = $roles->Role(
    $roles->Defined($terms->Sym('m3'), $terms->Str('RC::m3')),
    $roles->Defined($terms->Sym('m4'), $terms->Str('RC::m4')),
);

my $RD = $roles->Role(
    $roles->Defined($terms->Sym('m1'), $terms->Str('RD::m1')),
    $roles->Defined($terms->Sym('m4'), $terms->Str('RD::m4')),
);

my $RC2 = $roles->Role(
    $roles->Defined($terms->Sym('m2'), $terms->Str('RC2::m2')),
);

my $RX2 = $roles->Role(
    $roles->Defined($terms->Sym('m2'), $terms->Str('RX2::m2')),
);

my $RY2 = $roles->Role(
    $roles->Defined($terms->Sym('m2'), $terms->Str('RY2::m2')),
);

my $REmpty = $roles->Role();

my $RReqM1 = $roles->Role(
    $roles->Required($terms->Sym('m1')),
    $roles->Defined($terms->Sym('r1'), $terms->Str('r1:body')),
);

my $RReqM3DefM4 = $roles->Role(
    $roles->Required($terms->Sym('m3')),
    $roles->Defined($terms->Sym('m4'),      $terms->Str('RReqM3DefM4::m4')),
    $roles->Defined($terms->Sym('uses_m3'), $terms->Str('uses_m3:body')),
);

my $RProvM1     = $roles->Role($roles->Defined($terms->Sym('m1'), $terms->Str('shared::m1')));
my $RAlsoProvM1 = $roles->Role($roles->Defined($terms->Sym('m1'), $terms->Str('shared::m1')));  # same value!

# -- R23: Conflicted survives composition with empty --

subtest 'R23: Union(Union(RA, RB), REmpty) - Conflict on m2 unchanged by empty' => sub {
    my $AB     = $roles->Union($RA, $RB);
    my $result = $roles->Union($AB, $REmpty);

    is $result->size, 3, '... result has 3 slots';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m3 = $result->lookup('m3');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',  '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';

    is $m1->value->value, 'RA::m1', '... m1 value is "RA::m1"';
    is $m3->value->value, 'RB::m3', '... m3 value is "RB::m3"';

    # the Conflict object should be the same (not rewrapped) as the one in AB
    my $ab_m2 = $AB->lookup('m2');
    is $m2->hash, $ab_m2->hash, '... m2 Conflict hash is unchanged from AB (not rewrapped)';
};

# -- R24: Third provider does NOT resolve - it compounds --

subtest 'R24: Union(Union(RA, RB), RC2) - third provider deepens the Conflict' => sub {
    my $AB     = $roles->Union($RA, $RB);
    my $result = $roles->Union($AB, $RC2);

    is $result->size, 3, '... result has 3 slots';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m3 = $result->lookup('m3');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',  '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is outer Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';

    is $m1->value->value, 'RA::m1', '... m1 value is "RA::m1"';
    is $m3->value->value, 'RB::m3', '... m3 value is "RB::m3"';

    # m2: outer Conflict where lhs is the inner Conflict(Def(RA::m2),Def(RB::m2))
    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Conflict', '... m2->lhs is inner Conflict';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Defined',  '... m2->rhs is Defined';

    is $m2->lhs->lhs->value->value, 'RA::m2',   '... m2->lhs->lhs value is "RA::m2"';
    is $m2->lhs->rhs->value->value, 'RB::m2',   '... m2->lhs->rhs value is "RB::m2"';
    is $m2->rhs->value->value,      'RC2::m2',  '... m2->rhs value is "RC2::m2"';
};

# -- R25: Conflicted + Conflicted from independent compositions --

subtest 'R25: Union(Union(RA, RB), Union(RX2, RY2)) - two independent Conflicts merge' => sub {
    my $AB     = $roles->Union($RA,  $RB);
    my $XY     = $roles->Union($RX2, $RY2);
    my $result = $roles->Union($AB,  $XY);

    is $result->size, 3, '... result has 3 slots';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m3 = $result->lookup('m3');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',  '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is outer Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined';

    is $m1->value->value, 'RA::m1', '... m1 value is "RA::m1"';
    is $m3->value->value, 'RB::m3', '... m3 value is "RB::m3"';

    # m2: outer Conflict: lhs = Con(Def(RA::m2),Def(RB::m2)), rhs = Con(Def(RX2::m2),Def(RY2::m2))
    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Conflict', '... m2->lhs is Conflict (from AB)';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Conflict', '... m2->rhs is Conflict (from XY)';

    is $m2->lhs->lhs->value->value, 'RA::m2',  '... m2->lhs->lhs value is "RA::m2"';
    is $m2->lhs->rhs->value->value, 'RB::m2',  '... m2->lhs->rhs value is "RB::m2"';
    is $m2->rhs->lhs->value->value, 'RX2::m2', '... m2->rhs->lhs value is "RX2::m2"';
    is $m2->rhs->rhs->value->value, 'RY2::m2', '... m2->rhs->rhs value is "RY2::m2"';
};

# -- R26: Requirement met by same-hash Defined from two roles --

subtest 'R26: Union(RReqM1, Union(RProvM1, RAlsoProvM1)) - idempotent providers satisfy requirement' => sub {
    my $inner  = $roles->Union($RProvM1, $RAlsoProvM1);
    my $result = $roles->Union($RReqM1, $inner);

    is $result->size, 2, '... result has 2 slots (no Required remaining)';

    my $m1 = $result->lookup('m1');
    my $r1 = $result->lookup('r1');

    ok defined($m1), '... m1 slot exists';
    ok defined($r1), '... r1 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined', '... m1 is Defined';
    isa_ok $r1, 'MXCL::Term::Role::Slot::Defined', '... r1 is Defined';

    ok !($m1 isa 'MXCL::Term::Role::Slot::Required'), '... m1 is NOT Required';
    ok !($m1 isa 'MXCL::Term::Role::Slot::Conflict'), '... m1 is NOT Conflict';

    is $m1->value->value, 'shared::m1', '... m1 value is "shared::m1"';
    is $r1->value->value, 'r1:body',    '... r1 value is "r1:body"';
};

# -- R27: Requirement meets a conflict (not satisfied) --

subtest 'R27: Union(RReqM1, Union(RA, RD)) - Requirement meets Conflict, Conflict wins' => sub {
    my $inner  = $roles->Union($RA,  $RD);
    my $result = $roles->Union($RReqM1, $inner);

    is $result->size, 4, '... result has 4 slots';

    my $m1 = $result->lookup('m1');
    my $m2 = $result->lookup('m2');
    my $m4 = $result->lookup('m4');
    my $r1 = $result->lookup('r1');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m4), '... m4 slot exists';
    ok defined($r1), '... r1 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Conflict', '... m1 is Conflict (Required is identity against Conflict)';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Defined',  '... m2 is Defined';
    isa_ok $m4, 'MXCL::Term::Role::Slot::Defined',  '... m4 is Defined';
    isa_ok $r1, 'MXCL::Term::Role::Slot::Defined',  '... r1 is Defined';

    isa_ok $m1->lhs, 'MXCL::Term::Role::Slot::Defined', '... m1->lhs is Defined';
    isa_ok $m1->rhs, 'MXCL::Term::Role::Slot::Defined', '... m1->rhs is Defined';

    is $m1->lhs->value->value, 'RA::m1', '... m1->lhs value is "RA::m1"';
    is $m1->rhs->value->value, 'RD::m1', '... m1->rhs value is "RD::m1"';

    is $m2->value->value, 'RA::m2',  '... m2 value is "RA::m2"';
    is $m4->value->value, 'RD::m4',  '... m4 value is "RD::m4"';
    is $r1->value->value, 'r1:body', '... r1 value is "r1:body"';
};

# -- R28: Requirement satisfied + separate conflict on another slot --

subtest 'R28: Union(RReqM3DefM4, RC) - Req(m3) satisfied, m4 conflicts' => sub {
    my $result = $roles->Union($RReqM3DefM4, $RC);

    is $result->size, 3, '... result has 3 slots';

    my $m3      = $result->lookup('m3');
    my $m4      = $result->lookup('m4');
    my $uses_m3 = $result->lookup('uses_m3');

    ok defined($m3),      '... m3 slot exists';
    ok defined($m4),      '... m4 slot exists';
    ok defined($uses_m3), '... uses_m3 slot exists';

    isa_ok $m3,      'MXCL::Term::Role::Slot::Defined',  '... m3 is Defined (Req satisfied by RC)';
    isa_ok $m4,      'MXCL::Term::Role::Slot::Conflict', '... m4 is Conflict';
    isa_ok $uses_m3, 'MXCL::Term::Role::Slot::Defined',  '... uses_m3 is Defined';

    ok !($m3 isa 'MXCL::Term::Role::Slot::Required'), '... m3 is NOT Required';

    is $m3->value->value,      'RC::m3',            '... m3 value is "RC::m3"';
    is $uses_m3->value->value, 'uses_m3:body',      '... uses_m3 value is "uses_m3:body"';

    isa_ok $m4->lhs, 'MXCL::Term::Role::Slot::Defined', '... m4->lhs is Defined';
    isa_ok $m4->rhs, 'MXCL::Term::Role::Slot::Defined', '... m4->rhs is Defined';

    is $m4->lhs->value->value, 'RReqM3DefM4::m4', '... m4->lhs value is "RReqM3DefM4::m4"';
    is $m4->rhs->value->value, 'RC::m4',          '... m4->rhs value is "RC::m4"';
};

# -- R29: Requirement satisfied, no other conflicts --

subtest 'R29: Union(RReqM3DefM4, RB) - Req(m3) satisfied, no conflicts' => sub {
    my $result = $roles->Union($RReqM3DefM4, $RB);

    is $result->size, 4, '... result has 4 slots (0 Conflicts, 0 Required)';

    my $m2      = $result->lookup('m2');
    my $m3      = $result->lookup('m3');
    my $m4      = $result->lookup('m4');
    my $uses_m3 = $result->lookup('uses_m3');

    ok defined($m2),      '... m2 slot exists';
    ok defined($m3),      '... m3 slot exists';
    ok defined($m4),      '... m4 slot exists';
    ok defined($uses_m3), '... uses_m3 slot exists';

    isa_ok $m2,      'MXCL::Term::Role::Slot::Defined', '... m2 is Defined';
    isa_ok $m3,      'MXCL::Term::Role::Slot::Defined', '... m3 is Defined (Req satisfied by RB)';
    isa_ok $m4,      'MXCL::Term::Role::Slot::Defined', '... m4 is Defined';
    isa_ok $uses_m3, 'MXCL::Term::Role::Slot::Defined', '... uses_m3 is Defined';

    ok !($m2      isa 'MXCL::Term::Role::Slot::Conflict'), '... m2 is NOT Conflict';
    ok !($m3      isa 'MXCL::Term::Role::Slot::Conflict'), '... m3 is NOT Conflict';
    ok !($m3      isa 'MXCL::Term::Role::Slot::Required'), '... m3 is NOT Required';
    ok !($m4      isa 'MXCL::Term::Role::Slot::Conflict'), '... m4 is NOT Conflict';
    ok !($uses_m3 isa 'MXCL::Term::Role::Slot::Conflict'), '... uses_m3 is NOT Conflict';

    is $m2->value->value,      'RB::m2',            '... m2 value is "RB::m2"';
    is $m3->value->value,      'RB::m3',            '... m3 value is "RB::m3"';
    is $m4->value->value,      'RReqM3DefM4::m4',   '... m4 value is "RReqM3DefM4::m4"';
    is $uses_m3->value->value, 'uses_m3:body',      '... uses_m3 value is "uses_m3:body"';
};

done_testing;
