
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

use Carp ();

class MXCL::Term::ContextRef :isa(MXCL::Term) {
    field $uid       :param :reader;
    field $__context :param :reader(context);

    method stringify {
        sprintf 'ctx<%s>' => $uid;
    }

    method pprint {
        sprintf 'ctx<%s>' => $uid;
    }

    method DECOMPOSE { (uid => $uid) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ uid ]}))
    }
}
