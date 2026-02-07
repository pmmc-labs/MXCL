
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Str :isa(MXCL::Term) {
    field $value :param :reader;

    method to_string { sprintf '"%s"' => $value }
}
