
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Operative :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method to_string { 'native:operative' }
}
