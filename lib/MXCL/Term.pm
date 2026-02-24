
use v5.42;
use experimental qw[ class ];

use Scalar::Util qw[blessed];

class MXCL::Term {
    field $hash :param :reader;

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

    method children {
        my %decomposed = $self->DECOMPOSE;
        my @children;
        for my $val (values %decomposed) {
            if (ref $val eq 'ARRAY') {
                push @children, grep { blessed($_) && $_->isa('MXCL::Term') } @$val;
            } elsif (blessed($val) && $val->isa('MXCL::Term')) {
                push @children, $val;
            }
        }
        return @children;
    }

    sub COMPOSE ($class, %args) {
        die "COMPOSE not implemented for $class"
    }

}
