
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Env :isa(MXCL::Term) {
    field $bindings :param :reader;

    method keys    { sort { $a cmp $b } keys %$bindings }
    method values  { map {     $bindings->{$_} } $self->keys }
    method entries { map { $_, $bindings->{$_} }  $self->keys }
}
