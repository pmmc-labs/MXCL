
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

    field $terms     :reader;
    field $roles     :reader;
    field $kontinues :reader;

    field $parser    :reader;
    field $compiler  :reader;
    field $machine   :reader;
    field $runtime   :reader;

    field $tape;
    field @scopes;
    field $initialized = false;

    ADJUST {
        $arena     = MXCL::Arena->new;
        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $roles     = MXCL::Allocator::Roles->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );

        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( parser => $parser, alloc => $terms );
        $runtime   = MXCL::Runtime->new;
        $machine   = MXCL::Machine->new;
    }

    method tape {
        $tape // die "TAPE IS NOT READY YET!";
    }

    method initialize (%options) {
        return if $initialized;

        $runtime->initialize( $self );

        my $scope   = $runtime->base_scope;
        my $prelude = $runtime->prelude->artifact;

        push @scopes => $scope;

        # Splice in the prelude ...
        $tape = MXCL::Tape->new( exprs => $prelude )->enqueue(
            $kontinues->Host($scope, 'HALT', +{}, $terms->Nil),
            reverse map {
                $kontinues->Discard($scope, $terms->Nil),
                $kontinues->EvalExpr($scope, $_, $terms->Nil)
            } @$prelude
        );

        my $result = $machine->run( $self );

        push @scopes => $result->env;

        $tape = MXCL::Tape::Spliced->new;

        $initialized = true;

        return $self;
    }

    method prelude_scope { $scopes[1] }

    method base_scope { $scopes[-1] }

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

        return $result;
    }
}
