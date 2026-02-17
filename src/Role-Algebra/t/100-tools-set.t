#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Digest::MD5 ();

use Roles::Tools::Set;

class Sym {
    field $ident :reader :param;
    field $hash  :reader;

    ADJUST {
        $hash = Digest::MD5::md5_hex(__CLASS__, $ident);
    }

    method to_string { $ident }
}

sub to_s (@args) { join '' => map { blessed $_ ? $_->to_string : $_ } @args }

my $a = Roles::Tools::Set->new;
my $b = Roles::Tools::Set->new(items => [ map { Sym->new(ident => $_) } qw( a b c ) ]);
my $c = Roles::Tools::Set->new(items => [ map { Sym->new(ident => $_) } qw( c d e ) ]);

isa_ok $a, 'Roles::Tools::Set';
isa_ok $b, 'Roles::Tools::Set';
isa_ok $c, 'Roles::Tools::Set';

is $a->size, 0, to_s( "size of ", $a, " is 0" );
is $b->size, 3, to_s( "size of ", $b, " is 3" );

ok $b->contains(map { Sym->new(ident => $_) } qw( a c )), to_s( $b, " contains 'a' and 'c'" );
ok $b->contains(map { Sym->new(ident => $_) } qw( a c )), "has() is an alias for contains()";
ok !$a->contains(map { Sym->new(ident => $_) } ('b')), to_s( $a, " does not contain 'b'" );
ok $a->contains(), to_s( $a, " contains the empty list" );

ok $a->is_empty,  to_s( $a, " is empty" );
ok !$b->is_empty, to_s( $b, " is not empty" );

ok $a->is_equal($a),  to_s( $a, " is equal to ",     $a );
ok $b->is_equal($b),  to_s( $b, " is equal to ",     $b );
ok !$a->is_equal($b), to_s( $a, " is not equal to ", $b );

ok $a->is_subset($a),  to_s( $a, " is a subset of ",     $a );
ok $a->is_subset($b),  to_s( $a, " is a subset of ",     $b );
ok $b->is_subset($b),  to_s( $b, " is a subset of ",     $b );
ok !$b->is_subset($a), to_s( $b, " is not a subset of ", $a );

ok $a->is_proper_subset($b),  to_s( $a, " is a proper subset of ",     $b );
ok !$a->is_proper_subset($a), to_s( $a, " is not a proper subset of ", $a );
ok !$b->is_proper_subset($b), to_s( $b, " is not a proper subset of ", $b );
ok !$b->is_proper_subset($a), to_s( $b, " is not a proper subset of ", $a );

ok $b->is_superset($b),  to_s( $b, " is a superset of ",     $b );
ok $b->is_superset($a),  to_s( $b, " is a superset of ",     $a );
ok $a->is_superset($a),  to_s( $a, " is a superset of ",     $a );
ok !$a->is_superset($b), to_s( $a, " is not a superset of ", $b );

ok $b->is_proper_superset($a),  to_s( $b, " is a proper superset of ",     $a );
ok !$b->is_proper_superset($b), to_s( $b, " is not a proper superset of ", $b );
ok !$a->is_proper_superset($a), to_s( $a, " is not a proper superset of ", $a );
ok !$a->is_proper_superset($b), to_s( $a, " is not a proper superset of ", $b );

ok $a->is_disjoint($a),  to_s( $a, " and ", $a, " are disjoint" );
ok $a->is_disjoint($b),  to_s( $a, " and ", $b, " are disjoint" );
ok !$b->is_disjoint($b), to_s( $b, " and ", $b, " are not disjoint" );

ok !$a->is_properly_intersecting($b),
    to_s( $a, " is not properly intersecting ", $b );
ok !$a->is_properly_intersecting($a),
    to_s( $a, " is not properly intersecting ", $a );
ok !$b->is_properly_intersecting($b),
    to_s( $b, " is not properly intersecting ", $b );

my $d1 = $b->difference($c);
my $d2 = $c->difference($b);

isa_ok $d1, 'Roles::Tools::Set';
isa_ok $d2, 'Roles::Tools::Set';

is $d1->to_string, '(a b)',
    to_s( "difference of ", $b, " and ", $c, " is ", $d1 );
is $d2->to_string, '(d e)',
    to_s( "difference of ", $c, " and ", $b, " is ", $d2 );

my $u  = $b->union($c);
my $i  = $b->intersection($c);
my $s  = $b->symmetric_difference($c);

isa_ok $u, 'Roles::Tools::Set';
isa_ok $i, 'Roles::Tools::Set';
isa_ok $s, 'Roles::Tools::Set';

is $u->to_string, '(a b c d e)',
    to_s( "union of ", $b, " and ", $c, " is ", $u );
is $i->to_string, '(c)',
    to_s( "intersection of ", $b, " and ", $c, " is ", $i );
is $s->to_string, '(a b d e)',
    to_s( "symmetric difference of ", $b, " and ", $c, " is ", $s );

done_testing;






