#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use Test::MXCL qw[ parser ];

# -- parse simple compound --

subtest '... parse (a b c)' => sub {
    my $exprs = parser->parse("(a b c)");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';
    is $compound->open->source, '(', 'open bracket is (';
    is $compound->close->source, ')', 'close bracket is )';

    my $items = $compound->items;
    is scalar @$items, 3, 'compound has 3 items';

    isa_ok $items->[0], 'MXCL::Parser::Token';
    is $items->[0]->source, 'a', 'first item is a';
    isa_ok $items->[1], 'MXCL::Parser::Token';
    is $items->[1]->source, 'b', 'second item is b';
    isa_ok $items->[2], 'MXCL::Parser::Token';
    is $items->[2]->source, 'c', 'third item is c';
};

# -- parse nested compound --

subtest '... parse (a (b c))' => sub {
    my $exprs = parser->parse("(a (b c))");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';

    my $items = $compound->items;
    is scalar @$items, 2, 'outer compound has 2 items';

    isa_ok $items->[0], 'MXCL::Parser::Token';
    is $items->[0]->source, 'a', 'first item is Token a';

    my $inner = $items->[1];
    isa_ok $inner, 'MXCL::Parser::Compound';
    is $inner->open->source, '(', 'inner open is (';

    my $inner_items = $inner->items;
    is scalar @$inner_items, 2, 'inner compound has 2 items';
    is $inner_items->[0]->source, 'b', 'inner first is b';
    is $inner_items->[1]->source, 'c', 'inner second is c';
};

# -- parse hash brackets --

subtest '... parse +{ :foo 10 }' => sub {
    my $exprs = parser->parse("+{ :foo 10 }");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';
    is $compound->open->source, '+{', 'open bracket is +{';
    is $compound->close->source, '}', 'close bracket is }';

    my $items = $compound->items;
    is scalar @$items, 2, 'compound has 2 items';
    is $items->[0]->source, ':foo', 'first item is :foo';
    is $items->[1]->source, '10', 'second item is 10';
};

# -- parse array brackets --

subtest '... parse +[ 1 2 ]' => sub {
    my $exprs = parser->parse("+[ 1 2 ]");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';
    is $compound->open->source, '+[', 'open bracket is +[';
    is $compound->close->source, ']', 'close bracket is ]';

    my $items = $compound->items;
    is scalar @$items, 2, 'compound has 2 items';
    is $items->[0]->source, '1', 'first item is 1';
    is $items->[1]->source, '2', 'second item is 2';
};

# -- parse quote --

subtest '... parse quote expression' => sub {
    my $exprs = parser->parse("'(a)");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';
    is $compound->open->source, "'", 'open is quote character';

    my $items = $compound->items;
    is scalar @$items, 1, 'quote compound has 1 item';
    isa_ok $items->[0], 'MXCL::Parser::Compound', 'quoted item is a Compound';
    is $items->[0]->open->source, '(', 'quoted item open is (';

    my $inner_items = $items->[0]->items;
    is scalar @$inner_items, 1, 'inner compound has 1 item';
    is $inner_items->[0]->source, 'a', 'inner item is a';
};

# -- parse multiple top-level expressions --

subtest '... parse multiple top-level expressions' => sub {
    my $exprs = parser->parse("a (b c)");
    is scalar @$exprs, 2, 'two top-level expressions';

    isa_ok $exprs->[0], 'MXCL::Parser::Token';
    is $exprs->[0]->source, 'a', 'first is Token a';

    isa_ok $exprs->[1], 'MXCL::Parser::Compound';
    my $items = $exprs->[1]->items;
    is scalar @$items, 2, 'compound has 2 items';
    is $items->[0]->source, 'b', 'first item is b';
    is $items->[1]->source, 'c', 'second item is c';
};

# -- parse empty parens --

subtest '... parse empty parens' => sub {
    my $exprs = parser->parse("()");
    is scalar @$exprs, 1, 'one top-level expression';

    my $compound = $exprs->[0];
    isa_ok $compound, 'MXCL::Parser::Compound';
    is $compound->open->source, '(', 'open is (';
    is $compound->close->source, ')', 'close is )';

    my $items = $compound->items;
    is scalar @$items, 0, 'compound has 0 items';
};

# -- mismatched brackets die --

subtest '... mismatched brackets die' => sub {
    eval { parser->parse("(a b]") };
    ok $@, 'mismatched brackets (a b] throws an error';
    like $@, qr/Unbalanced Brackets/, 'error message mentions Unbalanced Brackets';
};

done_testing;
