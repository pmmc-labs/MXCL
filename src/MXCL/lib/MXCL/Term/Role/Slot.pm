
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Role::Slot :isa(MXCL::Term) {
    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Role\:\://r }
    method stringify { $self->type }
    method pprint { $self->type }
}

class MXCL::Term::Role::Slot::Defined :isa(MXCL::Term::Role::Slot) {
    field $ident :param :reader;
    field $value :param :reader;

    method pprint { sprintf 'defined:(%s, %s)' => $ident->pprint, $value->pprint }
}

class MXCL::Term::Role::Slot::Required :isa(MXCL::Term::Role::Slot) {
    field $ident :param :reader;

    method pprint { sprintf 'required:(%s)' => $ident->pprint }
}

class MXCL::Term::Role::Slot::Conflict :isa(MXCL::Term::Role::Slot) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    ADJUST {
        $lhs->ident->eq($rhs->ident)
            || die 'Conflicted ident must be equal';
    }

    method ident { $lhs->ident }

    method pprint {
        sprintf 'conflicted:(%s ~ %s)' => $lhs->pprint, $rhs->pprint
    }
}
