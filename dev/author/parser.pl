#!perl

use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];
use List::Util qw[ max min uniq ];
use Time::HiRes ();

use MXCL::Context;
use MXCL::Debugger;

my $context = MXCL::Context->new;

my $exprs = $context->parser->parse(q[

(let source "Given$a$text$file$of$many$lines,$where$fields$within$a$line$
are$delineated$by$a$single$'dollar'$character,$write$a$program
that$aligns$each$column$of$fields$by$ensuring$that$words$in$each$
column$are$separated$by$at$least$one$space.
Further,$allow$for$each$word$in$a$column$to$be$either$left$
justified,$right$justified,$or$center$justified$within$its$column.")


]);

my $program = $context->compiler->compile(q[

(define map (f lst)
    (if (nil? lst)
        ()
        (cons (f (head lst)) (map f (tail lst)))))

]);

say "COMPILED:";
say $_->pprint foreach @$program;

MXCL::Debugger->visualize_term($context, $_) foreach @$program;

sub traverse ($t, $f, $depth=0) {
    given (blessed $t) {
        when ('MXCL::Term::Parser::Token') {
            $f->($t, $depth);
        }
        when ('MXCL::Term::Parser::Compound') {
            $f->($t->open, $depth);
            foreach my $token ($t->items->@*) {
                traverse( $token, $f, $depth + 1 );
            }
            $f->($t->close, $depth);
        }
    }
}

say "PROGRAM:";
foreach my $expr (@$exprs) {
    say '─' x 80;
    traverse($expr, sub ($t, $depth) {
        say sprintf '%s%s' => ('  ' x $depth), $t->source;
    });
    say $expr->pprint;
}
say '─' x 80;
