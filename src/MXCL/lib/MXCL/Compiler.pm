
use v5.42;
use experimental qw[ class ];

use Scalar::Util ();

class MXCL::Compiler {
    field $context :param :reader;

    method compile ($source) {
        my $compounds = $context->parser->parse($source);
        my $expanded  = $self->expand($compounds);
        return $expanded;
    }

    method expand ($compounds) {
        return +[ map $self->expand_expression($_), @$compounds ]
    }

    method expand_expression ($expr) {
        if ($expr isa MXCL::Parser::Compound) {
            return $self->expand_compound( $expr );
        } else {
            return $self->expand_token( $expr );
        }
    }

    method expand_token ($token) {
        my $src = $token->source;
        return $context->terms->True  if $src eq 'true';
        return $context->terms->False if $src eq 'false';
        if ($src =~ /^\".*\"$/) {
            my $str = substr($src, 1, length($src) - 2);
            $str = "\n" if $str eq "\\n";
            $str = "\t" if $str eq "\\t";
            return $context->terms->Str( $str );
        }
        return $context->terms->Num( 0+$src ) if Scalar::Util::looks_like_number($src);
        return $context->terms->Tag( substr($src, 1) ) if $src =~ /^\:/;
        return $context->terms->Sym( $src );
    }

    method expand_compound ($compound) {
        my @items = $compound->items->@*;
        my $open  = $compound->open->source;

        # expand empty compounds based on delimiter type
        if (scalar @items == 0) {
            die 'MXCL::Term::Tuple not yet supported' if $open eq "[";
            die 'MXCL::Term::Hash not yet supported'  if $open eq "%{";
            # FIXME - return an empty Array here
            die 'MXCL::Term::Array not yet supported' if $open eq "@[";
            return $context->terms->Nil; # () and {} with no content
        }

        # expand pairs at compile time,
        # as they are constructive
        if (scalar @items == 3 && $items[1] isa MXCL::Parser::Token && $items[1]->source eq '.') {
            die "MXCL::Pair not yet supported";
            #my ($fst, $dot, $snd) = @items;
            #return MXCL::Term::Pair->new(
            #    fst => $self->expand_expression($fst),
            #    snd => $self->expand_expression($snd),
            #);
        }

        # ...
        my @list = map $self->expand_expression( $_ ), @items;

        # expand quoted lists ...
        unshift @list => $context->terms->Sym('quote')
            if $compound->open->source eq "'";

        # expand blocks ...
        unshift @list => $context->terms->Sym('do')
            if $compound->open->source eq "{";

        # expand hashes ...
        unshift @list => $context->terms->Sym('hash/new')
            if $compound->open->source eq "%{";

        # expand tuples ...
        unshift @list => $context->terms->Sym('tuple/new')
            if $compound->open->source eq "[";

        # TODO:
        # don't expand the arrays, return an Array term
        # similar to how Lists work below.
        unshift @list => $context->terms->Sym('array/new')
            if $compound->open->source eq "@[";

        # otherwise it is a list ...
        return $context->terms->List( @list );
    }
}
