
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Ref :isa(MXCL::Term) {
    field $uid :param :reader;

    method stringify { sprintf 'ref<%s>' => $uid }
    method boolify { true }

    method pprint { die 'Cannot pprint a Ref' }
}
