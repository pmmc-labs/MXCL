
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Apply::Expr :isa(MXCL::Term::Kontinue) {
    field $args :param :reader;
}
