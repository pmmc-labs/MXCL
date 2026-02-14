
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Trait::Slot :isa(MXCL::Term) {
    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Trait\:\://r }
    method stringify { $self->type }
    method pprint { $self->type }
}

class MXCL::Term::Trait::Slot::Absent   :isa(MXCL::Term::Trait::Slot) {}
class MXCL::Term::Trait::Slot::Required :isa(MXCL::Term::Trait::Slot) {}
class MXCL::Term::Trait::Slot::Excluded :isa(MXCL::Term::Trait::Slot) {}

class MXCL::Term::Trait::Slot::Defined :isa(MXCL::Term::Trait::Slot) {
    field $term :param :reader;

    method pprint {
        sprintf '%s[%s]' => $self->type, $term->pprint
    }
}

class MXCL::Term::Trait::Slot::Conflict :isa(MXCL::Term::Trait::Slot) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method pprint {
        sprintf '%s[%s]' => $self->type, (join ' !! ' => $lhs->pprint, $rhs->pprint)
    }
}

class MXCL::Term::Trait::Slot::Alias :isa(MXCL::Term::Trait::Slot) {
    field $symbol :param :reader;
    field $term   :param :reader;

    method pprint {
        sprintf '%s[%s]' => $self->type, (join ' => ' => $symbol->pprint, $term->pprint)
    }
}
