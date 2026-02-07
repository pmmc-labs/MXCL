
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Nil :isa(MXCL::Term) {

    method to_string { '()' }
}
