#!perl

use v5.42;
use experimental qw[ class ];
use Test::More import => [qw[ plan subtest ok is diag ]];
use Scalar::Util qw[ refaddr ];

use MXCL::Arena;
use MXCL::Allocator::Terms;

plan tests => 15;

my $a = MXCL::Allocator::Terms->new( arena => MXCL::Arena->new );

# --- singletons ---

subtest 'Nil' => sub {
    plan tests => 2;
    is refaddr($a->Nil), refaddr($a->Nil), 'is a singleton';
    is $a->Nil->hash,    $a->Nil->hash,    'hash is stable';
};

subtest 'Bool' => sub {
    plan tests => 4;
    is refaddr($a->True),  refaddr($a->True),  'True is a singleton';
    is refaddr($a->False), refaddr($a->False), 'False is a singleton';
    is $a->True->hash,     $a->True->hash,     'True hash is stable';
    ok $a->True->hash ne $a->False->hash,      'True and False have different hashes';
};

# --- interned primitives ---

subtest 'Num' => sub {
    plan tests => 3;
    my ($a1, $a2, $b) = ( $a->Num(42), $a->Num(42), $a->Num(7) );
    is refaddr($a1), refaddr($a2), 'deduplicates';
    is $a1->hash,    $a2->hash,    'hash equality';
    ok $a1->hash ne $b->hash,      'distinct value gives different hash';
};

subtest 'Str' => sub {
    plan tests => 3;
    my ($a1, $a2, $b) = ( $a->Str("hi"), $a->Str("hi"), $a->Str("bye") );
    is refaddr($a1), refaddr($a2), 'deduplicates';
    is $a1->hash,    $a2->hash,    'hash equality';
    ok $a1->hash ne $b->hash,      'distinct value gives different hash';
};

subtest 'Sym' => sub {
    plan tests => 3;
    my ($a1, $a2, $b) = ( $a->Sym("x"), $a->Sym("x"), $a->Sym("y") );
    is refaddr($a1), refaddr($a2), 'deduplicates';
    is $a1->hash,    $a2->hash,    'hash equality';
    ok $a1->hash ne $b->hash,      'distinct value gives different hash';
};

subtest 'Tag' => sub {
    plan tests => 3;
    my ($a1, $a2, $b) = ( $a->Tag("foo"), $a->Tag("foo"), $a->Tag("bar") );
    is refaddr($a1), refaddr($a2), 'deduplicates';
    is $a1->hash,    $a2->hash,    'hash equality';
    ok $a1->hash ne $b->hash,      'distinct value gives different hash';
};

# --- structured terms ---

subtest 'Cons' => sub {
    plan tests => 3;
    my $a1 = $a->Cons( $a->Num(1), $a->Nil );
    my $a2 = $a->Cons( $a->Num(1), $a->Nil );
    my $b  = $a->Cons( $a->Num(2), $a->Nil );
    is refaddr($a1), refaddr($a2), 'deduplicates';
    is $a1->hash,    $a2->hash,    'hash equality';
    ok $a1->hash ne $b->hash,      'different head gives different hash';
};

subtest 'Env' => sub {
    plan tests => 4;
    my $x  = $a->Num(1);
    my $e1 = $a->Env( a => $x, b => $a->Num(2) );
    my $e2 = $a->Env( b => $a->Num(2), a => $x );   # reversed key order
    my $e3 = $a->Env( a => $x, b => $a->Num(3) );
    is refaddr($e1), refaddr($e2), 'deduplicates regardless of key order';
    is $e1->hash,    $e2->hash,    'hash is key-order independent';
    ok $e1->hash ne $e3->hash,     'different value gives different hash';
    ok $a->Env( a => $a->Num(1) )->hash ne $a->Env( b => $a->Num(1) )->hash,
                                           'different keys give different hash';
};

subtest 'Lambda' => sub {
    plan tests => 3;
    my $params = $a->Cons( $a->Sym("x"), $a->Nil );
    my $body   = $a->Sym("x");
    my $env    = $a->Env( y => $a->Num(1) );
    my $l1     = $a->Lambda( $params, $body, $env );
    my $l2     = $a->Lambda( $params, $body, $env );
    my $l3     = $a->Lambda( $params, $a->Sym("y"), $env );
    is refaddr($l1), refaddr($l2), 'deduplicates';
    is $l1->hash,    $l2->hash,    'hash equality';
    ok $l1->hash ne $l3->hash,     'different body gives different hash';
};

subtest 'Opaque' => sub {
    plan tests => 3;
    my $env1 = $a->Env( x => $a->Num(1) );
    my $env2 = $a->Env( x => $a->Num(2) );
    my $o1   = $a->Opaque( $env1 );
    my $o2   = $a->Opaque( $env1 );
    my $o3   = $a->Opaque( $env2 );
    is refaddr($o1), refaddr($o2), 'deduplicates';
    is $o1->hash,    $o2->hash,    'hash equality';
    ok $o1->hash ne $o3->hash,     'different env gives different hash';
};

subtest 'NativeApplicative' => sub {
    plan tests => 3;
    my $params = $a->Cons( $a->Sym("x"), $a->Nil );
    my $body   = sub { $_[0] };
    my $na1    = $a->NativeApplicative( $params, $body );
    my $na2    = $a->NativeApplicative( $params, $body );
    my $na3    = $a->NativeApplicative( $params, sub { $_[0] } );
    is refaddr($na1), refaddr($na2), 'deduplicates with same code ref';
    is $na1->hash,    $na2->hash,    'hash equality';
    ok $na1->hash ne $na3->hash,     'different code ref gives different hash';
};

subtest 'NativeOperative' => sub {
    plan tests => 3;
    my $params = $a->Cons( $a->Sym("x"), $a->Nil );
    my $body   = sub { $_[0] };
    my $no1    = $a->NativeOperative( $params, $body );
    my $no2    = $a->NativeOperative( $params, $body );
    my $no3    = $a->NativeOperative( $params, sub { $_[0] } );
    is refaddr($no1), refaddr($no2), 'deduplicates with same code ref';
    is $no1->hash,    $no2->hash,    'hash equality';
    ok $no1->hash ne $no3->hash,     'different code ref gives different hash';
};

# --- cross-cutting / compound ---

subtest 'type tag distinguishes Sym from Str' => sub {
    plan tests => 1;
    ok $a->Sym("foo")->hash ne $a->Str("foo")->hash, 'same value, different type';
};

subtest 'shared Cons tail deduplicates' => sub {
    plan tests => 2;
    my $tail  = $a->Cons( $a->Num(2), $a->Cons( $a->Num(3), $a->Nil ) );
    my $list1 = $a->Cons( $a->Num(1), $tail );
    my $list2 = $a->Cons( $a->Num(0), $tail );
    is refaddr( $list2->tail ), refaddr( $tail ), 'extracted tail is the interned object';
    # rebuild tail from scratch - should be the same interned object
    my $tail2 = $a->Cons( $a->Num(2), $a->Cons( $a->Num(3), $a->Nil ) );
    is refaddr( $tail ), refaddr( $tail2 ), 'independently rebuilt tail deduplicates';
};

subtest 'Env with shared list structure' => sub {
    plan tests => 3;
    my $list = $a->Cons( $a->Num(1), $a->Cons( $a->Num(2), $a->Nil ) );
    my $env1 = $a->Env( xs => $list, n => $a->Num(3) );
    my $env2 = $a->Env( xs => $list, n => $a->Num(3) );
    is refaddr( $env1 ),                   refaddr( $env2 ),  'Envs with same contents deduplicate';
    is $env1->bindings->{xs}->hash,        $list->hash,       'binding preserves list hash';
    is refaddr( $env1->bindings->{xs} ),   refaddr( $list ),  'binding holds the interned list';
};

diag "Arena:";
diag "  - allocated = ", $a->arena->num_allocated;
diag "  - alive     = ", $a->arena->num_pointers;



