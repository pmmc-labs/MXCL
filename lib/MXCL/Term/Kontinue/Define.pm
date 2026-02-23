
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Define :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), name => $name) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env name stack ]}))
    }
}
