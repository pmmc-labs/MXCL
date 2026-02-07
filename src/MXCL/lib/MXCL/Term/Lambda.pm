
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Lambda :isa(MXCL::Term) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method to_string {
        sprintf '(lambda %s %s)' => $params->to_string, $body->to_string
    }
}
