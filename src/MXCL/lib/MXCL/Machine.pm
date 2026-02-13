
use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use experimental qw[ class switch ];

use P5::TUI::Table;

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
        my $k;
        while (@$queue) {
            $k = pop @$queue;
            last if $k isa MXCL::Term::Kontinue::Host;
            push @$queue => $self->step($k);
            push @$trace => $k;
        }
        $self->DEBUG_STEP($k, true);
        return $k;
    }

    method DEBUG_STEP ($k, $final=false) {
        my @rows = map {
            [
                $_,
                $k->env->bindings->{$_}->stringify
            ]
        } sort { $a cmp $b }
          keys $k->env->bindings->%*;

        my $env_table = P5::TUI::Table->new(
            column_spec => [
                {
                    name  => $k->env->hash,
                    width => 32,
                    align => -1,     # right-aligned
                    color => { fg => 'cyan', bg => undef }
                },
                {
                    name  => $k->env->name->stringify,
                    width => '100%',  # Percentage of available space
                    align => 1,      # Left-aligned
                    color => { fg => 'white', bg => undef }
                },
            ],
            rows => \@rows
        );

        my $lines = $env_table->draw( width => '80%', height => (2 * scalar @rows) );

        say '-' x 120;
        if ($final) {
            say sprintf "DONE[%03d]" => $steps;
        } else {
            say sprintf "STEP[%03d]" => $steps;
        }
        say " -> ", $k->pprint;
        if (@$queue) {
            say "  - ", join "\n  - " => map blessed $_ ? $_->pprint : $_, reverse @$queue;
        }
        say for $lines->@*;
    }

    method step ($k) {
        $steps++;
        $self->DEBUG_STEP($k);
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
                my $value = $k->stack->head;
                my $name  = $k->name->value;
                my $local = $context->traits->Compose(
                    # FIXME - this naming is horrible
                    $context->terms->Sym("Scope[Parent]"),
                    $k->env,
                    $context->traits->Trait(
                        # FIXME - this naming is either worse, or better, hmmm
                        $context->terms->Sym("Scope[declare:${name}]"),
                        $name,
                        $context->traits->Defined( $value )
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

                    my $local = $context->traits->Compose(
                        $context->terms->Sym('Scope[Lambda]'),
                        $call->env,
                        $context->traits->Trait(
                            $context->terms->Sym(
                                sprintf 'Scope[%s]' =>
                                    join ', ' => map {
                                        sprintf 'arg:%s' => $_->value
                                    } @params
                            ),
                            map {
                                $_->value,
                                $context->traits->Defined(shift @args)
                            } @params
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
