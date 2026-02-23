
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

use MXCL::Term::Kontinue::Scope::Leave;

class MXCL::Term::Kontinue::Scope::Enter :isa(MXCL::Term::Kontinue) {
    field $leave :param :reader;

    method wrap (@kontinuations) {
        return ($leave, @kontinuations, $self)
    }

    method DECOMPOSE { ($self->SUPER::DECOMPOSE(), leave => $leave) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ env leave stack ]}))
    }
}
