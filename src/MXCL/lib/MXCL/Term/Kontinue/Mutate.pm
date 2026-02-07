
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Mutate :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;
}
