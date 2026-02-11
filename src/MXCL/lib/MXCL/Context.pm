
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

class MXCL::Context {
    field $arena     :reader;
    field $terms     :reader;
    field $traits    :reader;
    field $refs      :reader;
    field $kontinues :reader;

    field $parser    :reader;
    field $compiler  :reader;

    ADJUST {
        $arena     = MXCL::Arena->new;
        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $traits    = MXCL::Allocator::Traits->new( arena => $arena );
        $refs      = MXCL::Allocator::References->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );
        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( context => $self );
    }

}
