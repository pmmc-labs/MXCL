
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Trait::Slot :isa(MXCL::Term) {
    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Trait\:\://r }
    method to_string { $self->type }
}

class MXCL::Term::Trait::Slot::Absent :isa(MXCL::Term::Trait::Slot) {
    method to_string { $self->type }
}

class MXCL::Term::Trait::Slot::Required :isa(MXCL::Term::Trait::Slot) {
    method to_string { $self->type }
}

class MXCL::Term::Trait::Slot::Excluded :isa(MXCL::Term::Trait::Slot) {
    method to_string { $self->type }
}

class MXCL::Term::Trait::Slot::Defined :isa(MXCL::Term::Trait::Slot) {
    field $term :param :reader;

    method to_string {
        sprintf '%s[%s]' => $self->type, $term->to_string
    }
}

class MXCL::Term::Trait::Slot::Conflict :isa(MXCL::Term::Trait::Slot) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method to_string {
        sprintf '%s[%s]' => $self->type, (join ' !! ' => $lhs->to_string, $rhs->to_string)
    }
}

class MXCL::Term::Trait::Slot::Alias :isa(MXCL::Term::Trait::Slot) {
    field $symbol :param :reader;
    field $term   :param :reader;

    method to_string {
        sprintf '%s[%s]' => $self->type, (join ' => ' => $symbol->to_string, $term->to_string)
    }
}
