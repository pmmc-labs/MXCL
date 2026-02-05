
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Lambda :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;
}
