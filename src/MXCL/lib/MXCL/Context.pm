
use v5.42;
use experimental qw[ class switch ];

use MXCL::Arena;
use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;

use MXCL::Allocator::Terms;
use MXCL::Allocator::Traits;
use MXCL::Allocator::References;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Natives;

class MXCL::Context {
    field $arena     :reader;

    field $terms     :reader;
    field $traits    :reader;
    field $refs      :reader;
    field $kontinues :reader;
    field $natives   :reader;

    field $parser    :reader;
    field $compiler  :reader;
    field $machine   :reader;

    ADJUST {
        $arena     = MXCL::Arena->new;

        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( context => $self );
        $machine   = MXCL::Machine->new( context => $self );

        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $traits    = MXCL::Allocator::Traits->new( arena => $arena );
        $refs      = MXCL::Allocator::References->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );
        $natives   = MXCL::Allocator::Natives->new(
            arena => $arena,
            terms => $terms, # FIXME - see TODO.md
        );

        $arena->commit_generation('context initialized');
    }


    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        $arena->commit_generation('program compiled');
        return $exprs;
    }

    method evaluate ( $env, $exprs ) {
        my $result = $machine->run( $env, $exprs );
        $arena->commit_generation('program executed');
        return $result;
    }
}
