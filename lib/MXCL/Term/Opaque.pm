
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

use Carp ();

class MXCL::Term::Opaque :isa(MXCL::Term) {
    field $uid  :param :reader;
    field $repr :param :reader;
    field $role :param :reader;

    ADJUST {
        $role isa MXCL::Term::Role || Carp::confess("WHOAT!");
    }

    method stringify {
        sprintf 'opaque<%s>[%s](%s)' => $uid, $repr->stringify, $role->hash;
    }

    method pprint {
        sprintf 'opaque<%s>[%s]:%s' => $uid, $repr->pprint, $role->pprint;
    }

    method DECOMPOSE { (repr => $repr, role => $role, uid => $uid) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ repr role uid ]}))
    }
}
