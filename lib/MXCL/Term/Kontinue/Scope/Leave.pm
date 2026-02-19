
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Scope::Leave :isa(MXCL::Term::Kontinue) {
    field $__deferred :param :reader(deferred) = +[];

    method has_deferred { scalar @$__deferred > 0 }

    method defer ($callback) {
        push @$__deferred => $callback;
        return;
    }
}
