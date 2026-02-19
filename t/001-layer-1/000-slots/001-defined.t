#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms roles ];

my $terms = terms;
my $roles = roles;

# -- type hierarchy --

subtest 'type hierarchy' => sub {
    my $slot = $roles->Defined( $terms->Sym('x'), $terms->Str('hello') );

    isa_ok $slot, 'MXCL::Term::Role::Slot::Defined';
    isa_ok $slot, 'MXCL::Term::Role::Slot';
    isa_ok $slot, 'MXCL::Term';
};

# -- ident accessor --

subtest 'ident accessor' => sub {
    my $sym  = $terms->Sym('foo');
    my $val  = $terms->Str('bar');
    my $slot = $roles->Defined( $sym, $val );

    ok defined($slot->ident), '->ident returns something defined';
    is refaddr($slot->ident), refaddr($sym), '->ident returns the exact same Sym object';
    isa_ok $slot->ident, 'MXCL::Term::Sym';
};

# -- value accessor --

subtest 'value accessor' => sub {
    my $sym  = $terms->Sym('x');
    my $val  = $terms->Str('hello');
    my $slot = $roles->Defined( $sym, $val );

    ok defined($slot->value), '->value returns something defined';
    is refaddr($slot->value), refaddr($val), '->value returns the exact same Term object';
};

# -- hash is defined and non-empty --

subtest 'hash is defined and non-empty' => sub {
    my $slot = $roles->Defined( $terms->Sym('x'), $terms->Str('hello') );

    ok defined($slot->hash), '->hash is defined';
    ok length($slot->hash) > 0, '->hash is non-empty';
};

# -- content addressing: same ident + same value => same refaddr --

subtest 'content addressing' => sub {
    my $slot1 = $roles->Defined( $terms->Sym('x'), $terms->Str('hello') );
    my $slot2 = $roles->Defined( $terms->Sym('x'), $terms->Str('hello') );

    is refaddr($slot1), refaddr($slot2),
        'same ident + same value gives same object refaddr';
    ok $slot1->eq($slot2), '->eq returns true for same content';
};

# -- different value => different object --

subtest 'different value gives different object' => sub {
    my $slot_a = $roles->Defined( $terms->Sym('x'), $terms->Str('a') );
    my $slot_b = $roles->Defined( $terms->Sym('x'), $terms->Str('b') );

    isnt refaddr($slot_a), refaddr($slot_b),
        'Defined(Sym(x), Str(a)) and Defined(Sym(x), Str(b)) are different objects';
    ok !$slot_a->eq($slot_b),
        '->eq returns false for different values';
};

# -- different ident => different object --

subtest 'different ident gives different object' => sub {
    my $slot_x = $roles->Defined( $terms->Sym('x'), $terms->Str('v') );
    my $slot_y = $roles->Defined( $terms->Sym('y'), $terms->Str('v') );

    isnt refaddr($slot_x), refaddr($slot_y),
        'Defined(Sym(x), Str(v)) and Defined(Sym(y), Str(v)) are different objects';
    ok !$slot_x->eq($slot_y),
        '->eq returns false for different idents';
};

# -- equality semantics --

subtest 'equality semantics' => sub {
    my $slot1 = $roles->Defined( $terms->Sym('name'), $terms->Str('alice') );
    my $slot2 = $roles->Defined( $terms->Sym('name'), $terms->Str('alice') );
    my $slot3 = $roles->Defined( $terms->Sym('name'), $terms->Str('bob') );

    ok  $slot1->eq($slot2), '->eq true for identical ident and value';
    ok !$slot1->eq($slot3), '->eq false when value differs';
};

# -- value can be any Term: Str and Num --

subtest 'value can be Str' => sub {
    my $slot = $roles->Defined( $terms->Sym('label'), $terms->Str('hello') );

    ok defined($slot), 'Defined with Str value constructs successfully';
    is refaddr($slot->value), refaddr($terms->Str('hello')),
        '->value returns the Str term';
};

subtest 'value can be Num' => sub {
    my $slot = $roles->Defined( $terms->Sym('count'), $terms->Num(42) );

    ok defined($slot), 'Defined with Num value constructs successfully';
    is refaddr($slot->value), refaddr($terms->Num(42)),
        '->value returns the Num term';
};

subtest 'Str value and Num value with same ident are different objects' => sub {
    my $slot_str = $roles->Defined( $terms->Sym('v'), $terms->Str('hello') );
    my $slot_num = $roles->Defined( $terms->Sym('v'), $terms->Num(42) );

    isnt refaddr($slot_str), refaddr($slot_num),
        'Defined with Str value differs from Defined with Num value';
    ok !$slot_str->eq($slot_num),
        '->eq false when value types differ';
};

# -- pprint --

subtest 'pprint' => sub {
    my $slot = $roles->Defined( $terms->Sym('myident'), $terms->Str('myvalue') );
    my $pp   = $slot->pprint;

    ok defined($pp),         '->pprint returns something defined';
    ok length($pp) > 0,      '->pprint returns a non-empty string';
    like $pp, qr/myident/,   '->pprint contains the ident name';
    like $pp, qr/defined:/,  '->pprint starts with "defined:"';
};

done_testing;
