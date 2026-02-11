
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue :isa(MXCL::Term) {
    field $stack :param :reader;
    field $env   :param :reader;

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r }

    method to_string {
        sprintf 'Kontinue[%s] %s => %s' =>
            (blessed $self) =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r,
            (
                ($self->isa('MXCL::Term::Kontinue::Eval::Expr') ?
                    ($self->expr->to_string) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Head') ?
                    ($self->cons->to_string) :
                ($self->isa('MXCL::Term::Kontinue::Eval::Rest') ?
                    ($self->rest->to_string) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Expr') ?
                    ($self->args->to_string) :
                ($self->isa('MXCL::Term::Kontinue::Apply::Applicative') ||
                 $self->isa('MXCL::Term::Kontinue::Apply::Operative') ?
                    ($self->call->to_string) :
                '')))))
            ),
            $stack->to_string;
    }
}
