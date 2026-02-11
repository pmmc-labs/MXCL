
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Applicative :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method stringify { 'native:applicative' }

    method pprint { die 'Cannot pprint a Native::Applicative' }
}
