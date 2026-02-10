
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term;

use MXCL::Term::Nil;
use MXCL::Term::Cons;

use MXCL::Term::Bool;
use MXCL::Term::Num;
use MXCL::Term::Str;
use MXCL::Term::Tag;

use MXCL::Term::Array;

use MXCL::Term::Sym;
use MXCL::Term::Env;

use MXCL::Term::Lambda;
use MXCL::Term::Opaque;

use MXCL::Term::Native::Applicative;
use MXCL::Term::Native::Operative;

class MXCL::Allocator::Terms {
    field $arena :param :reader;

    field $nil;
    field $true;
    field $false;

    ADJUST {
        $nil   = $arena->allocate(MXCL::Term::Nil::);
        $true  = $arena->allocate(MXCL::Term::Bool::, value => true);
        $false = $arena->allocate(MXCL::Term::Bool::, value => false);
    }

    method Nil   { $nil }
    method True  { $true }
    method False { $false }

    method Bool ($value) { $value ? $true : $false }

    method Num ($value) { $arena->allocate(MXCL::Term::Num::, value => $value) }
    method Str ($value) { $arena->allocate(MXCL::Term::Str::, value => $value) }
    method Sym ($value) { $arena->allocate(MXCL::Term::Sym::, value => $value) }
    method Tag ($value) { $arena->allocate(MXCL::Term::Tag::, value => $value) }

    method Cons ($head, $tail) {
        $arena->allocate(MXCL::Term::Cons::, head => $head, tail => $tail )
    }

    method Lambda ($params, $body, $env) {
        $arena->allocate(MXCL::Term::Lambda::, params => $params, body => $body, env => $env )
    }

    method Array (@elements) {
        $arena->allocate(MXCL::Term::Array::, elements => \@elements )
    }

    ## -------------------------------------------------------------------------
    ## Opaque and Native Bindings (hashed by identity)
    ## -------------------------------------------------------------------------

    method Opaque ($env) {
        state $nonce = 0;
        my $uid = ++$nonce; # unique object identity
        $arena->allocate(MXCL::Term::Opaque::, env => $env, uid => $uid );
    }

    method NativeApplicative ($params, $body) {
        # the body refaddr is used for identity
        $arena->allocate(MXCL::Term::Native::Applicative::, params => $params, body => $body )
    }

    method NativeOperative ($params, $body) {
        # the body refaddr is used for identity
        $arena->allocate(MXCL::Term::Native::Operative::, params => $params, body => $body )
    }

    ## -------------------------------------------------------------------------
    ## List Utils
    ## -------------------------------------------------------------------------

    method List (@items) {
        my $list = $nil;
        foreach my $item (reverse @items) {
            $list = $self->Cons( $item, $list );
        }
        return $list;
    }

    method Uncons ($list) {
        my @items;
        until ($list isa MXCL::Term::Nil) {
            push @items => $list->head;
            $list = $list->tail;
        }
        return @items;
    }

    method Append ($first, $second) {
        $self->List( $self->Uncons($first), $self->Uncons($second) )
    }

}
