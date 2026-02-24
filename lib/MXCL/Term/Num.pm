
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Num :isa(MXCL::Term) {
    field $value :param :reader;

    method stringify { "${value}" }
    method numify { $value }
    method boolify { $value != 0 }

    method DECOMPOSE { (value => $value) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{value}))
    }
}
