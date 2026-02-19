
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
use MXCL::Term::Sym;

use MXCL::Term::Array;
use MXCL::Term::Hash;

use MXCL::Term::Lambda;
use MXCL::Term::Opaque;

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

    method Lambda ($params, $body, $env, $name=undef) {
        $name //= $self->Sym('__SUB__');
        $arena->allocate(MXCL::Term::Lambda::, name => $name, params => $params, body => $body, env => $env )
    }

    method Array (@elements) {
        $arena->allocate(MXCL::Term::Array::, elements => \@elements )
    }

    method Hash (%elements) {
        $arena->allocate(MXCL::Term::Hash::, elements => \%elements )
    }

    ## -------------------------------------------------------------------------
    ## Opaques (hashed by identity)
    ## -------------------------------------------------------------------------

    method Opaque ($repr, $role) {
        state $nonce = 0;
        my $uid = ++$nonce; # unique object identity
        $arena->allocate(MXCL::Term::Opaque::,
            uid  => $uid,
            repr => $repr,
            role => $role,
        );
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
