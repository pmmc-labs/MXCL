#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ arena terms ];

# --- allocate directly via arena ---

my $num = arena->allocate(MXCL::Term::Num::, value => 42);

isa_ok $num, 'MXCL::Term', 'arena->allocate returns a Term';
isa_ok $num, 'MXCL::Term::Num', '... specifically a Num';

ok defined($num->hash), '... term has a defined hash';
ok length($num->hash) > 0, '... hash is a non-empty string';

ok defined($num->gen), '... term has a defined gen';
like $num->gen, qr/^\d+$/, '... gen is a number';

# --- allocate via terms factory ---

my $num2 = terms->Num(99);

isa_ok $num2, 'MXCL::Term', 'terms->Num returns a Term';
isa_ok $num2, 'MXCL::Term::Num', '... specifically a Num';

ok defined($num2->hash), '... factory term has a defined hash';
ok length($num2->hash) > 0, '... hash is a non-empty string';

ok defined($num2->gen), '... factory term has a defined gen';
like $num2->gen, qr/^\d+$/, '... gen is a number';

# --- allocate other types via factory ---

my $str = terms->Str("hello");
isa_ok $str, 'MXCL::Term::Str', 'terms->Str returns a Str';
ok defined($str->hash), '... Str has a defined hash';

my $nil = terms->Nil;
isa_ok $nil, 'MXCL::Term::Nil', 'terms->Nil returns a Nil';
ok defined($nil->hash), '... Nil has a defined hash';

my $cons = terms->Cons($num, $nil);
isa_ok $cons, 'MXCL::Term::Cons', 'terms->Cons returns a Cons';
ok defined($cons->hash), '... Cons has a defined hash';

done_testing;
