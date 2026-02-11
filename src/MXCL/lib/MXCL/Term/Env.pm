
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Env :isa(MXCL::Term) {
    field $parent   :param :reader = undef;
    field $bindings :param :reader;

    method lookup ($key) {
        return $bindings->{ $key }     if exists $bindings->{ $key };
        return $parent->lookup( $key ) if defined $parent;
        return;
    }

    method keys    { sort { $a cmp $b } keys %$bindings }
    method values  { map {     $bindings->{$_} } $self->keys }
    method entries { map { $_, $bindings->{$_} }  $self->keys }

    method to_string {
        sprintf 'e{ %s }' => join ', ' => $self->keys
    }

    method pprint { die 'Cannot pprint a Env' }
}
