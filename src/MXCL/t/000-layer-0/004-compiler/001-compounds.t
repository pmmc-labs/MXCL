#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms compiler ];

my $terms    = terms;
my $compiler = compiler;

# -- empty () => Nil --

{
    my $result = $compiler->compile("()");
    is scalar @$result, 1, 'compile "()" returns one term';

    my $got = $result->[0];
    is refaddr($got), refaddr($terms->Nil),
        'compile "()" yields same ref as terms->Nil';
}

# -- empty +{} => Hash() --

{
    my $result = $compiler->compile("+{}");
    is scalar @$result, 1, 'compile "+{}" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Hash';
    is refaddr($got), refaddr($terms->Hash()),
        'compile "+{}" yields same ref as terms->Hash()';
}

# -- empty +[] => Array() --

{
    my $result = $compiler->compile("+[]");
    is scalar @$result, 1, 'compile "+[]" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Array';
    is refaddr($got), refaddr($terms->Array()),
        'compile "+[]" yields same ref as terms->Array()';
}

# -- (a b) => List(Sym("a"), Sym("b")) --

{
    my $result = $compiler->compile("(a b)");
    is scalar @$result, 1, 'compile "(a b)" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Cons',
        'result is a Cons (list)';

    # head is Sym("a")
    is refaddr($got->head), refaddr($terms->Sym("a")),
        'head is Sym("a")';

    # tail is a Cons
    my $tail = $got->tail;
    isa_ok $tail, 'MXCL::Term::Cons',
        'tail is a Cons';

    # tail head is Sym("b")
    is refaddr($tail->head), refaddr($terms->Sym("b")),
        'tail head is Sym("b")';

    # tail tail is Nil
    isa_ok $tail->tail, 'MXCL::Term::Nil',
        'tail tail is Nil';

    # whole thing matches terms->List(...)
    my $expected = $terms->List($terms->Sym("a"), $terms->Sym("b"));
    is refaddr($got), refaddr($expected),
        'compile "(a b)" yields same ref as terms->List(Sym("a"), Sym("b"))';
}

# -- +{ :foo 10 } => List(Sym("make-hash"), Tag("foo"), Num(10)) --

{
    my $result = $compiler->compile("+{ :foo 10 }");
    is scalar @$result, 1, 'compile "+{ :foo 10 }" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Cons',
        'result is a Cons (list)';

    # head is Sym("make-hash")
    is refaddr($got->head), refaddr($terms->Sym("make-hash")),
        'head is Sym("make-hash")';

    # second element is Tag("foo")
    my $second = $got->tail;
    isa_ok $second, 'MXCL::Term::Cons';
    is refaddr($second->head), refaddr($terms->Tag("foo")),
        'second element is Tag("foo")';

    # third element is Num(10)
    my $third = $second->tail;
    isa_ok $third, 'MXCL::Term::Cons';
    is refaddr($third->head), refaddr($terms->Num(10)),
        'third element is Num(10)';

    # terminated by Nil
    isa_ok $third->tail, 'MXCL::Term::Nil',
        'list terminated by Nil';

    # same ref as constructing manually
    my $expected = $terms->List(
        $terms->Sym("make-hash"),
        $terms->Tag("foo"),
        $terms->Num(10),
    );
    is refaddr($got), refaddr($expected),
        'compile "+{ :foo 10 }" matches terms->List(Sym("make-hash"), Tag("foo"), Num(10))';
}

# -- +[ 1 2 ] => List(Sym("make-array"), Num(1), Num(2)) --

{
    my $result = $compiler->compile("+[ 1 2 ]");
    is scalar @$result, 1, 'compile "+[ 1 2 ]" returns one term';

    my $got = $result->[0];
    isa_ok $got, 'MXCL::Term::Cons',
        'result is a Cons (list)';

    # head is Sym("make-array")
    is refaddr($got->head), refaddr($terms->Sym("make-array")),
        'head is Sym("make-array")';

    # second element is Num(1)
    is refaddr($got->tail->head), refaddr($terms->Num(1)),
        'second element is Num(1)';

    # third element is Num(2)
    is refaddr($got->tail->tail->head), refaddr($terms->Num(2)),
        'third element is Num(2)';

    # terminated by Nil
    isa_ok $got->tail->tail->tail, 'MXCL::Term::Nil',
        'list terminated by Nil';

    # same ref as constructing manually
    my $expected = $terms->List(
        $terms->Sym("make-array"),
        $terms->Num(1),
        $terms->Num(2),
    );
    is refaddr($got), refaddr($expected),
        'compile "+[ 1 2 ]" matches terms->List(Sym("make-array"), Num(1), Num(2))';
}

# -- nested: (a (b c)) --

{
    my $result = $compiler->compile("(a (b c))");
    is scalar @$result, 1, 'compile "(a (b c))" returns one term';

    my $outer = $result->[0];
    isa_ok $outer, 'MXCL::Term::Cons',
        'outer result is a Cons';

    # outer head is Sym("a")
    is refaddr($outer->head), refaddr($terms->Sym("a")),
        'outer head is Sym("a")';

    # outer tail head is the inner list
    my $inner = $outer->tail->head;
    isa_ok $inner, 'MXCL::Term::Cons',
        'second element is itself a Cons (nested list)';

    # inner head is Sym("b")
    is refaddr($inner->head), refaddr($terms->Sym("b")),
        'inner head is Sym("b")';

    # inner tail head is Sym("c")
    is refaddr($inner->tail->head), refaddr($terms->Sym("c")),
        'inner second element is Sym("c")';

    # inner tail tail is Nil
    isa_ok $inner->tail->tail, 'MXCL::Term::Nil',
        'inner list terminated by Nil';

    # outer tail tail is Nil (only two elements in outer list)
    isa_ok $outer->tail->tail, 'MXCL::Term::Nil',
        'outer list terminated by Nil';

    # same ref as constructing manually
    my $expected = $terms->List(
        $terms->Sym("a"),
        $terms->List(
            $terms->Sym("b"),
            $terms->Sym("c"),
        ),
    );
    is refaddr($outer), refaddr($expected),
        'compile "(a (b c))" matches nested terms->List(...)';
}

done_testing;
