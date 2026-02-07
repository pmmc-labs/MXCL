
use v5.42;
use experimental qw[ class ];

use Digest::MD5 ();

class MXCL::Arena {
    sub construct_hash ($inv, @values) {
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

    field $terms :reader = +{};
    field $alive :reader = 0;

    method allocate ($type, %fields) {
        my @names  = sort { $a cmp $b } keys %fields;
        my @values = @fields{ @names };
        my $hash = construct_hash($type, @values);
        $alive++;
        return $terms->{ $hash } //= $type->new( hash => $hash, %fields );
    }

    method num_pointers  { $alive }
    method num_allocated { scalar keys %$terms }

    method term_report {
        my %stats;
        foreach my $term (values %$terms) {
            $stats{ blessed $term }++;
        }
        return \%stats;
    }
}
