
use v5.42;
use experimental qw[ class switch ];

use MXCL::Debugger;

class MXCL::Machine {
    field $context :param :reader;

    field $steps :reader = 0;
    field $queue :reader = +[];
    field $trace :reader = +[];
    field $debug :reader = undef;

    ADJUST {
        $debug = MXCL::Debugger->new( machine => $self );
    }

    method run ($env, $exprs) {
        push @$queue => (
            $context->kontinues->Host($env, 'HALT', +{}, $context->terms->Nil),
            reverse map $context->kontinues->EvalExpr($env, $_, $context->terms->Nil), @$exprs
        );
        return $self->run_until_host;
    }

    method run_until_host {
        my $k;
        while (@$queue) {
            $k = pop @$queue;
            last if $k isa MXCL::Term::Kontinue::Host;
            push @$queue => $self->step($k);
            push @$trace => $k;
        }
        $debug->DEBUG_STEP($k, true);
        return $k;
    }

    method step ($k) {
        $steps++;
        $debug->DEBUG_STEP( $k );
        given (blessed $k) {
            # ------------------------------------------------------------------
            # Threading of Env & Stack
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Return') {
                # NOTE:
                # can mutate Env and Stack of previous K
                # unless previous K is a Return, in which
                # case it will preserve the Env of the
                # previous K rather than overrite it
                my $prev = pop @$queue;
                return $context->kontinues->Update(
                    $prev,
                    $k->env,
                    $context->terms->Append( $prev->stack, $k->stack )
                );
            }
            when ('MXCL::Term::Kontinue::Define') {
                my $name   = $k->name->value;
                my $lambda = $k->stack->head;

                my $local = $context->traits->Compose(
                    # FIXME - this naming is horrible
                    $context->terms->Sym("Scope[".$k->env->name->stringify." + declare:${name}]"),
                    $k->env,
                    $context->traits->Trait(
                        # FIXME - this naming is either worse, or better, hmmm
                        $context->terms->Sym($name),
                        $name, $context->traits->Defined( $lambda )
                    )
                );

                return $context->kontinues->Return(
                    $local,
                    $context->terms->Nil,
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
                    my @params = $context->terms->Uncons($call->params);
                    my @args   = $context->terms->Uncons($args);
                    die "Arity mismatch" if scalar @params != scalar @args;

                    my $args_string = sprintf '(%s)' => join ', ' => map $_->value, @params;

                    my $local = $context->traits->Compose(
                        $context->terms->Sym("Scope[Lambda + args:${args_string}]"),
                        $call->env,
                        $context->traits->Trait(
                            $context->terms->Sym($args_string),
                            # Define a recursive self call ...
                            $call->name, $context->traits->Defined($call),
                            # include the params ...
                            map {
                                $_->value,
                                $context->traits->Defined(shift @args)
                            } @params,
                        )
                    );

                    return (
                        $context->kontinues->Return( $k->env, $context->terms->Nil ),
                        $context->kontinues->EvalExpr(
                            $local,
                            $call->body,
                            $context->terms->Nil
                        )
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
