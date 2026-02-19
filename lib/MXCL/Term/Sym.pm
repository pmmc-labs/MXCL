
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Sym :isa(MXCL::Term) {
    field $value :param :reader;

    method stringify { $value }
    method boolify { true }
}
