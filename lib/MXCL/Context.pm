
use v5.42;
use experimental qw[ class switch ];

use MXCL::Arena;
use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;
use MXCL::Runtime;

use MXCL::Allocator::Terms;
use MXCL::Allocator::Roles;
use MXCL::Allocator::Kontinues;

use MXCL::Tape;
use MXCL::Tape::Spliced;

use MXCL::Debugger;

class MXCL::Context {
    field $arena     :reader;
    field $tape      :reader;

    field $terms     :reader;
    field $roles     :reader;
    field $kontinues :reader;

    field $parser    :reader;
    field $compiler  :reader;
    field $machine   :reader;
    field $runtime   :reader;

    ADJUST {
        $arena     = MXCL::Arena->new;
        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $roles     = MXCL::Allocator::Roles->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );

        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( parser => $parser, alloc => $terms );
        $runtime   = MXCL::Runtime->new;
        $machine   = MXCL::Machine->new;
        $tape      = MXCL::Tape::Spliced->new;

        $runtime->initialize( $self );

        # REMOVE ME
        $arena->commit('context initialized', roots => [ $runtime->base_scope ]);

        my $scope   = $runtime->base_scope;
        my $prelude = $runtime->prelude->artifact;

        # Splice in the prelude ...
        $tape->splice(
            MXCL::Tape->new( exprs => $prelude )->enqueue(
                # discard the last value, but pass on the Env
                $kontinues->Discard($scope, $terms->Nil),
                reverse map {
                    $kontinues->Discard($scope, $terms->Nil),
                    $kontinues->EvalExpr($scope, $_, $terms->Nil)
                } @$prelude
            )
        );
    }

    method base_scope {
        $runtime->base_scope
    }

    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        return $exprs;
    }

    method evaluate ($env, $exprs, %opts) {
        # Splice in the program ...
        $tape->splice(
            MXCL::Tape->new( exprs => $exprs )->enqueue(
                $kontinues->Host($env, 'HALT', +{}, $terms->Nil),
                reverse map {
                    $kontinues->Discard($env, $terms->Nil),
                    $kontinues->EvalExpr($env, $_, $terms->Nil)
                } @$exprs
            )
        );

        my $result = $machine->run( $self );

        # REMOVE ME
        $arena->commit('program executed', roots => [ $result->env, $result->stack ]);

        return $result;
    }
}
