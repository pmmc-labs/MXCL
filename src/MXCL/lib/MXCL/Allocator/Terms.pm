
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

    method Num ($value) { $arena->allocate(MXCL::Term::Num::, value => $value) }
    method Str ($value) { $arena->allocate(MXCL::Term::Str::, value => $value) }
    method Sym ($value) { $arena->allocate(MXCL::Term::Sym::, value => $value) }
    method Tag ($value) { $arena->allocate(MXCL::Term::Tag::, value => $value) }

    method Cons ($head, $tail) {
        $arena->allocate(MXCL::Term::Cons::, head => $head, tail => $tail )
    }

    method List (@items) {
        my $list = $nil;
        foreach my $item (reverse @items) {
            $list = $self->Cons( $item, $list );
        }
        return $list;
    }

    method Env (%bindings) {
        $arena->allocate(MXCL::Term::Env::, bindings => \%bindings )
    }

    method Lambda ($params, $body, $env) {
        $arena->allocate(MXCL::Term::Lambda::, params => $params, body => $body, env => $env )
    }

    method Opaque ($env) {
        $arena->allocate(MXCL::Term::Opaque::, env  => $env )
    }

    method NativeApplicative ($params, $body) {
        $arena->allocate(MXCL::Term::Native::Applicative::, params => $params, body => $body )
    }

    method NativeOperative ($params, $body) {
        $arena->allocate(MXCL::Term::Native::Operative::, params => $params, body => $body )
    }
}
