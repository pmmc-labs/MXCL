#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;
use Scalar::Util qw[ refaddr ];

use Test::MXCL qw[ terms compiler ];

my $terms    = terms;
my $compiler = compiler;

# --- traditional "keywords" compile as plain Sym terms ---

{
    my @keywords = qw( if define lambda while do );

    for my $kw (@keywords) {
        my $result = $compiler->compile($kw);
        is scalar @$result, 1, "compile \"$kw\" returns one term";

        my $got = $result->[0];
        isa_ok $got, 'MXCL::Term::Sym',
            "\"$kw\" compiles to a Sym";

        ok $got->eq($terms->Sym($kw)),
            "compiled \"$kw\" eq terms->Sym(\"$kw\")";

        is refaddr($got), refaddr($terms->Sym($kw)),
            "compiled \"$kw\" is same ref as terms->Sym(\"$kw\")";
    }
}

# --- no type distinction between "keywords" and user symbols ---

{
    my $sym_if      = $terms->Sym("if");
    my $sym_user    = $terms->Sym("my-func");

    is ref($sym_if), ref($sym_user),
        'Sym("if") and Sym("my-func") have the same blessed type';

    is ref($sym_if), 'MXCL::Term::Sym',
        'both are MXCL::Term::Sym';

    # they differ in value, not in kind
    isnt $sym_if->hash, $sym_user->hash,
        'Sym("if") and Sym("my-func") differ in hash (different values)';

    isnt refaddr($sym_if), refaddr($sym_user),
        'Sym("if") and Sym("my-func") differ in refaddr';

    is $sym_if->value, "if",
        'Sym("if") has value "if"';

    is $sym_user->value, "my-func",
        'Sym("my-func") has value "my-func"';
}

# --- structural equivalence of "keyword" and user expressions ---

{
    my $kw_expr   = $compiler->compile("(if x y z)")->[0];
    my $user_expr = $compiler->compile("(f a b c)")->[0];

    # both are Cons (list) structures
    isa_ok $kw_expr,   'MXCL::Term::Cons', '"(if x y z)" is a Cons';
    isa_ok $user_expr, 'MXCL::Term::Cons', '"(f a b c)" is a Cons';

    # both have exactly 4 elements
    my @kw_items   = $terms->Uncons($kw_expr);
    my @user_items = $terms->Uncons($user_expr);

    is scalar @kw_items,   4, '"(if x y z)" has 4 elements';
    is scalar @user_items, 4, '"(f a b c)" has 4 elements';

    # every element in both lists is a Sym
    for my $i (0 .. 3) {
        isa_ok $kw_items[$i],   'MXCL::Term::Sym',
            "element $i of (if x y z) is a Sym";
        isa_ok $user_items[$i], 'MXCL::Term::Sym',
            "element $i of (f a b c) is a Sym";
    }

    # they differ only in which Sym values appear, not in structure
    isnt $kw_expr->hash, $user_expr->hash,
        '"(if x y z)" and "(f a b c)" have different hashes (different Sym values)';

    # but structurally they are the same kind: both Cons, same length, all Sym leaves
    is ref($kw_expr), ref($user_expr),
        'both are the same Perl class (Cons)';
}

# --- no keyword markers in compiled output ---

{
    # compile a mix of "keyword" and user expressions
    my $program = $compiler->compile("(if (eq x 0) (do (print x)) (define y 1))");

    is scalar @$program, 1, 'whole program compiles to one top-level term';

    # walk the entire tree and verify every node is a standard Term type --
    # no special keyword wrappers, no annotation objects, just Terms
    my @queue = ($program->[0]);
    my $node_count = 0;

    while (@queue) {
        my $node = shift @queue;
        $node_count++;

        ok $node->isa('MXCL::Term'),
            "node $node_count is an MXCL::Term";

        # no node should be anything other than the standard term types
        ok(
            $node->isa('MXCL::Term::Cons')
            || $node->isa('MXCL::Term::Sym')
            || $node->isa('MXCL::Term::Num')
            || $node->isa('MXCL::Term::Nil')
            || $node->isa('MXCL::Term::Str')
            || $node->isa('MXCL::Term::Bool')
            || $node->isa('MXCL::Term::Tag'),
            "node $node_count is a standard term type (no keyword wrappers)"
        );

        # descend into Cons nodes
        if ($node->isa('MXCL::Term::Cons')) {
            push @queue, $node->head, $node->tail;
        }
    }

    ok $node_count > 1, "walked $node_count nodes in the tree (non-trivial structure)";
}

done_testing;
