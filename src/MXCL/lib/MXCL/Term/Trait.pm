
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Trait :isa(MXCL::Term) {
    field $name     :param :reader;
    field $bindings :param :reader;

    method lookup ($key) { $bindings->{ $key } }

    method keys    { sort { $a cmp $b } keys %$bindings }
    method values  { map {     $bindings->{$_} } $self->keys }
    method entries { map { $_, $bindings->{$_} }  $self->keys }

    method to_string {
        sprintf '%s{ %s }' => $name, join ', ' => $self->keys
    }
}
