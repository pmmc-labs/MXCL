
use v5.42;
use experimental qw[ class switch ];

use MXCL::Internals;

class MXCL::Term::FExpr :isa(MXCL::Term) {
    field $name   :param :reader;
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method stringify {
        sprintf '(/fexpr [%s] %s %s)' => $name->stringify, $params->stringify, $body->stringify
    }

    method pprint {
        sprintf '(fexpr %s %s)' => $params->pprint, $body->pprint
    }

    method DECOMPOSE { (body => $body, env => $env, name => $name, params => $params) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ body env name params ]}))
    }
}
