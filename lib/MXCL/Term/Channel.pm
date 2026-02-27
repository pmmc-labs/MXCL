
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Channel :isa(MXCL::Term) {
    field $uid      :param :reader;
    field $__buffer :reader(buffer) = +[];

    method read          { pop @$__buffer }
    method write ($data) { unshift @$__buffer => $data }

    method stringify { sprintf 'Channel<%s>' => $uid }
    method boolify { true }

    method DECOMPOSE { (uid => $uid, __buffer => $__buffer) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{uid}))
    }
}
