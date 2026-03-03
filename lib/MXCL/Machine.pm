
use v5.42;
use experimental qw[ class switch ];

class MXCL::Machine {

    method run ($context) {
        return $self->run_until_host($context);
    }

    method run_until_host ($context) {
        my $k;
        while ($context->tape->has_next) {
            $k = $context->tape->next;
            last if $k isa MXCL::Term::Kontinue::Host;
            $context->tape->advance( $context, $k, $self->step( $context, $k ) );
        }
        return $k;
    }

    method step ($context, $k) {
        state $Terms = $context->terms;
        state $Konts = $context->kontinues;
        state $Roles = $context->roles;
        state $Nil   = $Terms->Nil;

        given (blessed $k) {
            # ------------------------------------------------------------------
            # Threading of Env & Stack
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Return') {
                die "EXPECTED KONTINUE IN QUEUE for Return!"
                    unless $context->tape->has_next;

                my $prev = $context->tape->next;
                return $Konts->Update(
                    $prev,
                    $k->env,
                    $Terms->Append( $prev->stack, $k->stack )
                );
            }
            when ('MXCL::Term::Kontinue::Discard') {
                die "EXPECTED KONTINUE IN QUEUE for Discard!"
                    unless $context->tape->has_next;

                my $prev = $context->tape->next;
                return $Konts->Update( $prev, $k->env, $prev->stack );
            }
            when ('MXCL::Term::Kontinue::Capture') {
                die "EXPECTED KONTINUE IN QUEUE for Capture!"
                    unless $context->tape->has_next;

                my $prev = $context->tape->next;
                return $Konts->Update(
                    $prev,
                    $k->env,
                    $Terms->Append(
                        $prev->stack,
                        $Terms->List( $Roles->Difference( $k->env, $k->origin ) )
                    )
                );
            }
            when ('MXCL::Term::Kontinue::Define') {
                my $name  = $k->name;
                my $value = $k->stack->head;

                my $slot  = $value isa MXCL::Term::Role::Slot
                    ? $value
                    : $Roles->Defined( $name, $value );

                my $local = $Roles->Union( $k->env, $Roles->Role( $slot ) );

                $context->enter_scope($local);

                # TODO
                # - need to check if we have any conflicts
                #   here, and decide what to do with them
                #   this is going to need some thinking

                return $Konts->Return( $local, $Nil );
            }
            # ------------------------------------------------------------------
            # Enter/Leave Scopes
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Scope::Enter') {
                $context->enter_scope( $k->env );
                # TODO
                # - set up the `defer` function in the Env
                return ();
            }
            when ('MXCL::Term::Kontinue::Scope::Leave') {
                # XXX:
                # this should work, but could have issues
                # so be on the lookout for them :)
                until ($context->current_scope->hash eq $k->env->hash) {
                    $context->leave_scope;
                }
                # NOTE:
                # this will restore the env, but in a kinda
                # janky way inside the Update function of the
                # Kontinues allocator.
                return $Konts->Return( $k->env, $k->stack );
            }
            # ------------------------------------------------------------------
            # Control Structures
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::IfElse') {
                my $condition = $k->stack->head;
                if (not($condition isa MXCL::Term::Nil) && $condition->value) {
                    return # AND short/circuit
                        refaddr $k->condition == refaddr $k->if_true
                            ? $Konts->Return( $k->env, $Terms->List( $condition ) )
                            : $self->evaluate_term( $context, $k->env, $k->if_true  );
                } else {
                    return # OR short/circuit
                        refaddr $k->condition == refaddr $k->if_false
                            ? $Konts->Return( $k->env, $Terms->List( $condition ) )
                            : $self->evaluate_term( $context, $k->env, $k->if_false );
                }
            }
            when ('MXCL::Term::Kontinue::DoWhile') {
                my $condition = $k->stack->head;
                if ($condition->value) {
                    return (
                        $Konts->DoWhile( $k->env, $k->condition, $k->body, $Nil ),
                        $Konts->EvalExpr( $k->env, $k->condition, $Nil ),
                        $Konts->EvalExpr( $k->env, $k->body, $Nil ),
                    );
                } else {
                    return (
                        $Konts->Return( $k->env, $Nil )
                    );
                }
            }
            # ------------------------------------------------------------------
            # Eval
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Eval::TOS') {
                my $expr = $k->stack->head;
                return $self->evaluate_term( $context, $k->env, $expr );
            }
            when ('MXCL::Term::Kontinue::Eval::Expr') {
                return $self->evaluate_term( $context, $k->env, $k->expr );
            }
            when ('MXCL::Term::Kontinue::Eval::Head') {
                my $cons = $k->cons;
                my $env  = $k->env;

                return (
                    $Konts->ApplyExpr( $env, $cons->tail, $Nil ),
                    $self->evaluate_term( $context, $env, $cons->head ),
                );
            }
            when ('MXCL::Term::Kontinue::Eval::Rest') {
                my $rest = $k->rest;
                my $env  = $k->env;
                return (
                    ($rest->tail->isa('MXCL::Term::Nil')
                        ? $Konts->Return( $env, $k->stack )
                        : $Konts->EvalRest( $env, $rest->tail, $k->stack )),
                    $self->evaluate_term( $context, $env, $rest->head ),
                );
            }
            # ------------------------------------------------------------------
            # Appy
            # ------------------------------------------------------------------
            when ('MXCL::Term::Kontinue::Apply::Stack') {

                #say "STACK!!!!: ";
                #say $k->stack->pprint;
                #say "STACK!!!!: ";

                return (
                    $Konts->ApplyExpr( $k->env, $k->stack->tail, $Nil ),
                    $self->evaluate_term( $context, $k->env, $k->stack->head ),
                );
            }
            when ('MXCL::Term::Kontinue::Apply::Expr') {
                my $call = $k->stack->head;
                my $args = $k->args;
                my $env  = $k->env;

                if ($call isa MXCL::Term::Native::Applicative || $call isa MXCL::Term::Lambda) {
                    return (
                        $Konts->ApplyApplicative( $env, $call, $Nil ),
                        ($args isa MXCL::Term::Nil
                            ? ()
                            : $Konts->EvalRest( $env, $args, $Nil ))
                    );
                }
                elsif ($call isa MXCL::Term::Native::Operative
                    || $call isa MXCL::Term::FExpr
                    || $call isa MXCL::Term::Opaque) {
                    return $Konts->ApplyOperative( $env, $call, $args );
                }
                else {
                    # FIXME: this is gross!!!
                    my $inv_type = $call isa MXCL::Term::Kontinue
                                        ? 'Kontinue'
                                        : $call->type;

                    my $autobox  = $env->lookup($inv_type);

                    # FIXME: this is gross!!!!
                    unless (defined $autobox) {
                        $autobox = $context->base_scope->lookup($inv_type);
                    }

                    unless ($autobox isa MXCL::Term::Role::Slot::Defined) {
                        die "Could not find role to autobox ${inv_type}";
                    }

                    my $role = $autobox->value;
                    my $name = $args->head; # should be Sym
                    my $slot = $role->lookup( $name->value );

                    die "Bad Slot! ".($slot ? $slot->pprint : 'Absent')." for ".(join '/' => $inv_type, $name->value)." in ".$role->pprint
                        unless $slot isa MXCL::Term::Role::Slot::Defined;

                    my $method = $slot->value;
                    return $Konts->ApplyExpr(
                        $k->env, $Terms->Cons( $call, $args->tail ), $Terms->List( $method )
                    );
                }
            }
            when ('MXCL::Term::Kontinue::Apply::Applicative') {
                my $call = $k->call;
                my $args = $k->stack;
                if ($call isa MXCL::Term::Native::Applicative) {
                    my $result = $call->body->( $Terms->Uncons( $args ) );
                    return $Konts->Return( $k->env, $Terms->List( $result ) );
                }
                elsif ($call isa MXCL::Term::Lambda) {
                    my @params = $Terms->Uncons($call->params);
                    my @args   = $Terms->Uncons($args);

                    die "Arity mismatch in ",$call->name->stringify
                        if scalar @params != scalar @args;

                    my $local = $Roles->Union(
                        $call->env,
                        $Roles->Role(
                            # Define a recursive self call ...
                            $Roles->Defined($call->name, $call),
                            # include the params ...
                            map {
                                $Roles->Defined($_, shift @args)
                            } @params,
                            # TODO: set up a local `return` function
                        )
                    );

                    return $Konts->Scope( $local, $k->env, $Nil )->wrap(
                        $Konts->EvalExpr(
                            $local,
                            $call->body,
                            $Nil
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
                    return $call->body->( $k->env, $Terms->Uncons( $args ) );
                }
                elsif ($call isa MXCL::Term::FExpr) {
                    my @params = $Terms->Uncons($call->params);
                    my @args   = ($k->env, $Terms->Uncons($args));

                    die "Arity mismatch in ",$call->name->stringify
                        if scalar @params != scalar @args;

                    my $local = $Roles->Union(
                        $call->env,
                        $Roles->Role(
                            # Define a recursive self call ...
                            $Roles->Defined($call->name, $call),
                            # include the params ...
                            map {
                                $Roles->Defined($_, shift @args)
                            } @params,
                            # TODO: set up a local `return` function
                        )
                    );

                    return $Konts->Scope( $local, $k->env, $Nil )->wrap(
                        $Konts->EvalExpr(
                            $local,
                            $call->body,
                            $Nil
                        )
                    );
                }
                elsif ($call isa MXCL::Term::Opaque) {
                    my $name = $args->head; # should be Sym
                    my $slot = $call->role->lookup( $name->value );

                    die "Bad Slot! ".$slot->stringify
                        unless $slot isa MXCL::Term::Role::Slot::Defined;

                    my $method = $slot->value;
                    return $Konts->ApplyExpr(
                        $k->env, $Terms->Cons( $call, $args->tail ), $context->terms->List( $method )
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

    method evaluate_term ($context, $env, $expr) {
        state $Terms = $context->terms;
        state $Konts = $context->kontinues;
        state $Roles = $context->roles;
        state $Nil   = $Terms->Nil;

        given (blessed $expr) {
            when ('MXCL::Term::Sym') {
                my $value = $env->lookup( $expr->value );

                # NOTE:
                # this works for here, but we really should
                # check things more carefully in Define.
                while ($value isa MXCL::Term::Role::Slot::Conflict) {
                    $value = $value->rhs;
                }

                die "Could not find ".$expr->value." in Env ".$env->hash." ... ".$Roles->Difference($env, $context->base_scope)->stringify
                    unless $value isa MXCL::Term::Role::Slot::Defined;

                return $Konts->Return( $env, $Terms->List( $value->value ) );
            }
            when ('MXCL::Term::Cons') {
                return $Konts->EvalHead( $env, $expr, $Nil );
            }
            default {
                return $Konts->Return( $env, $Terms->List( $expr ) );
            }
        }
    }

}
