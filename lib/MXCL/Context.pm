
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
use MXCL::Allocator::Kontinues;

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
        $runtime   = MXCL::Runtime->new( context => $self );
        $machine   = MXCL::Machine->new;
        $tape      = MXCL::Tape->new;

        $arena->commit_generation('context initialized');
    }

    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        $arena->commit_generation('program compiled');
        return $exprs;
    }

    method evaluate ($env, $exprs) {
        my $result = $machine->run( $self, $env, $exprs );
        $arena->commit_generation('program executed');
        return $result;
    }
}
