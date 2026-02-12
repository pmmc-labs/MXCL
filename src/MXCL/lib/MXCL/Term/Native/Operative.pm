
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Operative :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method stringify { 'native:operative' }

    method pprint { die 'Cannot pprint a Native::Operative' }

    # TODO:
    # this class needs a $name parameter for two reasons:
    # - it helps identify what it is in a trace
    # - it can print the name in the pprint function
    #   which should still make the pprint valid
}
