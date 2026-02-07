
use v5.42;
use experimental qw[ class ];

use MXCL::Term::Kontinue::Context::Leave;

class MXCL::Term::Kontinue::Context::Enter :isa(MXCL::Term::Kontinue) {
    field $leave :reader;

    ADJUST {
        $leave = MXCL::Term::Kontinue::Context::Leave->new(
            env => $self->env
        );
    }

    method wrap (@kontinuations) {
        return ($leave, @kontinuations, $self)
    }
}
