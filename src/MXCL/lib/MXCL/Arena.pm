
use v5.42;
use experimental qw[ class ];

use Digest::MD5 ();

class MXCL::Arena {
    field $terms :reader = +{};

    # TODO:
    # these stats are kind of clumbsy,
    # they need more thinking, we probably
    # need a Arena::Stats class that can
    # tracks things in a smarter way.

    field $stats :reader = +{};
    field $hashs :reader = +{};

    # TODO:
    # add generation counting
    # - the first generation would be the singletons
    # - next comes the terms allocated in the compiler
    # - next comes the start of runtime
    # - then once at each host continuation

    method allocate ($type, %fields) {
        my @names  = sort { $a cmp $b } keys %fields;
        my @values = @fields{ @names };
        my $hash   = $self->construct_hash($type, @values);

        $stats->{$type}{alive}++;
        $stats->{$type}{hits}   //= 0;
        $stats->{$type}{misses} //= 0;

        $hashs->{$hash}{alive}++;
        $hashs->{$hash}{hits}   //= 0;
        $hashs->{$hash}{misses} //= 0;

        if (exists $terms->{ $hash }) {
            $stats->{$type}{hits}++;
            $hashs->{$hash}{hits}++;
            return $terms->{ $hash };
        } else {
            $stats->{$type}{misses}++;
            $hashs->{$hash}{misses}++;
            return $terms->{ $hash } = $type->new( hash => $hash, %fields );
        }
    }

    method construct_hash ($inv, @values) {
        my $type = blessed $inv // $inv;

        if (scalar @values == 1 && ref $values[0] && reftype $values[0] eq 'HASH') {
            my $hashref = shift @values;
            @values = map { $_, $hashref->{$_} } sort { $a cmp $b } keys %$hashref;
        }

        return Digest::MD5::md5_hex( $type, map {
            # FIXME: This is maybe a bit fragile
            # and very opaque, we should make it
            # easier to catch issues here.
            blessed $_
                ? $_->isa('MXCL::Term')
                    ? $_->hash
                    : refaddr $_
                : ref $_
                    ? refaddr $_
                    : $_
        } @values );
    }
}
