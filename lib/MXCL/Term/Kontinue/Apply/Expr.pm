
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::Apply::Expr :isa(MXCL::Term::Kontinue) {
    field $args :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), args => $args) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ args env stack ]}))
    }
}
