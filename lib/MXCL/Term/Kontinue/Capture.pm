
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Capture :isa(MXCL::Term::Kontinue) {
    field $origin :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), origin => $origin) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env origin stack ]}))
    }
}
