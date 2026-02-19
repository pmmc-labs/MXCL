#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

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
my $RC2 = $roles->Role(
    $roles->Defined($terms->Sym('m2'), $terms->Str('RC2::m2')),
);
my $RReqM1 = $roles->Role(
    $roles->Required($terms->Sym('m1')),
    $roles->Defined($terms->Sym('r1'), $terms->Str('r1:body')),
);

# -- R14: Commutativity (qualified) --
# Union is NOT fully commutative: Conflict node children are in opposite order,
# so AB and BA have different hashes. But non-conflicted slots are identical.

subtest 'R14: commutativity - AB and BA have different hashes (conflict order differs)' => sub {
    my $AB = $roles->Union($RA, $RB);
    my $BA = $roles->Union($RB, $RA);

    isnt $AB->hash, $BA->hash,
        'AB->hash ne BA->hash (conflict child order differs)';

    is $AB->size, 3, 'AB->size is 3';
    is $BA->size, 3, 'BA->size is 3';

    # non-conflicted slots are identical in both directions
    is $AB->lookup('m1')->hash, $BA->lookup('m1')->hash,
        'AB and BA agree on m1 slot hash (no conflict)';
    is $AB->lookup('m3')->hash, $BA->lookup('m3')->hash,
        'AB and BA agree on m3 slot hash (no conflict)';

    # m2 is a Conflict in both
    isa_ok $AB->lookup('m2'), 'MXCL::Term::Role::Slot::Conflict',
        'AB->lookup("m2")';
    isa_ok $BA->lookup('m2'), 'MXCL::Term::Role::Slot::Conflict',
        'BA->lookup("m2")';

    # AB: m2 conflict has RA on lhs, RB on rhs
    is $AB->lookup('m2')->lhs->value->value, 'RA::m2',
        'AB m2 conflict: lhs->value->value eq "RA::m2"';
    is $AB->lookup('m2')->rhs->value->value, 'RB::m2',
        'AB m2 conflict: rhs->value->value eq "RB::m2"';

    # BA: m2 conflict has RB on lhs, RA on rhs (swapped)
    is $BA->lookup('m2')->lhs->value->value, 'RB::m2',
        'BA m2 conflict: lhs->value->value eq "RB::m2"';
    is $BA->lookup('m2')->rhs->value->value, 'RA::m2',
        'BA m2 conflict: rhs->value->value eq "RA::m2"';
};

# -- R15: Associativity (same structure - no three-way conflict) --
# Union((RA <+> RB) <+> RC) == Union(RA <+> (RB <+> RC))
# Both groupings produce identical conflict trees for each slot,
# so the resulting roles have the same hash.

subtest 'R15: associativity - (RA+RB)+RC and RA+(RB+RC) have the same hash' => sub {
    my $AB_C = $roles->Union($roles->Union($RA, $RB), $RC);
    my $A_BC = $roles->Union($RA, $roles->Union($RB, $RC));

    is $AB_C->hash, $A_BC->hash,
        '(RA+RB)+RC and RA+(RB+RC) have identical hashes';

    is $AB_C->size, 4, '(RA+RB)+RC size is 4 (m1, m2, m3, m4)';

    # spot-check: m2 conflict structure is the same in both
    isa_ok $AB_C->lookup('m2'), 'MXCL::Term::Role::Slot::Conflict',
        '(RA+RB)+RC: m2 is a Conflict';
    isa_ok $A_BC->lookup('m2'), 'MXCL::Term::Role::Slot::Conflict',
        'RA+(RB+RC): m2 is a Conflict';

    is $AB_C->lookup('m2')->lhs->value->value, 'RA::m2',
        '(RA+RB)+RC: m2 conflict lhs->value->value eq "RA::m2"';
    is $AB_C->lookup('m2')->rhs->value->value, 'RB::m2',
        '(RA+RB)+RC: m2 conflict rhs->value->value eq "RB::m2"';

    is $A_BC->lookup('m2')->lhs->value->value, 'RA::m2',
        'RA+(RB+RC): m2 conflict lhs->value->value eq "RA::m2"';
    is $A_BC->lookup('m2')->rhs->value->value, 'RB::m2',
        'RA+(RB+RC): m2 conflict rhs->value->value eq "RB::m2"';
};

# -- R16: Associativity with three-way conflict (tree shape diverges) --
# All three of RA, RB, RC2 provide m2 with different values.
# Different groupings produce different tree shapes -> different hashes.

subtest 'R16: associativity with three-way conflict - tree shapes differ' => sub {
    my $AB    = $roles->Union($RA,  $RB);           # m2: Con(Def(RA::m2), Def(RB::m2))
    my $AB_C2 = $roles->Union($AB,  $RC2);          # m2: Con(Con(Def(RA), Def(RB)), Def(RC2))

    my $BC2   = $roles->Union($RB,  $RC2);          # m2: Con(Def(RB::m2), Def(RC2::m2))
    my $A_BC2 = $roles->Union($RA,  $BC2);          # m2: Con(Def(RA), Con(Def(RB), Def(RC2)))

    isnt $AB_C2->hash, $A_BC2->hash,
        'AB_C2 and A_BC2 have different hashes (tree shapes differ)';

    is $AB_C2->size, 3, 'AB_C2 size is 3 (m1, m2, m3)';
    is $A_BC2->size, 3, 'A_BC2 size is 3 (m1, m2, m3)';

    # AB_C2: m2 is left-heavy - outer Conflict, lhs is itself a Conflict
    my $ab_c2_m2 = $AB_C2->lookup('m2');
    isa_ok $ab_c2_m2, 'MXCL::Term::Role::Slot::Conflict',
        'AB_C2: m2 is a Conflict';
    isa_ok $ab_c2_m2->lhs, 'MXCL::Term::Role::Slot::Conflict',
        'AB_C2: m2 lhs is itself a Conflict (left-heavy)';
    is $ab_c2_m2->lhs->lhs->value->value, 'RA::m2',
        'AB_C2: m2 lhs.lhs->value->value eq "RA::m2"';
    is $ab_c2_m2->lhs->rhs->value->value, 'RB::m2',
        'AB_C2: m2 lhs.rhs->value->value eq "RB::m2"';
    is $ab_c2_m2->rhs->value->value, 'RC2::m2',
        'AB_C2: m2 rhs->value->value eq "RC2::m2"';

    # A_BC2: m2 is right-heavy - outer Conflict, rhs is itself a Conflict
    my $a_bc2_m2 = $A_BC2->lookup('m2');
    isa_ok $a_bc2_m2, 'MXCL::Term::Role::Slot::Conflict',
        'A_BC2: m2 is a Conflict';
    isa_ok $a_bc2_m2->rhs, 'MXCL::Term::Role::Slot::Conflict',
        'A_BC2: m2 rhs is itself a Conflict (right-heavy)';
    is $a_bc2_m2->lhs->value->value, 'RA::m2',
        'A_BC2: m2 lhs->value->value eq "RA::m2"';
    is $a_bc2_m2->rhs->lhs->value->value, 'RB::m2',
        'A_BC2: m2 rhs.lhs->value->value eq "RB::m2"';
    is $a_bc2_m2->rhs->rhs->value->value, 'RC2::m2',
        'A_BC2: m2 rhs.rhs->value->value eq "RC2::m2"';
};

# -- R17: Idempotency --
# compose_roles(RA, RA) = RA
# Every slot composes with its identical twin -> same content hash -> same role object.

subtest 'R17: idempotency - Union(RA, RA) equals RA' => sub {
    my $AA = $roles->Union($RA, $RA);

    is $AA->hash, $RA->hash,
        'AA->hash eq RA->hash (idempotent)';
    is refaddr($AA), refaddr($RA),
        'AA and RA are the same Arena object (interned)';
    is $AA->size, 2,
        'AA->size is 2';
};

# -- R18: Idempotency with requirements --
# compose_roles(RReqM1, RReqM1) = RReqM1

subtest 'R18: idempotency with requirements - Union(RReqM1, RReqM1) equals RReqM1' => sub {
    my $RR = $roles->Union($RReqM1, $RReqM1);

    is $RR->hash, $RReqM1->hash,
        'RR->hash eq RReqM1->hash (idempotent)';
    is refaddr($RR), refaddr($RReqM1),
        'RR and RReqM1 are the same Arena object (interned)';
    is $RR->size, 2,
        'RR->size is 2';

    isa_ok $RR->lookup('m1'), 'MXCL::Term::Role::Slot::Required',
        'RR->lookup("m1") is a Required slot';
    isa_ok $RR->lookup('r1'), 'MXCL::Term::Role::Slot::Defined',
        'RR->lookup("r1") is a Defined slot';
};

done_testing;
