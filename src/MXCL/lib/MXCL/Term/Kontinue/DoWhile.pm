
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::DoWhile :isa(MXCL::Term::Kontinue) {
    field $condition :param :reader;
    field $body      :param :reader;
}
