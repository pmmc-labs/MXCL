
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Throw :isa(MXCL::Term::Kontinue) {
    field $exception :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), exception => $exception) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env exception stack ]}))
    }
}
