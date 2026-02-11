
use v5.42;
use experimental qw[ class ];

class MXCL::Term {
    use overload '""' => 'pprint';

    field $hash :param :reader;

    method type {
        my $type = __CLASS__ =~ s/^MXCL\:\:Term\:\://r;
        return $type || '*TERM*'
    }

    method eq ($other) { $hash eq $other->hash }

    method to_string  { die "No to_string specified for ".$self->type }
    method to_number  { die "No to_number specified for ".$self->type }
    method to_boolean { die "No to_boolean specified for ".$self->type }

    method pprint { $self->to_string }
}
