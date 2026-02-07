
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Eval::Expr :isa(MXCL::Term::Kontinue) {
    field $expr :param :reader;
}
