
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Kontinue::IfElse :isa(MXCL::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), condition => $condition, if_true => $if_true, if_false => $if_false) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ condition env if_false if_true stack ]}))
    }
}
