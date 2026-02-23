
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Tag :isa(MXCL::Term) {
    field $value :param :reader;

    method stringify  { ":${value}" }

    method DECOMPOSE { (value => $value) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{value}))
    }
}
