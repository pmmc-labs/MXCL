
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Num :isa(MXCL::Term) {
    field $value :param :reader;

    method stringify { "${value}" }
    method numify { $value }
}
