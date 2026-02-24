
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Sym :isa(MXCL::Term) {
    field $value :param :reader;

    method stringify { $value }
    method boolify { true }

    method DECOMPOSE { (value => $value) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{value}))
    }
}
