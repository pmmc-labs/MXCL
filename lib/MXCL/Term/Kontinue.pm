
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue :isa(MXCL::Term) {
    field $stack :param :reader;
    field $env   :param :reader;

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r }

    method stringify {
        sprintf 'Kontinue[%s] %s => %s <%s>' =>
            $self->type,
            $stack->stringify,
            $self->env->hash;
    }

    method pprint {
        sprintf 'Kontinue[%s] %s => %s <%s>' =>
            $self->type,
            (
                ($self->isa('MXCL::Term::Kontinue::Eval::Expr') ?
                    ($self->expr->pprint) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Head') ?
                    ($self->cons->head->pprint) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Rest') ?
                    ($self->rest->pprint) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Expr') ?
                    ($self->args->pprint) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Applicative') ||
                 $self->isa('MXCL::Term::Kontinue::Apply::Operative') ?
                    ($self->call->pprint) :
                $self->isa('MXCL::Term::Kontinue::Define') ?
                    ($self->name->pprint) :
                '#')))))
            ),
            $stack->pprint,
            substr($self->env->hash, 0, 8);
    }
}
