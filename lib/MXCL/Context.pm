
use v5.42;
use experimental qw[ class switch ];

use MXCL::Arena;
use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;
use MXCL::Runtime;
use MXCL::Tape;

use MXCL::Allocator::Terms;
use MXCL::Allocator::Roles;
use MXCL::Allocator::References;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Natives;

use MXCL::Debugger;

class MXCL::Context {
    field $arena     :reader;
    field $tape      :reader;

    field $terms     :reader;
    field $roles     :reader;
    field $refs      :reader;
    field $kontinues :reader;
    field $natives   :reader;

    field $parser    :reader;
    field $compiler  :reader;
    field $machine   :reader;
    field $runtime   :reader;

    ADJUST {
        $arena     = MXCL::Arena->new;
        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $refs      = MXCL::Allocator::References->new( arena => $arena );
        $natives   = MXCL::Allocator::Natives->new( arena => $arena, terms => $terms );
        $roles     = MXCL::Allocator::Roles->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );

        $runtime   = MXCL::Runtime->new( context => $self );

        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( context => $self );
        $machine   = MXCL::Machine->new( context => $self );
        $tape      = MXCL::Tape->new;

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
