
use v5.42;
use experimental qw[ class ];

use MXCL::Term::Kontinue::Scope::Leave;

class MXCL::Term::Kontinue::Scope::Enter :isa(MXCL::Term::Kontinue) {
    field $leave :param :reader;

    method wrap (@kontinuations) {
        return ($leave, @kontinuations, $self)
    }
}
