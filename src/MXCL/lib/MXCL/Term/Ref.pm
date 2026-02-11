
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Ref :isa(MXCL::Term) {
    field $uid :param :reader;

    method to_string {
        sprintf 'ref<%s>' => $uid;
    }

    method pprint { die 'Cannot pprint a Ref' }
}
