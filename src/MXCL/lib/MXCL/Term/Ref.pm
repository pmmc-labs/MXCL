
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Ref :isa(MXCL::Term) {
    field $uid :param :reader;

    method stringify { sprintf '<%s>' => $uid }
    method boolify { true }
}
