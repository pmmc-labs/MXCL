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

my $RBaz = $roles->Role(
    $roles->Defined($terms->Sym('m5'), $terms->Str('RBaz::m5')),
);

my $REmpty = $roles->Role();   # no slots

# -- R1: Disjoint merge - no overlapping names --

subtest 'R1: disjoint merge produces union of all slots' => sub {
    my $result = $roles->Union($RA, $RBaz);

    is $result->size, 3, '->size is 3';

    my $slot_m1 = $result->lookup('m1');
    ok defined($slot_m1), '->lookup("m1") is defined';
    isa_ok $slot_m1, 'MXCL::Term::Role::Slot::Defined', '->lookup("m1")';
    is $slot_m1->value->value, 'RA::m1', '->lookup("m1") value->value eq "RA::m1"';

    my $slot_m2 = $result->lookup('m2');
    ok defined($slot_m2), '->lookup("m2") is defined';
    isa_ok $slot_m2, 'MXCL::Term::Role::Slot::Defined', '->lookup("m2")';
    is $slot_m2->value->value, 'RA::m2', '->lookup("m2") value->value eq "RA::m2"';

    my $slot_m5 = $result->lookup('m5');
    ok defined($slot_m5), '->lookup("m5") is defined';
    isa_ok $slot_m5, 'MXCL::Term::Role::Slot::Defined', '->lookup("m5")';
    is $slot_m5->value->value, 'RBaz::m5', '->lookup("m5") value->value eq "RBaz::m5"';
};

# -- R2: Empty role is the identity element (both sides) --

subtest 'R2: empty role properties' => sub {
    ok $REmpty->is_empty, 'REmpty->is_empty is true';
    is $REmpty->size, 0,  'REmpty->size is 0';
};

subtest 'R2: empty role is left identity (REmpty <+> RA = RA)' => sub {
    my $result = $roles->Union($REmpty, $RA);

    is $result->hash, $RA->hash, '->hash equals $RA->hash (content-identical)';
    is $result->size, 2, '->size is 2';

    my $slot_m1 = $result->lookup('m1');
    ok defined($slot_m1), '->lookup("m1") is defined';
    is $slot_m1->value->value, 'RA::m1', '->lookup("m1") value->value eq "RA::m1"';

    my $slot_m2 = $result->lookup('m2');
    ok defined($slot_m2), '->lookup("m2") is defined';
    is $slot_m2->value->value, 'RA::m2', '->lookup("m2") value->value eq "RA::m2"';
};

subtest 'R2: empty role is right identity (RA <+> REmpty = RA)' => sub {
    my $result = $roles->Union($RA, $REmpty);

    is $result->hash, $RA->hash, '->hash equals $RA->hash (content-identical)';
    is $result->size, 2, '->size is 2';

    my $slot_m1 = $result->lookup('m1');
    ok defined($slot_m1), '->lookup("m1") is defined';
    is $slot_m1->value->value, 'RA::m1', '->lookup("m1") value->value eq "RA::m1"';

    my $slot_m2 = $result->lookup('m2');
    ok defined($slot_m2), '->lookup("m2") is defined';
    is $slot_m2->value->value, 'RA::m2', '->lookup("m2") value->value eq "RA::m2"';
};

done_testing;
