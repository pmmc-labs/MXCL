
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Context::Leave :isa(MXCL::Term::Kontinue) {
    field $deferred :reader = +[];

    method has_deferred { scalar @$deferred > 0 }

    method defer ($callback) {
        push @$deferred => $callback;
        return;
    }
}
