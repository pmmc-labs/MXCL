
use v5.42;
use experimental qw[ class ];

use Scalar::Util ();

use MXCL::Parser;

class MXCL::Compiler {
    field $alloc  :param :reader;
    field $parser :param :reader;

    method compile ($source) {
        my $compounds = $parser->parse($source);
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
        return $alloc->True  if $src eq 'true';
        return $alloc->False if $src eq 'false';
        if ($src =~ /^\".*\"$/) {
            my $str = substr($src, 1, length($src) - 2);
            $str = "\n" if $str eq "\\n";
            $str = "\t" if $str eq "\\t";
            return $alloc->Str( $str );
        }
        return $alloc->Num( 0+$src ) if Scalar::Util::looks_like_number($src);
        return $alloc->Tag( substr($src, 1) ) if $src =~ /^\:/;
        return $alloc->Sym( $src );
    }

    method expand_compound ($compound) {
        my @items = $compound->items->@*;
        my $open  = $compound->open->source;

        # expand empty compounds based on delimiter type
        if (scalar @items == 0) {
            die 'MXCL::Term::Tuple not yet supported' if $open eq "[";
            die 'MXCL::Term::Array not yet supported' if $open eq "@[";
            die 'MXCL::Term::Hash not yet supported'  if $open eq "%{";
            return $alloc->Nil; # () and {} with no content
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
        unshift @list => $alloc->Sym('quote')
            if $compound->open->source eq "'";

        # expand blocks ...
        unshift @list => $alloc->Sym('do')
            if $compound->open->source eq "{";

        # expand hashes ...
        unshift @list => $alloc->Sym('hash/new')
            if $compound->open->source eq "%{";

        # expand tuples ...
        unshift @list => $alloc->Sym('tuple/new')
            if $compound->open->source eq "[";

        # expand arrays ...
        unshift @list => $alloc->Sym('array/new')
            if $compound->open->source eq "@[";

        # otherwise it is a list ...
        return $alloc->List( @list );
    }
}
