
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Opaque :isa(MXCL::Term) {
    field $uid  :param :reader;
    field $repr :param :reader;
    field $role :param :reader;

    method stringify {
        sprintf 'opaque<%s>[%s](%s)' => $uid, $repr->stringify, $role->hash;
    }

    method pprint {
        sprintf 'opaque<%s>[%s]:%s' => $uid, $repr->pprint, $role->pprint;
    }

    method DECOMPOSE { (repr => $repr, role => $role, uid => $uid) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ repr role uid ]}))
    }
}
