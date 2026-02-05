
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Tag :isa(MXCL::Term) {
    field $value :param :reader;
}
