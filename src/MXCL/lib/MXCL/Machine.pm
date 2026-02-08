
use v5.42;
use experimental qw[ class switch ];


class MXCL::Machine {
    field $terms     :param :reader;
    field $kontinues :param :reader;

    field $steps :reader = 0;
    field $queue :reader = +[];

    method run ($env, $exprs) {
        push @$queue => (
            $kontinues->Host($env, 'HALT', +{}, $terms->Nil),
            reverse map $kontinues->EvalExpr($env, $_, $terms->Nil), @$exprs
        );
        return $self->run_until_host;
    }

    method run_until_host {
        while (@$queue) {
            say "  - ", join "\n  - " => map $_->to_string, @$queue;
            my $k = pop @$queue;
            return $k if $k isa MXCL::Term::Kontinue::Host;
            push @$queue => $self->step($k);
        }
    }

    method step ($k) {
        $steps++;
        say sprintf 'STEP[%03d]' => $steps;
        given (blessed $k) {
            when ('MXCL::Term::Kontinue::Return') {
                # NOTE:
                # can mutate Env and Stack of previous K
                # TODO:
                # add a LeaveScope kont to un-mutate the Env
                my $prev = pop @$queue;
                return $kontinues->Update(
                    $prev,
                    $k->env,
                    $terms->Append( $prev->stack, $k->stack )
                );
            }
            when ('MXCL::Term::Kontinue::Eval::Expr') {
                return $self->evaluate_term( $k->env, $k->expr );
            }
            when ('MXCL::Term::Kontinue::Eval::Head') {
                my $cons = $k->cons;
                my $env  = $k->env;

                return (
                    $kontinues->ApplyExpr( $env, $cons->tail, $terms->Nil ),
                    $self->evaluate_term( $env, $cons->head ),
                );
            }
            when ('MXCL::Term::Kontinue::Eval::Rest') {
                my $rest = $k->rest;
                my $env  = $k->env;
                return (
                    ($rest->tail->isa('MXCL::Term::Nil')
                        ? $kontinues->Return( $env, $k->stack )
                        : $kontinues->EvalRest( $env, $rest->tail, $k->stack )),
                    $self->evaluate_term( $env, $rest->head ),
                );
            }
            when ('MXCL::Term::Kontinue::Apply::Expr') {
                my $call = $k->stack->head;
                my $args = $k->args;
                my $env  = $k->env;

                if ($call isa MXCL::Term::Native::Applicative) {
                    return (
                        $kontinues->ApplyApplicative( $env, $call, $terms->Nil ),
                        ($args isa MXCL::Term::Nil
                            ? ()
                            : $kontinues->EvalRest( $env, $args, $terms->Nil ))
                    );
                }
                else {
                    my $box    = $env->lookup(blessed $call);
                    my $name   = $args->head; # should be Sym
                    my $method = $box->env->lookup( $name->value );
                    return (
                        $kontinues->ApplyApplicative( $box->env, $method, $terms->List( $call ) ),
                        ($args->tail isa MXCL::Term::Nil
                            ? ()
                            : $kontinues->EvalRest( $env, $args->tail, $terms->Nil ))
                    )
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Applicative') {
                my $call = $k->call;
                my $args = $k->stack;
                if ($call isa MXCL::Term::Native::Applicative) {
                    my $result = $call->body->( $args->head, $args->tail->head );
                    return $kontinues->Return( $k->env, $terms->List( $result ) );
                } else {
                    die 'TODO - apply applicative for '.blessed $call;
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Operative') {
                die 'TODO - Operative';
            }
            default {
                die "Unexpected Kontinue ".$k->to_string;
            }
        }
    }

    method evaluate_term ($env, $expr) {
        given (blessed $expr) {
            when ('MXCL::Term::Sym') {
                my $value = $env->lookup( $expr->value );
                die "Could not find ".$expr->value." in Env"
                    unless defined $value;
                return $kontinues->Return( $env, $terms->List( $value ) );
            }
            when ('MXCL::Term::Cons') {
                return $kontinues->EvalHead( $env, $expr, $terms->Nil );
            }
            default {
                return $kontinues->Return( $env, $terms->List( $expr ) );
            }
        }
    }

}
