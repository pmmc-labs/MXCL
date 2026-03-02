
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::TapeRef :isa(MXCL::Term) {
    field $uid    :param :reader;
    field $__tape :param :reader(tape);

    method stringify {
        sprintf '<%s>' => $uid;
    }

    method pprint {
        sprintf '<%s>' => $uid;
    }

    method DECOMPOSE { (uid => $uid) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ uid ]}))
    }
}
