
use v5.42;
use experimental qw[ class switch ];

use MXCL::Arena;

use MXCL::Term::Kontinue::Host;

use MXCL::Term::Kontinue::Return;

use MXCL::Term::Kontinue::IfElse;
use MXCL::Term::Kontinue::DoWhile;

use MXCL::Term::Kontinue::Eval::Expr;
use MXCL::Term::Kontinue::Eval::Head;
use MXCL::Term::Kontinue::Eval::Rest;

use MXCL::Term::Kontinue::Apply::Expr;
use MXCL::Term::Kontinue::Apply::Operative;
use MXCL::Term::Kontinue::Apply::Applicative;

use MXCL::Term::Kontinue::Define;

class MXCL::Allocator::Kontinues {
    field $arena :param :reader;

    ## -------------------------------------------------------------------------

    # XXX - this needs a better name
    method Update ($k, $env, $stack) {
        my %args;
        $args{env}   = $env;
        $args{stack} = $stack;
        # XXX - and I can't decide if this given/when
        # is really gross, or better than violating
        # encapsulation and having the class give
        # me this information, we shall see if we have
        # to do it again or not.
        given (blessed $k) {
            when ('MXCL::Term::Kontinue::Host') {
                @args{qw[ effect config ]} = ($k->effect, $k->config)
            }
            when ('MXCL::Term::Kontinue::Return') {
                $args{env} = $k->env; # preserve the env
            }
            when ('MXCL::Term::Kontinue::IfElse') {
                @args{qw[ condition if_true if_false ]} = ($k->condition, $k->if_true, $k->if_false)
            }
            when ('MXCL::Term::Kontinue::DoWhile') {
                @args{qw[ condition body ]} = ($k->condition, $k->body)
            }
            when ('MXCL::Term::Kontinue::Eval::Expr') {
                @args{qw[ expr ]} = ($k->expr)
            }
            when ('MXCL::Term::Kontinue::Eval::Head') {
                @args{qw[ cons ]} = ($k->cons)
            }
            when ('MXCL::Term::Kontinue::Eval::Rest') {
                @args{qw[ rest ]} = ($k->rest)
            }
            when ('MXCL::Term::Kontinue::Apply::Expr') {
                @args{qw[ args ]} = ($k->args)
            }
            when ('MXCL::Term::Kontinue::Apply::Operative') {
                @args{qw[ call ]} = ($k->call)
            }
            when ('MXCL::Term::Kontinue::Apply::Applicative') {
                @args{qw[ call ]} = ($k->call)
            }
            when ('MXCL::Term::Kontinue::Define') {
                @args{qw[ name ]} = ($k->name)
            }
            default {
                die 'BAD KONTINUE NO UPDATE FOR YOU!';
            }
        }
        return $arena->allocate(blessed $k, %args);
    }

    ## -------------------------------------------------------------------------

    method Host ($env, $effect, $config, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Host::,
            env    => $env,
            effect => $effect,
            config => $config,
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

    ## -------------------------------------------------------------------------

    method Define ($env, $name, $stack) {
        $arena->allocate(MXCL::Term::Kontinue::Define::,
            env   => $env,
            stack => $stack,
            name  => $name,
        )
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

    ## -------------------------------------------------------------------------

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

LEGEND:
$__INTERNAL  # often an internal detail
$__mutable   # these things are mutated after creation
@$on_stack   # a value which is expected to be on the stack

Kontinue
    $__env
    $__stack

## -----------------------------------------------------------------------------
## these might be internal and non user accesible ...
## I need to think more about Context stuff.
## -----------------------------------------------------------------------------

Host
    $__EFFECT  # this it the Effect object
    $__CONFIG  # and native HASHref configuration
    # - must be native, comes from Effects only

Context::Enter
    $__LEAVE
    # - returns all values of the stack
    # - defines the local `defer` which pushes
    #   onto the $__LEAVE it is paired with
Context::Leave
    $__deferred
    # - runs all deferred calls
    # - returns all values of the stack

## -----------------------------------------------------------------------------
## Control structures
## -----------------------------------------------------------------------------

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
IfElse
    $condition
    $if_true
    $if_false
    # check the contiditon and evalute the correct branch
DoWhile
    $conditon
    $body
    # checks the condition and re-calls itself until it fails

## -----------------------------------------------------------------------------
## TODO: Replace these ...
## -----------------------------------------------------------------------------

Define
    $name
    @$value
Mutate
    $name
    @$value

## -----------------------------------------------------------------------------
## TODO: Turn these into explicit stack operations
## -----------------------------------------------------------------------------

Return
    $value

## -----------------------------------------------------------------------------
## Evaling
## -----------------------------------------------------------------------------

Eval::Expr
    $expr
Eval::TOS
    @$expr
Eval::Head
    $cons
Eval::Rest
    $rest
    # - returns all values of the stack

## -----------------------------------------------------------------------------
## Applying
## -----------------------------------------------------------------------------

Apply::Expr
    $args
    @$call
    # dispatch based on type:
    # - operative
    #   - pass $args directly via the stack
    # - applicative
    #   - enqueue $args for eval (and they will end up on the stack)
Apply::Operative
    $call
    @$args
    # dispatch based on type:
    # - fexpr
    # - native
    # - opaque
Apply::Applicative
    $call
    @$args
    # dispatch based on type:
    # - lambda
    # - native

## -----------------------------------------------------------------------------

=cut

















