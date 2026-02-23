
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Nil :isa(MXCL::Term) {

    method stringify { '()' }
    method boolify { false }

    method DECOMPOSE { () }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (hash => MXCL::Internals::hash_fields($class))
    }
}
