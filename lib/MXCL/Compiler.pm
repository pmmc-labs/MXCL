
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
            return $context->terms->Hash  if $open eq "+{";
            return $context->terms->Array if $open eq "+[";
            return $context->terms->Nil; # empty list
        }

        # ...
        my @list = map $self->expand_expression( $_ ), @items;

        unshift @list => $context->terms->Sym('make-hash')
            if $compound->open->source eq "+{";

        unshift @list => $context->terms->Sym('make-array')
            if $compound->open->source eq "+[";

        # otherwise it is a list ...
        return $context->terms->List( @list );
    }
}
