#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

# RLeft and RRight both carry RBase's exact same values for 'm' and 'shared'
my $RLeft = $roles->Role(
    $roles->Defined($terms->Sym('m'),      $terms->Str('RBase::m')),
    $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared')),
    $roles->Defined($terms->Sym('left'),   $terms->Str('RLeft::left')),
);

my $RRight = $roles->Role(
    $roles->Defined($terms->Sym('m'),      $terms->Str('RBase::m')),
    $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared')),
    $roles->Defined($terms->Sym('right'),  $terms->Str('RRight::right')),
);

# RLeftOverride has a DIFFERENT value for 'm'
my $RLeftOverride = $roles->Role(
    $roles->Defined($terms->Sym('m'),      $terms->Str('RLeftOverride::m')),
    $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared')),
    $roles->Defined($terms->Sym('left'),   $terms->Str('RLeftOverride::left')),
);

# RRightOverride has yet another different value for 'm'
my $RRightOverride = $roles->Role(
    $roles->Defined($terms->Sym('m'),      $terms->Str('RRightOverride::m')),
    $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared')),
    $roles->Defined($terms->Sym('right'),  $terms->Str('RRightOverride::right')),
);

# RRightSameOverride has the SAME value for 'm' as RLeftOverride (convergent evolution)
my $RRightSameOverride = $roles->Role(
    $roles->Defined($terms->Sym('m'),      $terms->Str('RLeftOverride::m')),  # same as RLeftOverride!
    $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared')),
    $roles->Defined($terms->Sym('right'),  $terms->Str('RRightSameOverride::right')),
);

# -- R19: Classic diamond - same hash, no conflict --

subtest 'R19: classic diamond - same content hash, no conflict' => sub {
    my $result = $roles->Union($RLeft, $RRight);

    is $result->size, 4, '->size is 4';

    my $slot_m = $result->lookup('m');
    ok defined($slot_m), '->lookup("m") is defined';
    isa_ok $slot_m, 'MXCL::Term::Role::Slot::Defined', '->lookup("m")';
    is $slot_m->value->value, 'RBase::m', '->lookup("m") value->value eq "RBase::m"';

    my $slot_shared = $result->lookup('shared');
    ok defined($slot_shared), '->lookup("shared") is defined';
    isa_ok $slot_shared, 'MXCL::Term::Role::Slot::Defined', '->lookup("shared")';
    is $slot_shared->value->value, 'RBase::shared', '->lookup("shared") value->value eq "RBase::shared"';

    my $slot_left = $result->lookup('left');
    ok defined($slot_left), '->lookup("left") is defined';
    isa_ok $slot_left, 'MXCL::Term::Role::Slot::Defined', '->lookup("left")';
    is $slot_left->value->value, 'RLeft::left', '->lookup("left") value->value eq "RLeft::left"';

    my $slot_right = $result->lookup('right');
    ok defined($slot_right), '->lookup("right") is defined';
    isa_ok $slot_right, 'MXCL::Term::Role::Slot::Defined', '->lookup("right")';
    is $slot_right->value->value, 'RRight::right', '->lookup("right") value->value eq "RRight::right"';

    # content addressing: the 'm' slot from the union should have the same hash
    # as the independently-constructed Defined slot with the same content
    my $expected_m = $roles->Defined($terms->Sym('m'), $terms->Str('RBase::m'));
    is $slot_m->hash, $expected_m->hash, '->lookup("m")->hash matches standalone Defined slot (content-addressed)';

    my $expected_shared = $roles->Defined($terms->Sym('shared'), $terms->Str('RBase::shared'));
    is $slot_shared->hash, $expected_shared->hash, '->lookup("shared")->hash matches standalone Defined slot (content-addressed)';
};

# -- R20: Diamond - one side overrides --

subtest 'R20: diamond - one side overrides, other keeps base value => Conflict on m' => sub {
    my $result = $roles->Union($RLeftOverride, $RRight);

    is $result->size, 4, '->size is 4';

    my $slot_m = $result->lookup('m');
    ok defined($slot_m), '->lookup("m") is defined';
    isa_ok $slot_m, 'MXCL::Term::Role::Slot::Conflict', '->lookup("m") is a Conflict';
    isa_ok $slot_m->lhs, 'MXCL::Term::Role::Slot::Defined', '->lookup("m")->lhs is Defined';
    isa_ok $slot_m->rhs, 'MXCL::Term::Role::Slot::Defined', '->lookup("m")->rhs is Defined';
    is $slot_m->lhs->value->value, 'RLeftOverride::m', '->lookup("m")->lhs value->value eq "RLeftOverride::m"';
    is $slot_m->rhs->value->value, 'RBase::m',         '->lookup("m")->rhs value->value eq "RBase::m"';

    my $slot_shared = $result->lookup('shared');
    ok defined($slot_shared), '->lookup("shared") is defined';
    isa_ok $slot_shared, 'MXCL::Term::Role::Slot::Defined', '->lookup("shared") is Defined (no conflict)';
    is $slot_shared->value->value, 'RBase::shared', '->lookup("shared") value->value eq "RBase::shared"';

    my $slot_left = $result->lookup('left');
    ok defined($slot_left), '->lookup("left") is defined';
    isa_ok $slot_left, 'MXCL::Term::Role::Slot::Defined', '->lookup("left")';
    is $slot_left->value->value, 'RLeftOverride::left', '->lookup("left") value->value eq "RLeftOverride::left"';

    my $slot_right = $result->lookup('right');
    ok defined($slot_right), '->lookup("right") is defined';
    isa_ok $slot_right, 'MXCL::Term::Role::Slot::Defined', '->lookup("right")';
    is $slot_right->value->value, 'RRight::right', '->lookup("right") value->value eq "RRight::right"';
};

# -- R21: Diamond - both sides override, different bodies --

subtest 'R21: diamond - both sides override with different values => Conflict on m' => sub {
    my $result = $roles->Union($RLeftOverride, $RRightOverride);

    is $result->size, 4, '->size is 4';

    my $slot_m = $result->lookup('m');
    ok defined($slot_m), '->lookup("m") is defined';
    isa_ok $slot_m, 'MXCL::Term::Role::Slot::Conflict', '->lookup("m") is a Conflict';
    isa_ok $slot_m->lhs, 'MXCL::Term::Role::Slot::Defined', '->lookup("m")->lhs is Defined';
    isa_ok $slot_m->rhs, 'MXCL::Term::Role::Slot::Defined', '->lookup("m")->rhs is Defined';
    is $slot_m->lhs->value->value, 'RLeftOverride::m',  '->lookup("m")->lhs value->value eq "RLeftOverride::m"';
    is $slot_m->rhs->value->value, 'RRightOverride::m', '->lookup("m")->rhs value->value eq "RRightOverride::m"';

    my $slot_shared = $result->lookup('shared');
    ok defined($slot_shared), '->lookup("shared") is defined';
    isa_ok $slot_shared, 'MXCL::Term::Role::Slot::Defined', '->lookup("shared") is Defined (no conflict)';
    is $slot_shared->value->value, 'RBase::shared', '->lookup("shared") value->value eq "RBase::shared"';

    my $slot_left = $result->lookup('left');
    ok defined($slot_left), '->lookup("left") is defined';
    isa_ok $slot_left, 'MXCL::Term::Role::Slot::Defined', '->lookup("left")';
    is $slot_left->value->value, 'RLeftOverride::left', '->lookup("left") value->value eq "RLeftOverride::left"';

    my $slot_right = $result->lookup('right');
    ok defined($slot_right), '->lookup("right") is defined';
    isa_ok $slot_right, 'MXCL::Term::Role::Slot::Defined', '->lookup("right")';
    is $slot_right->value->value, 'RRightOverride::right', '->lookup("right") value->value eq "RRightOverride::right"';
};

# -- R22: Diamond - both sides override, convergent (same body) --

subtest 'R22: diamond - both sides converge on same value => no conflict (content-addressed idempotent)' => sub {
    my $result = $roles->Union($RLeftOverride, $RRightSameOverride);

    is $result->size, 4, '->size is 4';

    my $slot_m = $result->lookup('m');
    ok defined($slot_m), '->lookup("m") is defined';
    isa_ok $slot_m, 'MXCL::Term::Role::Slot::Defined', '->lookup("m") is Defined (convergent, no conflict)';
    is $slot_m->value->value, 'RLeftOverride::m', '->lookup("m") value->value eq "RLeftOverride::m"';

    # content addressing: convergent overrides hash to the same slot object
    my $expected_m = $roles->Defined($terms->Sym('m'), $terms->Str('RLeftOverride::m'));
    is $slot_m->hash, $expected_m->hash, '->lookup("m")->hash matches standalone Defined slot (convergent content-addressed)';

    my $slot_shared = $result->lookup('shared');
    ok defined($slot_shared), '->lookup("shared") is defined';
    isa_ok $slot_shared, 'MXCL::Term::Role::Slot::Defined', '->lookup("shared") is Defined (no conflict)';
    is $slot_shared->value->value, 'RBase::shared', '->lookup("shared") value->value eq "RBase::shared"';

    my $slot_left = $result->lookup('left');
    ok defined($slot_left), '->lookup("left") is defined';
    isa_ok $slot_left, 'MXCL::Term::Role::Slot::Defined', '->lookup("left")';
    is $slot_left->value->value, 'RLeftOverride::left', '->lookup("left") value->value eq "RLeftOverride::left"';

    my $slot_right = $result->lookup('right');
    ok defined($slot_right), '->lookup("right") is defined';
    isa_ok $slot_right, 'MXCL::Term::Role::Slot::Defined', '->lookup("right")';
    is $slot_right->value->value, 'RRightSameOverride::right', '->lookup("right") value->value eq "RRightSameOverride::right"';
};

done_testing;
