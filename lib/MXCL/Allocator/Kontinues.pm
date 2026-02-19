
use v5.42;
use experimental qw[ class switch ];

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

use MXCL::Term::Kontinue::Apply::Expr;
use MXCL::Term::Kontinue::Apply::Operative;
use MXCL::Term::Kontinue::Apply::Applicative;

use MXCL::Term::Kontinue::Define;

use MXCL::Term::Kontinue::Scope::Enter;
use MXCL::Term::Kontinue::Scope::Leave;

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
                ; # do nothing
            }
            when ('MXCL::Term::Kontinue::Discard') {
                ; # do nothing
            }
            when ('MXCL::Term::Kontinue::Capture') {
                @args{qw[ origin ]} = ($k->origin)
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
            when ('MXCL::Term::Kontinue::Scope::Enter') {
                @args{qw[ leave ]} = ($k->leave)
            }
            when ('MXCL::Term::Kontinue::Scope::Leave') {
                @args{qw[ __deferred ]} = ($k->deferred);
                $args{env} = $k->env; # preserve the env
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

















