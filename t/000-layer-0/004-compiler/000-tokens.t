#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms compiler ];

my $terms    = terms;
my $compiler = compiler;

# -- true => Bool(true) --

{
    my $result = $compiler->compile("true");
    is scalar @$result, 1, 'compile "true" returns one term';

    my $got = $result->[0];
    is refaddr($got), refaddr($terms->True),
        'compile "true" yields the same ref as terms->True';
}

# -- false => Bool(false) --

{
    my $result = $compiler->compile("false");
    is scalar @$result, 1, 'compile "false" returns one term';

    my $got = $result->[0];
    is refaddr($got), refaddr($terms->False),
        'compile "false" yields the same ref as terms->False';
}

# -- integer 42 => Num(42) --

{
    my $result = $compiler->compile("42");
    is scalar @$result, 1, 'compile "42" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Num';
    is refaddr($got), refaddr($terms->Num(42)),
        'compile "42" yields same ref as terms->Num(42)';
}

# -- float 3.14 => Num(3.14) --

{
    my $result = $compiler->compile("3.14");
    is scalar @$result, 1, 'compile "3.14" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Num';
    is refaddr($got), refaddr($terms->Num(3.14)),
        'compile "3.14" yields same ref as terms->Num(3.14)';
}

# -- 0 => Num(0), not Bool(false) --

{
    my $result = $compiler->compile("0");
    is scalar @$result, 1, 'compile "0" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Num',
        'compile "0" produces a Num, not Bool';
    is refaddr($got), refaddr($terms->Num(0)),
        'compile "0" yields same ref as terms->Num(0)';
    isnt refaddr($got), refaddr($terms->False),
        'compile "0" is not the same ref as terms->False';
}

# -- tag :foo => Tag("foo") --

{
    my $result = $compiler->compile(":foo");
    is scalar @$result, 1, 'compile ":foo" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Tag';
    is refaddr($got), refaddr($terms->Tag("foo")),
        'compile ":foo" yields same ref as terms->Tag("foo")';
}

# -- bare word hello => Sym("hello") --

{
    my $result = $compiler->compile("hello");
    is scalar @$result, 1, 'compile "hello" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Sym';
    is refaddr($got), refaddr($terms->Sym("hello")),
        'compile "hello" yields same ref as terms->Sym("hello")';
}

# -- quoted string "hello" => Str("hello") --

{
    my $result = $compiler->compile(q["hello"]);
    is scalar @$result, 1, 'compile q["hello"] returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Str';
    is refaddr($got), refaddr($terms->Str("hello")),
        'compile q["hello"] yields same ref as terms->Str("hello")';
}

# -- multiple tokens in one source --

{
    my $result = $compiler->compile("true 42 hello");
    is scalar @$result, 3, 'compile "true 42 hello" returns three terms';

    is refaddr($result->[0]), refaddr($terms->True),
        'first term is True';
    is refaddr($result->[1]), refaddr($terms->Num(42)),
        'second term is Num(42)';
    is refaddr($result->[2]), refaddr($terms->Sym("hello")),
        'third term is Sym("hello")';
}

done_testing;
