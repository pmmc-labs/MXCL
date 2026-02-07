
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::IfElse :isa(MXCL::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;
}
