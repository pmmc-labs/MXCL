
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Ref :isa(MXCL::Term) {
    field $uid :param :reader;

    method stringify { sprintf '<%s>' => $uid }
    method boolify { true }

    method DECOMPOSE { (uid => $uid) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{uid}))
    }
}
