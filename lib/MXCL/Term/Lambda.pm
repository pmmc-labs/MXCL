
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Lambda :isa(MXCL::Term) {
    field $name   :param :reader;
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method stringify {
        sprintf '(/lambda [%s] %s %s)' => $name->stringify, $params->stringify, $body->stringify
    }

    method pprint {
        sprintf '(lambda %s %s)' => $params->pprint, $body->pprint
    }
}
