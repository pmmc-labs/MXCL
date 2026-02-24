
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Native::Applicative :isa(MXCL::Term) {
    field $name    :param :reader;
    field $params  :param :reader;
    field $__body  :param :reader(body);

    method stringify {
        sprintf 'native:applicative[%s](%s)' =>
            $name->stringify,
            join ', ' => map $_->stringify, $params->uncons
        ;
    }

    method DECOMPOSE { (name => $name, params => $params, __body => $__body) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ name params ]}))
    }
}
