
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Define :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;
}
