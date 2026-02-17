#!perl

use v5.42;
use experimental qw[ class switch ];

use List::Util;

## -----------------------------------------------------------------------------

class Term {
    method eq;
}

class Sym :isa(Term) {
    field $name :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) && $other->name eq $name
    }
}

class Num :isa(Term) {
    field $value :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) && $other->value == $value
    }
}

class Nil :isa(Term) {
    method eq ($other) { $other->isa(__CLASS__) }
}

class Cons :isa(Term) {
    field $head :param :reader;
    field $tail :param :reader;

    method uncons {
        my @items;
        my $list = $self;
        until ($list isa Nil) {
            push @items => $list->head;
            $list = $list->tail;
        }
        return @items;
    }

    method eq ($other) {
        $other->isa(__CLASS__) &&
            $other->head->eq($head) &&
                $other->tail->eq($tail)
    }
}

class Lambda :isa(Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) &&
            $other->params->eq($params) &&
                $other->body->eq($body)
    }
}

class Native :isa(Term) {
    field $spec :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) && $other->spec eq $spec
    }
}

## -----------------------------------------------------------------------------

sub num ($value)    { Num->new( value => $value ) }
sub sym ($name)     { Sym->new( name => $name ) }
sub nil             { Nil->new }
sub cons ($h, $t)   { Cons->new( head => $h, tail => $t ) }
sub lambda ($p, $b) { Lambda->new( params => $p, body => $b ) }
sub native ($spec)  { Native->new( spec => $spec ) }

## -----------------------------------------------------------------------------

class Slot {
    method ident;
    method eq;
}

class Defined :isa(Slot) {
    field $ident :param :reader;
    field $value :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) &&
            $other->ident->eq($ident) &&
                $other->value->eq($value)
    }
}

class Required :isa(Slot) {
    field $ident :param :reader;

    method eq ($other) {
        $other->isa(__CLASS__) &&
            $other->ident->eq($ident)
    }
}

class Conflict :isa(Slot) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    ADJUST {
        $lhs->ident->eq($rhs->ident) || die 'Conflicted ident must be equal';
    }

    method ident { $lhs->ident }

    method eq ($other) {
        $other->isa(__CLASS__) &&
            $other->lhs->eq($lhs) &&
                $other->rhs->eq($rhs)
    }
}

class Role {
    field $ident :param :reader;
    field $does  :param :reader;
    field $slots :param :reader;

    ADJUST {
        # TODO - de-duplicate `does`
        $does->@*  = sort { $b->ident->name cmp $a->ident->name } $does->@*;
        # TODO - check invariant for unique names
        $slots->@* = sort { $b->ident->name cmp $a->ident->name } $slots->@*;
    }
}

## -----------------------------------------------------------------------------

sub declare  ($ident, $value) { Defined->new( ident => $ident, value => $value ) }
sub required ($ident)         { Required->new( ident => $ident ) }
sub conflict ($lhs, $rhs)      { Conflict->new( lhs => $lhs, rhs => $rhs ) }

sub role ($ident, $does, @slots) {
    Role->new(
        ident => $ident,
        does  => $does,
        slots => \@slots
    )
}

## -----------------------------------------------------------------------------

sub pprint ($t) {
    given (blessed $t) {
        when ('Num')  { $t->value."" }
        when ('Sym')  { $t->name }
        when ('Nil')  { '' }
        when ('Cons') {
            sprintf '(%s)' => join ' ' => map { pprint($_) } $t->uncons;
        }
        when ('Native') { $t->spec }
        when ('Lambda') {
            sprintf "(lambda %s %s)" => pprint($t->params), pprint($t->body)
        }
        # ...
        when ('Role') {
            sprintf "(role %s [%s]\n  %s)" =>
                pprint($t->ident),
                (join ' ' => map { pprint($_->ident) } $t->does->@*),
                join "\n  " => map { pprint($_) } $t->slots->@*;

        }
        when ('Defined') {
            sprintf '(defined  %s %s)' => pprint($t->ident), pprint($t->value)
        }
        when ('Required') {
            sprintf '(required %s)' => pprint($t->ident)
        }
        when ('Conflict') {
            sprintf '(conflict %s %s)' => pprint($t->lhs), pprint($t->rhs)
        }
    }
}

## -----------------------------------------------------------------------------

my $EQ = role( sym('EQ'), [],
    required( sym('==') ),
    declare(
        sym('!='),
        lambda(
            cons(sym('x'), cons(sym('y'), nil())),
            cons(sym('not'), cons(sym('=='), cons(sym('x'), cons(sym('y'), nil())))),
        )
    )
);

my $ORD = role( sym('ORD'), [],
    required( sym('<=>') ),
    declare(sym('=='), lambda(cons(sym('x'), cons(sym('y'), nil())),
        cons(sym('eq?'), cons(
            cons(sym('<=>'), cons(sym('x'), cons(sym('y'), nil()))),
            cons(num(0), nil())
        ))
    )),
    declare(sym('<'), lambda(cons(sym('x'), cons(sym('y'), nil())),
        cons(sym('eq?'), cons(
            cons(sym('<=>'), cons(sym('x'), cons(sym('y'), nil()))),
            cons(num(-1), nil())
        ))
    )),
    declare(sym('>'), lambda(cons(sym('x'), cons(sym('y'), nil())),
        cons(sym('eq?'), cons(
            cons(sym('<=>'), cons(sym('x'), cons(sym('y'), nil()))),
            cons(num(-1), nil())
        ))
    )),
    declare(sym('>='), lambda(cons(sym('x'), cons(sym('y'), nil())),
        cons(sym('>'), cons(
            cons(sym('<=>'), cons(sym('x'), cons(sym('y'), nil()))),
            cons(num(0), nil())
        ))
    )),
    declare(sym('<='), lambda(cons(sym('x'), cons(sym('y'), nil())),
        cons(sym('<'), cons(
            cons(sym('<=>'), cons(sym('x'), cons(sym('y'), nil()))),
            cons(num(0), nil())
        ))
    )),
);

my $NUM = role( sym('NUM'), [],
    declare(
        sym('<=>'),
        native('sub ($x,$y) { $x <=> $y }'),
    )
);

say pprint($EQ);
say pprint($ORD);
say pprint($NUM);

sub merge_slot ($s1, $s2) {
    return $s1 if not defined $s2;
    return $s2 if not defined $s1;
    return $s1 if $s1 isa Required && $s2 isa Required;
    return $s1 if $s1 isa Defined  && $s2 isa Required;
    return $s2 if $s1 isa Required && $s2 isa Defined;
    if ($s1 isa Defined && $s2 isa Defined) {
        if ($s1->eq($s2)) {
            return $s1;
        } else {
            return conflict($s1, $s2);
        }
    }
    die "Cannot Merge Slots (".(blessed($s1) // '???').") and (".(blessed($s2) // '???').")";
}

sub compose ($r1, $r2) {
    my %r1_bindings = map { $_->ident->name, $_ } $r1->slots->@*;
    my %r2_bindings = map { $_->ident->name, $_ } $r2->slots->@*;
    my %merged      = (%r1_bindings, %r2_bindings);
    my @slots       = map {
        merge_slot(
            $r1_bindings{ $_ },
            $r2_bindings{ $_ }
        )
    } keys %merged;

    return role(
        sym(sprintf '%s(%s)' => $r1->ident->name, $r2->ident->name),
        [ $r1, $r2 ],
        @slots
    );
}

say pprint(compose($EQ, $ORD));
say pprint(compose($NUM, compose($EQ, $ORD)));




