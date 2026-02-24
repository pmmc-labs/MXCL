
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Apply::Applicative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), call => $call) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ call env stack ]}))
    }
}
