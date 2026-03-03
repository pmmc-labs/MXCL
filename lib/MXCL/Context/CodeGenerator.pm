
use v5.42;
use experimental qw[ class switch ];

use MXCL::Tape;

class MXCL::Context::CodeGenerator {
    field $context :param :reader;

    field $terms     :reader;
    field $roles     :reader;
    field $kontinues :reader;

    ADJUST {
        $terms     = $context->terms;
        $roles     = $context->roles;
        $kontinues = $context->kontinues;
    }

    # --------------------------------------------------------------------------

    method create_tape ($name, $env, $exprs) {
        return MXCL::Tape->new( name => $name, exprs => $exprs )->enqueue(
            $self->Halt( $env ),
            $self->EvalStatements( $env, $exprs )
        )
    }

    # --------------------------------------------------------------------------

    method InScope ($enter, $leave, @kontinues) {
        $kontinues->Scope( $enter, $leave, $terms->Nil )->wrap( @kontinues )
    }

    method CaptureScope ($env, $exprs) {
        return (
            $kontinues->Capture( $env, $terms->Nil ),
            $self->EvalStatements( $env, $exprs )
        )
    }

    method ReturnValues ($env, @values) {
        $kontinues->Return(
            $env,
            (@values ? $terms->List( @values ) : $terms->Nil)
        )
    }

    method ConstructRole ($env, $with, $exprs) {
        $self->InScope( $env, $env,
            ($with isa MXCL::Term::Nil
                ? ()
                : $kontinues->ApplyStack( $env, $with )),
            $self->CaptureScope( $env, $exprs )
        )
    }

    # --------------------------------------------------------------------------

    method ComposeRoles ($env, $lhs, $rhs) {
        ($lhs, $rhs) = map {
            $_ isa MXCL::Term::Sym
                ? $env->lookup( $_->value )->value
                : $_
        } ($lhs, $rhs);
        return $kontinues->Return(
            $env,
            $terms->List( $roles->Union( $lhs, $rhs ) )
        );
    }

    # --------------------------------------------------------------------------

    method DeclareRequirement ($env, $name) {
        $kontinues->Define(
            $env,
            $name,
            $terms->List( $roles->Required( $name ) )
        );
    }

    method DeclareVariable ($env, $name, $value) {
        return (
            $kontinues->Define( $env, $name, $terms->Nil ),
            $kontinues->EvalExpr( $env, $value, $terms->Nil )
        );
    }

    method DefineFunction ($env, $name, $params, $body) {
        return $kontinues->Define(
            $env,
            $name,
            $terms->List( $terms->Lambda( $params, $body, $env, $name ) )
        );
    }

    method DefineFExpr ($env, $name, $params, $body) {
        return $kontinues->Define(
            $env,
            $name,
            $terms->List( $terms->FExpr( $params, $body, $env, $name ) )
        );
    }

    method DefineRole ($env, $name, $with, $exprs) {
        return (
            $kontinues->Define( $env, $name, $terms->Nil ),
            $self->InScope( $env, $env,
                ($with isa MXCL::Term::Nil
                    ? ()
                    : $kontinues->ApplyStack( $env, $with )),
                $self->CaptureScope( $env, $exprs )
            )
        )
    }

    # --------------------------------------------------------------------------

    method Halt ($env) {
        $kontinues->Host( $env, 'HALT', +{}, $terms->Nil )
    }

    method EvalStatements ($env, $stmts) {
        reverse map {
            $kontinues->Discard( $env, $terms->Nil ),
            $kontinues->EvalExpr( $env, $_, $terms->Nil )
        } @$stmts
    }

    method EvalStatementsInScope ($env, $stmts) {
        $self->InScope( $env, $env, $self->EvalStatements( $env, $stmts ) )
    }

    # --------------------------------------------------------------------------

    method Conditional ($env, $cond, $if_true, $if_false) {
        return (
            $kontinues->IfElse( $env, $cond, $if_true, $if_false, $terms->Nil ),
            $kontinues->EvalExpr( $env, $cond, $terms->Nil ),
        )
    }

    method AndShortCircuit ($env, $lhs, $rhs) {
        return (
            $kontinues->IfElse( $env, $lhs, $rhs, $lhs, $terms->Nil ),
            $kontinues->EvalExpr( $env, $lhs, $terms->Nil ),
        )
    }

    method OrShortCircuit ($env, $lhs, $rhs) {
        return (
            $kontinues->IfElse( $env, $lhs, $lhs, $rhs, $terms->Nil ),
            $kontinues->EvalExpr( $env, $lhs, $terms->Nil ),
        )
    }

    method LoopWhile ($env, $cond, $body) {
        return (
            $kontinues->DoWhile( $env, $cond, $body, $terms->Nil ),
            $kontinues->EvalExpr( $env, $cond, $terms->Nil ),
        )
    }

    # --------------------------------------------------------------------------
}
