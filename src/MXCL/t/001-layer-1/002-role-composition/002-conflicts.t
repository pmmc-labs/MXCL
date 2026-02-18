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

my $RD = $roles->Role(
    $roles->Defined($terms->Sym('m1'), $terms->Str('RD::m1')),
    $roles->Defined($terms->Sym('m4'), $terms->Str('RD::m4')),
);

my $RX = $roles->Role(
    $roles->Defined($terms->Sym('m1'), $terms->Str('shared::m1')),
    $roles->Defined($terms->Sym('m5'), $terms->Str('RX::m5')),
);

my $RY = $roles->Role(
    $roles->Defined($terms->Sym('m1'), $terms->Str('shared::m1')),  # same value as RX
    $roles->Defined($terms->Sym('m6'), $terms->Str('RY::m6')),
);

# -- R9: Simple conflict --

subtest 'R9: Union(RA, RB) produces one Conflict for m2' => sub {
    my $r = $roles->Union($RA, $RB);

    is $r->size, 3, '... result has 3 slots';

    my $m1 = $r->lookup('m1');
    my $m2 = $r->lookup('m2');
    my $m3 = $r->lookup('m3');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',   '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict',  '... m2 is Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Defined',   '... m3 is Defined';

    is $m1->value->value, 'RA::m1', '... m1 value is "RA::m1"';
    is $m3->value->value, 'RB::m3', '... m3 value is "RB::m3"';

    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Defined', '... m2->lhs is Defined';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Defined', '... m2->rhs is Defined';

    is $m2->lhs->value->value, 'RA::m2', '... m2->lhs value is "RA::m2"';
    is $m2->rhs->value->value, 'RB::m2', '... m2->rhs value is "RB::m2"';
};

# -- R10: No conflict - same value hash, different origin --

subtest 'R10: Union(RX, RY) - same m1 value produces no conflict' => sub {
    my $r = $roles->Union($RX, $RY);

    is $r->size, 3, '... result has 3 slots';

    my $m1 = $r->lookup('m1');
    my $m5 = $r->lookup('m5');
    my $m6 = $r->lookup('m6');

    ok defined($m1), '... m1 slot exists';
    ok defined($m5), '... m5 slot exists';
    ok defined($m6), '... m6 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined', '... m1 is Defined (no conflict)';
    isa_ok $m5, 'MXCL::Term::Role::Slot::Defined', '... m5 is Defined';
    isa_ok $m6, 'MXCL::Term::Role::Slot::Defined', '... m6 is Defined';

    ok !($m1 isa 'MXCL::Term::Role::Slot::Conflict'), '... m1 is NOT a Conflict';
    ok !($m5 isa 'MXCL::Term::Role::Slot::Conflict'), '... m5 is NOT a Conflict';
    ok !($m6 isa 'MXCL::Term::Role::Slot::Conflict'), '... m6 is NOT a Conflict';

    is $m1->value->value, 'shared::m1', '... m1 value is "shared::m1"';
    is $m5->value->value, 'RX::m5',     '... m5 value is "RX::m5"';
    is $m6->value->value, 'RY::m6',     '... m6 value is "RY::m6"';
};

# -- R11: Mixed - some same hash, some different --

subtest 'R11: Union(RX, RA) - m1 has different values, produces Conflict' => sub {
    my $r = $roles->Union($RX, $RA);

    is $r->size, 3, '... result has 3 slots';

    my $m1 = $r->lookup('m1');
    my $m2 = $r->lookup('m2');
    my $m5 = $r->lookup('m5');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m5), '... m5 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Conflict', '... m1 is Conflict';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Defined',  '... m2 is Defined';
    isa_ok $m5, 'MXCL::Term::Role::Slot::Defined',  '... m5 is Defined';

    isa_ok $m1->lhs, 'MXCL::Term::Role::Slot::Defined', '... m1->lhs is Defined';
    isa_ok $m1->rhs, 'MXCL::Term::Role::Slot::Defined', '... m1->rhs is Defined';

    is $m1->lhs->value->value, 'shared::m1', '... m1->lhs value is "shared::m1"';
    is $m1->rhs->value->value, 'RA::m1',     '... m1->rhs value is "RA::m1"';

    is $m2->value->value, 'RA::m2', '... m2 value is "RA::m2"';
    is $m5->value->value, 'RX::m5', '... m5 value is "RX::m5"';
};

# -- R12: Two conflicts --

subtest 'R12: Union(RA, Union(RB, RC)) - two Conflicts' => sub {
    my $inner = $roles->Union($RB, $RC);

    # verify inner: m2 Defined, m3 Conflict, m4 Defined
    is $inner->size, 3, '... inner has 3 slots';
    isa_ok $inner->lookup('m2'), 'MXCL::Term::Role::Slot::Defined',  '... inner m2 is Defined';
    isa_ok $inner->lookup('m3'), 'MXCL::Term::Role::Slot::Conflict', '... inner m3 is Conflict';
    isa_ok $inner->lookup('m4'), 'MXCL::Term::Role::Slot::Defined',  '... inner m4 is Defined';

    my $r = $roles->Union($RA, $inner);

    is $r->size, 4, '... result has 4 slots';

    my $m1 = $r->lookup('m1');
    my $m2 = $r->lookup('m2');
    my $m3 = $r->lookup('m3');
    my $m4 = $r->lookup('m4');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';
    ok defined($m4), '... m4 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Defined',  '... m1 is Defined';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Conflict', '... m3 is Conflict';
    isa_ok $m4, 'MXCL::Term::Role::Slot::Defined',  '... m4 is Defined';

    is $m1->value->value, 'RA::m1', '... m1 value is "RA::m1"';
    is $m4->value->value, 'RC::m4', '... m4 value is "RC::m4"';

    # m2 conflict: RA::m2 vs RB::m2
    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Defined', '... m2->lhs is Defined';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Defined', '... m2->rhs is Defined';
    is $m2->lhs->value->value, 'RA::m2', '... m2->lhs value is "RA::m2"';
    is $m2->rhs->value->value, 'RB::m2', '... m2->rhs value is "RB::m2"';

    # m3 conflict: lhs Defined "RB::m3", rhs Defined "RC::m3"
    isa_ok $m3->lhs, 'MXCL::Term::Role::Slot::Defined', '... m3->lhs is Defined';
    isa_ok $m3->rhs, 'MXCL::Term::Role::Slot::Defined', '... m3->rhs is Defined';
    is $m3->lhs->value->value, 'RB::m3', '... m3->lhs value is "RB::m3"';
    is $m3->rhs->value->value, 'RC::m3', '... m3->rhs value is "RC::m3"';
};

# -- R13: Total conflict - four roles, all slots conflicted --

subtest 'R13: Union(RA, Union(RB, Union(RC, RD))) - all 4 slots are Conflicts' => sub {
    my $inner1 = $roles->Union($RC, $RD);
    my $inner2 = $roles->Union($RB, $inner1);
    my $r      = $roles->Union($RA, $inner2);

    is $r->size, 4, '... result has 4 slots';

    my $m1 = $r->lookup('m1');
    my $m2 = $r->lookup('m2');
    my $m3 = $r->lookup('m3');
    my $m4 = $r->lookup('m4');

    ok defined($m1), '... m1 slot exists';
    ok defined($m2), '... m2 slot exists';
    ok defined($m3), '... m3 slot exists';
    ok defined($m4), '... m4 slot exists';

    isa_ok $m1, 'MXCL::Term::Role::Slot::Conflict', '... m1 is Conflict';
    isa_ok $m2, 'MXCL::Term::Role::Slot::Conflict', '... m2 is Conflict';
    isa_ok $m3, 'MXCL::Term::Role::Slot::Conflict', '... m3 is Conflict';
    isa_ok $m4, 'MXCL::Term::Role::Slot::Conflict', '... m4 is Conflict';

    # m1: Conflict(Def "RA::m1", Def "RD::m1")
    isa_ok $m1->lhs, 'MXCL::Term::Role::Slot::Defined', '... m1->lhs is Defined';
    isa_ok $m1->rhs, 'MXCL::Term::Role::Slot::Defined', '... m1->rhs is Defined';
    is $m1->lhs->value->value, 'RA::m1', '... m1->lhs value is "RA::m1"';
    is $m1->rhs->value->value, 'RD::m1', '... m1->rhs value is "RD::m1"';

    # m2: Conflict(Def "RA::m2", Def "RB::m2")
    isa_ok $m2->lhs, 'MXCL::Term::Role::Slot::Defined', '... m2->lhs is Defined';
    isa_ok $m2->rhs, 'MXCL::Term::Role::Slot::Defined', '... m2->rhs is Defined';
    is $m2->lhs->value->value, 'RA::m2', '... m2->lhs value is "RA::m2"';
    is $m2->rhs->value->value, 'RB::m2', '... m2->rhs value is "RB::m2"';

    # m3: Conflict(Def "RB::m3", Def "RC::m3")
    isa_ok $m3->lhs, 'MXCL::Term::Role::Slot::Defined', '... m3->lhs is Defined';
    isa_ok $m3->rhs, 'MXCL::Term::Role::Slot::Defined', '... m3->rhs is Defined';
    is $m3->lhs->value->value, 'RB::m3', '... m3->lhs value is "RB::m3"';
    is $m3->rhs->value->value, 'RC::m3', '... m3->rhs value is "RC::m3"';

    # m4: Conflict(Def "RC::m4", Def "RD::m4")
    isa_ok $m4->lhs, 'MXCL::Term::Role::Slot::Defined', '... m4->lhs is Defined';
    isa_ok $m4->rhs, 'MXCL::Term::Role::Slot::Defined', '... m4->rhs is Defined';
    is $m4->lhs->value->value, 'RC::m4', '... m4->lhs value is "RC::m4"';
    is $m4->rhs->value->value, 'RD::m4', '... m4->rhs value is "RD::m4"';
};

done_testing;
