
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Bool :isa(MXCL::Term) {
    field $value :param :reader;

    method to_string { $value ? 'true' : 'false' }
}
