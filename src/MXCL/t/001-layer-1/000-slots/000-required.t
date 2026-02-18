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
    my $sym = $terms->Sym('x');
    my $req = $roles->Required($sym);

    isa_ok $req, 'MXCL::Term::Role::Slot::Required';
    isa_ok $req, 'MXCL::Term::Role::Slot';
    isa_ok $req, 'MXCL::Term';
};

# -- ident accessor --

subtest 'ident accessor' => sub {
    my $sym = $terms->Sym('foo');
    my $req = $roles->Required($sym);

    ok defined($req->ident), '->ident is defined';
    is refaddr($req->ident), refaddr($sym), '->ident returns the exact same Sym object';
    is $req->ident->value, 'foo', '->ident->value returns the symbol string';
};

# -- hash --

subtest 'hash' => sub {
    my $req = $roles->Required($terms->Sym('x'));

    ok defined($req->hash), '->hash is defined';
    ok length($req->hash) > 0, '->hash is non-empty';
};

# -- content addressing (interning) --

subtest 'content addressing' => sub {
    my $sym  = $terms->Sym('x');
    my $req1 = $roles->Required($sym);
    my $req2 = $roles->Required($sym);

    is refaddr($req1), refaddr($req2),
        'two Required calls with the same Sym return the same object';
};

# -- different syms produce different objects --

subtest 'different syms produce different objects' => sub {
    my $x = $roles->Required($terms->Sym('x'));
    my $y = $roles->Required($terms->Sym('y'));

    isnt refaddr($x), refaddr($y),
        'Required(Sym("x")) and Required(Sym("y")) are different objects';
};

# -- equality --

subtest 'equality' => sub {
    my $req_x1 = $roles->Required($terms->Sym('x'));
    my $req_x2 = $roles->Required($terms->Sym('x'));
    my $req_y  = $roles->Required($terms->Sym('y'));

    ok  $req_x1->eq($req_x2), '->eq is true for same-content Required slots';
    ok !$req_x1->eq($req_y),  '->eq is false for different Required slots';
};

# -- pprint --

subtest 'pprint' => sub {
    my $req = $roles->Required($terms->Sym('x'));
    my $pp  = $req->pprint;

    ok defined($pp),      '->pprint is defined';
    ok length($pp) > 0,   '->pprint is non-empty';
    like $pp, qr/x/,      '->pprint contains the symbol name';
    like $pp, qr/required:\(x\)/, '->pprint matches required:(x)';
};

done_testing;
