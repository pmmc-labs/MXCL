
use v5.42;
use experimental qw[ class switch ];


class MXCL::Machine {
    field $context :param :reader;

    field $steps :reader = 0;
    field $queue :reader = +[];
    field $trace :reader = +[];

    method run ($env, $exprs) {
        push @$queue => (
            $context->kontinues->Host($env, 'HALT', +{}, $context->terms->Nil),
            reverse map $context->kontinues->EvalExpr($env, $_, $context->terms->Nil), @$exprs
        );
        return $self->run_until_host;
    }

    method run_until_host {
        say sprintf "STEP[%03d]" => $steps;
        while (@$queue) {
            say "  - ", join "\n  - " => map blessed $_ ? $_->stringify : $_, reverse @$queue;
            my $k = pop @$queue;
            return $k if $k isa MXCL::Term::Kontinue::Host;
            push @$queue => $self->step($k);
            push @$trace => $k;
        }
    }

    method step ($k) {
        $steps++;
        say sprintf "STEP[%03d]\n  ^%s" => $steps, $k->env->stringify;
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
                return $context->kontinues->Update(
                    $prev,
                    $k->env,
                    $context->terms->Append( $prev->stack, $k->stack )
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
                            ? $context->kontinues->Return( $k->env, $context->terms->List( $condition ) )
                            : $self->evaluate_term( $k->env, $k->if_true  );
                } else {
                    return # OR short/circuit
                        refaddr $k->condition == refaddr $k->if_false
                            ? $context->kontinues->Return( $k->env, $context->terms->List( $condition ) )
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
                    $context->kontinues->ApplyExpr( $env, $cons->tail, $context->terms->Nil ),
                    $self->evaluate_term( $env, $cons->head ),
                );
            }
            when ('MXCL::Term::Kontinue::Eval::Rest') {
                my $rest = $k->rest;
                my $env  = $k->env;
                return (
                    ($rest->tail->isa('MXCL::Term::Nil')
                        ? $context->kontinues->Return( $env, $k->stack )
                        : $context->kontinues->EvalRest( $env, $rest->tail, $k->stack )),
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
                        $context->kontinues->ApplyApplicative( $env, $call, $context->terms->Nil ),
                        ($args isa MXCL::Term::Nil
                            ? ()
                            : $context->kontinues->EvalRest( $env, $args, $context->terms->Nil ))
                    );
                }
                elsif ($call isa MXCL::Term::Native::Operative || $call isa MXCL::Term::Opaque) {
                    return $context->kontinues->ApplyOperative( $env, $call, $args );
                }
                else {
                    my $autobox = $env->lookup(blessed $call);

                    die "Could not find trait to autobox ".blessed $call
                        unless $autobox isa MXCL::Term::Trait::Slot::Defined;

                    my $trait = $autobox->term;
                    my $name  = $args->head; # should be Sym
                    my $slot  = $trait->lookup( $name->value );

                    die "Bad Slot! ".$slot->stringify
                        unless $slot isa MXCL::Term::Trait::Slot::Defined;

                    my $method = $slot->term;
                    return $context->kontinues->ApplyExpr(
                        $k->env, $context->terms->Cons( $call, $args->tail ), $context->terms->List( $method )
                    );
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Applicative') {
                my $call = $k->call;
                my $args = $k->stack;
                if ($call isa MXCL::Term::Native::Applicative) {
                    my $result = $call->body->( $context->terms->Uncons( $args ) );
                    return $context->kontinues->Return( $k->env, $context->terms->List( $result ) );
                }
                elsif ($call isa MXCL::Term::Lambda) {
                    return $context->kontinues->EvalExpr(
                        $context->traits->BindParams(
                            $call->env,
                            [ $context->terms->Uncons($call->params) ],
                            [ $context->terms->Uncons($args) ]
                        ),
                        $call->body,
                        $context->terms->Nil
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
                    return $call->body->( $k->env, $context->terms->Uncons( $args ) );
                }
                elsif ($call isa MXCL::Term::Opaque) {
                    my $name = $args->head; # should be Sym
                    my $slot = $call->env->lookup( $name->value );

                    die "Bad Slot! ".$slot->stringify
                        unless $slot isa MXCL::Term::Trait::Slot::Defined;

                    my $method = $slot->term;
                    return $context->kontinues->ApplyExpr(
                        $k->env, $context->terms->Cons( $call, $args->tail ), $context->terms->List( $method )
                    );
                }
                else {
                    die 'Unknown Operative type '.blessed $call;
                }
            }
            default {
                die "Unexpected Kontinue ".(blessed $k ? $k->stringify : ($k // 'undef'));
            }
        }
    }

    method evaluate_term ($env, $expr) {
        given (blessed $expr) {
            when ('MXCL::Term::Sym') {
                my $value = $env->lookup( $expr->value );
                die "Could not find ".$expr->value." in Env"
                    unless $value isa MXCL::Term::Trait::Slot::Defined;
                return $context->kontinues->Return( $env, $context->terms->List( $value->term ) );
            }
            when ('MXCL::Term::Cons') {
                return $context->kontinues->EvalHead( $env, $expr, $context->terms->Nil );
            }
            default {
                return $context->kontinues->Return( $env, $context->terms->List( $expr ) );
            }
        }
    }

}
