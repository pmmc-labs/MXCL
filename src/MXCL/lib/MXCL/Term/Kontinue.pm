
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue :isa(MXCL::Term) {
    field $stack :param :reader;
    field $env   :param :reader;

    method to_string {
        sprintf 'Kontinue(%s) = %s' => blessed $self, $stack->to_string;
    }
}
