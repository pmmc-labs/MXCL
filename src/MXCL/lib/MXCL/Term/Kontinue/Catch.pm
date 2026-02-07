
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Catch :isa(MXCL::Term::Kontinue) {
    field $handler :param :reader;
}
