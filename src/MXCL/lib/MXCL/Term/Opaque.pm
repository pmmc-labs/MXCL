
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Opaque :isa(MXCL::Term) {
    field $env :param :reader;

    method to_string { 'opaque' }
}
