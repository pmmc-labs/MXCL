
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Opaque :isa(MXCL::Term) {
    field $uid :param :reader;
    field $env :param :reader;

    method to_string {
        sprintf 'opaque<%s>(%s)' => $uid, $env->hash;
    }
}
