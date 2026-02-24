
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Eval::Rest :isa(MXCL::Term::Kontinue) {
    field $rest :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), rest => $rest) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env rest stack ]}))
    }
}
