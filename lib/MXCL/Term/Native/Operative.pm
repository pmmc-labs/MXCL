
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Native::Operative :isa(MXCL::Term) {
    field $name    :param :reader;
    field $params  :param :reader;
    field $__body  :param :reader(body);

    method stringify {
        sprintf 'native:operative[%s](%s)' =>
            $name->stringify,
            join ', ' => map $_->stringify, $params->uncons
        ;
    }

    method DECOMPOSE { (name => $name, params => $params, __body => $__body) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ name params ]}))
    }
}
