
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Trait :isa(MXCL::Term) {
    field $name         :param :reader;
    field $bindings     :param :reader;
    field $__provenance :param :reader(provenance) = +[];

    method lookup ($key) { $bindings->{ $key } }

    # TODO:
    # need methods to ask if this trait is resolved or now
    # and maybe even methods to resolve conflicts, etc.

    method stringify {
        sprintf '%s{ %s }' =>
            $name,
            join ', ' =>
            sort { $a cmp $b } keys %$bindings;
    }
}
