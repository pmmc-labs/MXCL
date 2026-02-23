
use v5.42;
use experimental qw[ class ];

class MXCL::Term {
    field $hash :param :reader;
    field $gen  :param :reader;

    method type {
        my $type = __CLASS__ =~ s/^MXCL\:\:Term\:\://r;
        return $type || '*TERM*'
    }

    method eq ($other) { $hash eq $other->hash }

    method stringify  { die "No stringify specified for ".$self->type }
    method numify  { die "No numify specified for ".$self->type }
    method boolify { die "No boolify specified for ".$self->type }

    method pprint { $self->stringify }

    method DECOMPOSE { () }

    sub COMPOSE {
        my ($class, %args) = @_;
        die "COMPOSE not implemented for $class"
    }

}
