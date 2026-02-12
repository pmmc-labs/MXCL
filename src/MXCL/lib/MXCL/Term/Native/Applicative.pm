
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Applicative :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;

    method stringify { 'native:applicative' }

    method pprint { die 'Cannot pprint a Native::Applicative' }

    # TODO:
    # this class needs a $name parameter for two reasons:
    # - it helps identify what it is in a trace
    # - it can print the name in the pprint function
    #   which should still make the pprint valid
}
