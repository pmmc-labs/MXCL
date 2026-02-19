
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Opaque :isa(MXCL::Term) {
    field $uid :param :reader;
    field $env :param :reader;

    method stringify {
        sprintf 'opaque<%s>(%s)' => $uid, $env->hash;
    }

    method pprint {
        sprintf 'opaque[%s]:%s' => $uid, $env;
    }
}
