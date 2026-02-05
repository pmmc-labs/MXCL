
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Cons :isa(MXCL::Term) {
    field $head :param :reader;
    field $tail :param :reader;
}
