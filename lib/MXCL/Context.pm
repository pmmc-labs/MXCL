
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

        $arena->commit_generation('context initialized');
    }

    method base_scope {
        $runtime->base_scope( $self )
    }

    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        $arena->commit_generation('program compiled');
        return $exprs;
    }

    method evaluate ($env, $exprs, %opts) {

        if (exists $opts{load_prelude}) {
            # Load in the prelude ...
            $tape->splice(
                MXCL::Tape->new->enqueue(
                    # discard the last value, but pass on the Env
                    $kontinues->Discard($env, $terms->Nil),
                    reverse map {
                        $kontinues->Discard($env, $terms->Nil),
                        $kontinues->EvalExpr($env, $_, $terms->Nil)
                    } $self->compile_source(q[
                        (let $NAME      "MXCL")
                        (let $VERSION   :v0.0.1)
                        (let $AUTHORITY :cpan:STEVAN)
                    ])->@*
                )
            );
        }

        $tape->splice(
            MXCL::Tape->new->enqueue(
                $kontinues->Host($env, 'HALT', +{}, $terms->Nil),
                reverse map {
                    $kontinues->Discard($env, $terms->Nil),
                    $kontinues->EvalExpr($env, $_, $terms->Nil)
                } @$exprs
            )
        );

        my $result = $machine->run( $self );
        $arena->commit_generation('program executed');
        return $result;
    }
}
