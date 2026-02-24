
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Eval::Expr :isa(MXCL::Term::Kontinue) {
    field $expr :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), expr => $expr) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env expr stack ]}))
    }
}
