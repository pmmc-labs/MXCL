
use v5.42;
use experimental qw[ class ];

use Scalar::Util ();

class MXCL::Compiler {
    field $parser :param :reader;
    field $alloc  :param :reader;

    method compile ($source) {
        my $compounds = $parser->parse($source);
        $alloc->arena->commit_generation('parser finished');
        my $expanded  = $self->expand($compounds);
        return $expanded;
    }

    method expand ($compounds) {
        return +[ map $self->expand_expression($_), @$compounds ]
    }

    method expand_expression ($expr) {
        if ($expr isa MXCL::Term::Parser::Compound) {
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
            return $alloc->Hash  if $open eq "+{";
            return $alloc->Array if $open eq "+[";
            return $alloc->Nil; # empty list
        }

        # ...
        my @list = map $self->expand_expression( $_ ), @items;

        unshift @list => $alloc->Sym('make-hash')   if $open eq "+{";
        unshift @list => $alloc->Sym('make-array')  if $open eq "+[";

        # otherwise it is a list ...
        return $alloc->List( @list );
    }
}
