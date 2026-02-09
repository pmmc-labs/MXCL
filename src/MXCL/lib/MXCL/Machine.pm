
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
        say sprintf "STEP[%03d]" => $steps;
        while (@$queue) {
            say "  - ", join "\n  - " => map blessed $_ ? $_->to_string : $_, reverse @$queue;
            my $k = pop @$queue;
            return $k if $k isa MXCL::Term::Kontinue::Host;
            push @$queue => $self->step($k);
        }
    }

    method step ($k) {
        $steps++;
        say sprintf "STEP[%03d]\n  ^%s" => $steps, $k->env->to_string;
        given (blessed $k) {
            # ------------------------------------------------------------------
            # Threading of Env & Stack
            # ------------------------------------------------------------------
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
            # ------------------------------------------------------------------
            # Control Structures
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::IfElse') {
                my $condition = $k->stack->head;
                if ($condition->value) {
                    return # AND short/circuit
                        refaddr $k->condition == refaddr $k->if_true
                            ? $kontinues->Return( $k->env, $terms->List( $condition ) )
                            : $self->evaluate_term( $k->env, $k->if_true  );
                } else {
                    return # OR short/circuit
                        refaddr $k->condition == refaddr $k->if_false
                            ? $kontinues->Return( $k->env, $terms->List( $condition ) )
                            : $self->evaluate_term( $k->env, $k->if_false );
                }
            }
            # ------------------------------------------------------------------
            # Eval
            # ------------------------------------------------------------------
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
            # ------------------------------------------------------------------
            # Appy
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Apply::Expr') {
                my $call = $k->stack->head;
                my $args = $k->args;
                my $env  = $k->env;

                if ($call isa MXCL::Term::Native::Applicative || $call isa MXCL::Term::Lambda) {
                    return (
                        $kontinues->ApplyApplicative( $env, $call, $terms->Nil ),
                        ($args isa MXCL::Term::Nil
                            ? ()
                            : $kontinues->EvalRest( $env, $args, $terms->Nil ))
                    );
                }
                elsif ($call isa MXCL::Term::Native::Operative || $call isa MXCL::Term::Opaque) {
                    return $kontinues->ApplyOperative( $env, $call, $args );
                }
                else {
                    my $box    = $env->lookup(blessed $call);
                    my $name   = $args->head; # should be Sym
                    my $method = $box->env->lookup( $name->value );
                    return $kontinues->ApplyExpr(
                        $k->env, $terms->Cons( $call, $args->tail ), $terms->List( $method )
                    );
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Applicative') {
                my $call = $k->call;
                my $args = $k->stack;
                if ($call isa MXCL::Term::Native::Applicative) {
                    my $result = $call->body->( $terms->Uncons( $args ) );
                    return $kontinues->Return( $k->env, $terms->List( $result ) );
                }
                elsif ($call isa MXCL::Term::Lambda) {
                    return $kontinues->EvalExpr(
                        $terms->BindParams( $call->env, $call->params, $args ),
                        $call->body,
                        $terms->Nil
                    );
                }
                else {
                    die 'Unknown Applicative type '.blessed $call;
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Operative') {
                my $call = $k->call;
                my $args = $k->stack;
                if ($call isa MXCL::Term::Native::Operative) {
                    return $call->body->( $k->env, $terms->Uncons( $args ) );
                }
                elsif ($call isa MXCL::Term::Opaque) {
                    my $name   = $args->head; # should be Sym
                    my $method = $call->env->lookup( $name->value );
                    return $kontinues->ApplyExpr(
                        $k->env, $terms->Cons( $call, $args->tail ), $terms->List( $method )
                    );
                }
                else {
                    die 'Unknown Operative type '.blessed $call;
                }
            }
            default {
                die "Unexpected Kontinue ".(blessed $k ? $k->to_string : ($k // 'undef'));
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
