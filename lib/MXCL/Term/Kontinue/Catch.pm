
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Catch :isa(MXCL::Term::Kontinue) {
    field $handler :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), handler => $handler) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env handler stack ]}))
    }
}
