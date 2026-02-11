
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue :isa(MXCL::Term) {
    field $stack :param :reader;
    field $env   :param :reader;

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r }

    method stringify {
        sprintf 'Kontinue[%s] %s => %s' =>
            (blessed $self) =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r,
            (
                ($self->isa('MXCL::Term::Kontinue::Eval::Expr') ?
                    ($self->expr->stringify) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Head') ?
                    ($self->cons->stringify) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Rest') ?
                    ($self->rest->stringify) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Expr') ?
                    ($self->args->stringify) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Applicative') ||
                 $self->isa('MXCL::Term::Kontinue::Apply::Operative') ?
                    ($self->call->stringify) :
                '')))))
            ),
            $stack->stringify;
    }

    #method pprint { die 'Cannot pprint a Kontinue' }
}
