
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Capture :isa(MXCL::Term::Kontinue) {
    field $origin :param :reader;
}
