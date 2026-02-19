#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use Test::MXCL qw[ parser ];

# -- tokenize a number --

subtest '... tokenize a number' => sub {
    my $tokens = parser->tokenize("42");
    is scalar @$tokens, 1, 'got one token';
    is $tokens->[0]->source, '42', 'source is 42';
};

# -- tokenize a symbol --

subtest '... tokenize a symbol' => sub {
    my $tokens = parser->tokenize("foo");
    is scalar @$tokens, 1, 'got one token';
    is $tokens->[0]->source, 'foo', 'source is foo';
};

# -- tokenize a string --

subtest '... tokenize a string' => sub {
    my $tokens = parser->tokenize('"hello"');
    is scalar @$tokens, 1, 'got one token';
    is $tokens->[0]->source, '"hello"', 'source includes quotes';
};

# -- tokenize a tag --

subtest '... tokenize a tag' => sub {
    my $tokens = parser->tokenize(":foo");
    is scalar @$tokens, 1, 'got one token';
    is $tokens->[0]->source, ':foo', 'source is :foo';
};

# -- tokenize brackets --

subtest '... tokenize brackets' => sub {
    my $tokens = parser->tokenize("(a b)");
    is scalar @$tokens, 4, 'got 4 tokens';
    is $tokens->[0]->source, '(', 'open paren';
    is $tokens->[1]->source, 'a', 'first symbol';
    is $tokens->[2]->source, 'b', 'second symbol';
    is $tokens->[3]->source, ')', 'close paren';
};

# -- tokenize hash brackets --

subtest '... tokenize hash brackets' => sub {
    my $tokens = parser->tokenize("+{ :x 1 }");
    is scalar @$tokens, 4, 'got 4 tokens';
    is $tokens->[0]->source, '+{', 'hash open bracket';
    is $tokens->[1]->source, ':x', 'tag';
    is $tokens->[2]->source, '1', 'value';
    is $tokens->[3]->source, '}', 'close brace';
};

# -- tokenize array brackets --

subtest '... tokenize array brackets' => sub {
    my $tokens = parser->tokenize("+[ 1 2 ]");
    is scalar @$tokens, 4, 'got 4 tokens';
    is $tokens->[0]->source, '+[', 'array open bracket';
    is $tokens->[1]->source, '1', 'first value';
    is $tokens->[2]->source, '2', 'second value';
    is $tokens->[3]->source, ']', 'close bracket';
};

# -- whitespace is consumed --

subtest '... whitespace is consumed' => sub {
    my $tokens = parser->tokenize("a   b");
    is scalar @$tokens, 2, 'spaces are not tokens';
    is $tokens->[0]->source, 'a', 'first token';
    is $tokens->[1]->source, 'b', 'second token';
};

# -- newlines are consumed --

subtest '... newlines are consumed' => sub {
    my $tokens = parser->tokenize("a\nb");
    is scalar @$tokens, 2, 'newlines are not tokens';
    is $tokens->[0]->source, 'a', 'first token';
    is $tokens->[1]->source, 'b', 'second token';
};

# -- quote character before bracket --

subtest '... quote character before bracket' => sub {
    my $tokens = parser->tokenize("'(x)");
    is scalar @$tokens, 4, 'got 4 tokens';
    is $tokens->[0]->source, "'", 'quote is a separate token';
    is $tokens->[1]->source, '(', 'open paren';
    is $tokens->[2]->source, 'x', 'symbol';
    is $tokens->[3]->source, ')', 'close paren';
};

# -- multiple expressions --

subtest '... multiple expressions' => sub {
    my $tokens = parser->tokenize("a b c");
    is scalar @$tokens, 3, 'got 3 tokens';
    is $tokens->[0]->source, 'a', 'first';
    is $tokens->[1]->source, 'b', 'second';
    is $tokens->[2]->source, 'c', 'third';
};

# -- token position tracking --

subtest '... token position tracking' => sub {
    my $tokens = parser->tokenize("a\nb\nc");
    is scalar @$tokens, 3, 'got 3 tokens';

    is $tokens->[0]->line, 0, 'first token is on line 0';
    is $tokens->[1]->line, 1, 'second token is on line 1';
    is $tokens->[2]->line, 2, 'third token is on line 2';
};

done_testing;
