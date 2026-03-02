
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Role::Slot :isa(MXCL::Term) {
    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Role\:\://r }
    method stringify { $self->type }
    method pprint { $self->type }

    method kind {
        #my ($kind) = ($self->type =~ /^Slot\:\:(.)/);
        return lc substr($self->type, 6, 1);
    }

    method DECOMPOSE { () }

    sub COMPOSE ($class, %args) {
        return (hash => MXCL::Internals::hash_fields($class))
    }
}

class MXCL::Term::Role::Slot::Defined :isa(MXCL::Term::Role::Slot) {
    field $ident :param :reader;
    field $value :param :reader;

    method pprint { sprintf 'defined:(%s, %s)' => $ident->pprint, $value->pprint }

    method DECOMPOSE { (ident => $ident, value => $value) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ ident value ]}))
    }
}

class MXCL::Term::Role::Slot::Required :isa(MXCL::Term::Role::Slot) {
    field $ident :param :reader;

    method pprint { sprintf 'required:(%s)' => $ident->pprint }

    method DECOMPOSE { (ident => $ident) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{ident}))
    }
}

class MXCL::Term::Role::Slot::Conflict :isa(MXCL::Term::Role::Slot) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    ADJUST {
        $lhs->ident->eq($rhs->ident)
            || die 'Conflicted ident must be equal';
    }

    method ident {
        $rhs->ident
    }

    method pprint {
        sprintf 'conflicted:(%s ~ %s)' => $lhs->pprint, $rhs->pprint
    }

    method DECOMPOSE { (lhs => $lhs, rhs => $rhs) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ lhs rhs ]}))
    }
}
