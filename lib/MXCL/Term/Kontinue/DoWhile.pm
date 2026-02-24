
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::DoWhile :isa(MXCL::Term::Kontinue) {
    field $condition :param :reader;
    field $body      :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), body => $body, condition => $condition) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ body condition env stack ]}))
    }
}
