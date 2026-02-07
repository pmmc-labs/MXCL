
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Throw :isa(MXCL::Term::Kontinue) {
    field $exception :param :reader;
}
