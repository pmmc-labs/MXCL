
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Return :isa(MXCL::Term::Kontinue) {
    field $value :param :reader;

    method to_string {
        sprintf 'Kontinue[ %s ] %s = %s' => 'Return', $value->to_string, $self->stack->to_string;
    }
}
