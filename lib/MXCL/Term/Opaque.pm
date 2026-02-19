
use v5.42;
use experimental qw[ class ];

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
}
