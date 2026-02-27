
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Kontinue::Host;

use MXCL::Term::Kontinue::Return;
use MXCL::Term::Kontinue::Discard;
use MXCL::Term::Kontinue::Capture;

use MXCL::Term::Kontinue::IfElse;
use MXCL::Term::Kontinue::DoWhile;

use MXCL::Term::Kontinue::Eval::Expr;
use MXCL::Term::Kontinue::Eval::Head;
use MXCL::Term::Kontinue::Eval::Rest;
use MXCL::Term::Kontinue::Eval::TOS;

use MXCL::Term::Kontinue::Apply::Expr;
use MXCL::Term::Kontinue::Apply::Stack;
use MXCL::Term::Kontinue::Apply::Operative;
use MXCL::Term::Kontinue::Apply::Applicative;

use MXCL::Term::Kontinue::Define;

use MXCL::Term::Kontinue::Scope::Enter;
use MXCL::Term::Kontinue::Scope::Leave;

class MXCL::Allocator::Kontinues {
    field $arena :param :reader;

    ## -------------------------------------------------------------------------

    method Update ($k, $env, $stack) {
        my %args = $k->DECOMPOSE;
        $args{env}   = $env;
        $args{stack} = $stack;
        # Scope::Leave preserves its own env (it owns the scope boundary)
        $args{env}   = $k->env if $k isa MXCL::Term::Kontinue::Scope::Leave;
        return $arena->allocate(blessed $k, %args);
    }

    ## -------------------------------------------------------------------------

    method Host ($env, $effect, $config, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Host::,
            env    => $env,
            #effect => $effect,
            #config => $config,
            stack  => $stack,
        )
    }

    ## -------------------------------------------------------------------------

    method Return ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Return::,
            env   => $env,
            stack => $stack,
        )
    }

    method Discard ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Discard::,
            env   => $env,
            stack => $stack,
        )
    }

    ## -------------------------------------------------------------------------

    method Define ($env, $name, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Define::,
            env   => $env,
            stack => $stack,
            name  => $name,
        )
    }

    method Capture ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Capture::,
            env    => $env,
            stack  => $stack,
            origin => $env,
        )
    }

    ## -------------------------------------------------------------------------

    method Scope ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Scope::Enter::,
            env   => $env,
            stack => $stack,
            leave => $arena->allocate(MXCL::Term::Kontinue::Scope::Leave::,
                env   => $env,
                stack => $stack,
            )
        );
    }

    ## -------------------------------------------------------------------------

    method IfElse ($env, $cond, $if_true, $if_false, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::IfElse::,
            env       => $env,
            stack     => $stack,
            condition => $cond,
            if_true   => $if_true,
            if_false  => $if_false,
        )
    }

    method DoWhile ($env, $cond, $body, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::DoWhile::,
            env       => $env,
            stack     => $stack,
            condition => $cond,
            body      => $body,
        )
    }

    ## -------------------------------------------------------------------------

    method EvalExpr ($env, $expr, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Eval::Expr::,
            env   => $env,
            expr  => $expr,
            stack => $stack,
        )
    }

    method EvalHead ($env, $cons, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Eval::Head::,
            env   => $env,
            cons  => $cons,
            stack => $stack,
        )
    }

    method EvalRest ($env, $rest, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Eval::Rest::,
            env   => $env,
            rest  => $rest,
            stack => $stack,
        )
    }

    method EvalTOS ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Eval::TOS::,
            env   => $env,
            stack => $stack,
        )
    }

    ## -------------------------------------------------------------------------

    method ApplyStack ($env, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Apply::Stack::,
            env   => $env,
            stack => $stack,
        )
    }

    method ApplyExpr ($env, $args, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Apply::Expr::,
            env   => $env,
            args  => $args,
            stack => $stack,
        )
    }

    method ApplyOperative ($env, $call, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Apply::Operative::,
            env   => $env,
            call  => $call,
            stack => $stack,
        )
    }

    method ApplyApplicative ($env, $call, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Apply::Applicative::,
            env   => $env,
            call  => $call,
            stack => $stack,
        )
    }
}


=pod

TODO:

Throw
    $exception
    # unwinds the queue
    # - collects any Context::Leave kontinuations
    # - stops if a Catch is found
    #    - passed $exception to Catch via stack
    # enqueue the Catch and any Leaves we found
Catch
    $handler
    @$exception
    # if top of stack is an exception
    # - apply the handler with the @$exception on its stack
    # otherwise, just return the top of the stack
Eval::TOS
    @$expr

=cut
