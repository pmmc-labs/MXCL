
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Trait;

class MXCL::Allocator::Traits {
    field $arena :param :reader;

    method Trait ($name, %bindings) {
        $arena->allocate(MXCL::Term::Trait::,
            name     => $name,
            bindings => \%bindings,
        );
    }

    ## -------------------------------------------------------------------------
    ## Trait Composition
    ## -------------------------------------------------------------------------

    method Compose (@traits) {
        ...
    }
}
