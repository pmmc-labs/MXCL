
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Applicative :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method to_string { 'native:applicative' }
}
