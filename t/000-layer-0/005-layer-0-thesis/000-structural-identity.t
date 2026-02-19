#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms compiler ];

my $terms    = terms;
my $compiler = compiler;

# --- compile the same expression twice => identical term ---

{
    my $first  = $compiler->compile("(+ 1 2)");
    my $second = $compiler->compile("(+ 1 2)");

    is scalar @$first, 1,  'compile "(+ 1 2)" returns one term';
    is scalar @$second, 1, 'second compile also returns one term';

    is $first->[0]->hash, $second->[0]->hash,
        'same source compiled twice produces the same hash';

    is refaddr($first->[0]), refaddr($second->[0]),
        'same source compiled twice produces the same refaddr (interned)';
}

# --- whitespace is irrelevant: all forms produce the same term ---

{
    my $compact    = $compiler->compile("(+ 1 2)")->[0];
    my $spaces     = $compiler->compile("(+  1  2)")->[0];
    my $newlines   = $compiler->compile("(+\n1\n2)")->[0];

    is $compact->hash, $spaces->hash,
        '"(+ 1 2)" and "(+  1  2)" produce the same hash';

    is refaddr($compact), refaddr($spaces),
        '"(+ 1 2)" and "(+  1  2)" are the same ref';

    is $compact->hash, $newlines->hash,
        '"(+ 1 2)" and "(+\\n1\\n2)" produce the same hash';

    is refaddr($compact), refaddr($newlines),
        '"(+ 1 2)" and "(+\\n1\\n2)" are the same ref';
}

# --- manually built term matches compiled term ---

{
    my $compiled = $compiler->compile("(+ 1 2)")->[0];
    my $manual   = $terms->List(
        $terms->Sym("+"),
        $terms->Num(1),
        $terms->Num(2),
    );

    is $compiled->hash, $manual->hash,
        'compiled "(+ 1 2)" has same hash as manually built List(Sym(+), Num(1), Num(2))';

    is refaddr($compiled), refaddr($manual),
        'compiled and manually built terms are the exact same ref';
}

# --- nested structures: compile twice => identical refs all the way down ---

{
    my $first  = $compiler->compile("(f (g x))")->[0];
    my $second = $compiler->compile("(f (g x))")->[0];

    is refaddr($first), refaddr($second),
        'nested "(f (g x))" compiled twice: outer Cons is same ref';

    # walk into the structure: first element is Sym("f")
    my @outer_1 = $terms->Uncons($first);
    my @outer_2 = $terms->Uncons($second);

    is scalar @outer_1, 2, 'outer list has 2 elements (f and (g x))';
    is scalar @outer_2, 2, 'second outer list also has 2 elements';

    is refaddr($outer_1[0]), refaddr($outer_2[0]),
        'Sym("f") sub-terms are same ref';

    is refaddr($outer_1[1]), refaddr($outer_2[1]),
        'inner "(g x)" sub-terms are same ref';

    # walk into the inner (g x)
    my @inner_1 = $terms->Uncons($outer_1[1]);
    my @inner_2 = $terms->Uncons($outer_2[1]);

    is refaddr($inner_1[0]), refaddr($inner_2[0]),
        'Sym("g") sub-terms are same ref';

    is refaddr($inner_1[1]), refaddr($inner_2[1]),
        'Sym("x") sub-terms are same ref';
}

# --- sub-expression sharing: identical sub-terms share a single ref ---

{
    my $result = $compiler->compile("(+ 1 1)")->[0];

    my @elements = $terms->Uncons($result);
    is scalar @elements, 3, '"(+ 1 1)" has 3 elements: +, 1, 1';

    my $num1_a = $elements[1];
    my $num1_b = $elements[2];

    isa_ok $num1_a, 'MXCL::Term::Num';
    isa_ok $num1_b, 'MXCL::Term::Num';

    is refaddr($num1_a), refaddr($num1_b),
        'the two Num(1) sub-terms in "(+ 1 1)" are the exact same ref';
}

done_testing;
