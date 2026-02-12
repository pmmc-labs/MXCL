
use v5.42;
use experimental qw[ class ];

use Digest::MD5 ();

class MXCL::Arena {
    field $terms :reader = +{};

    # TODO - this could be done better
    field $generations :reader = +[];
    field $current_gen :reader = 0;

    # FIXME - these started out as stats
    # trackers, but are not being used in
    # commit tracking, so these will need
    # work, but are fine-ish for now.
    field $statz :reader = +{};
    field $typez :reader = +{};
    field $hashz :reader = +{};

    # ... commits

    method commit_generation ($label) {
        # track the commits ...
        push @$generations => +{
            label  => $label,
            # NOTE: this is not ideal, we should
            # do it properly, but these two thing
            # track enough information for now
            statz  => +{ %$statz },
            typez  => +{ %$typez },
            hashz  => +{ %$hashz },
        };

        # clear them each generation
        # so that we are just track
        # the new changes ...
        $statz->%* = ();
        $typez->%* = ();
        $hashz->%* = ();

        # get the next gen marker
        $current_gen = scalar @$generations;
        $self;
    }

    method allocate ($type, %fields) {
        my @names  = sort { $a cmp $b } keys %fields;
        my @values = @fields{ @names };
        my $hash   = $self->construct_hash($type, @values);

        $statz->{alive}++;
        $statz->{types}{$type}++;
        $statz->{hashes}{$hash}++;

        $typez->{$type}{alive}++;
        $typez->{$type}{hits}   //= 0;
        $typez->{$type}{misses} //= 0;

        $hashz->{$hash}{alive}++;
        $hashz->{$hash}{hits}   //= 0;
        $hashz->{$hash}{misses} //= 0;

        if (exists $terms->{ $hash }) {
            $statz->{hits}++;
            $typez->{$type}{hits}++;
            $hashz->{$hash}{hits}++;
            return $terms->{ $hash };
        } else {
            $statz->{misses}++;
            $typez->{$type}{misses}++;
            $hashz->{$hash}{misses}++;
            return $terms->{ $hash } = $type->new(
                hash => $hash,
                gen  => $current_gen,
                %fields
            );
        }
    }

    method construct_hash ($inv, @values) {
        my $type = blessed $inv // $inv;

        if (scalar @values == 1 && ref $values[0] && !(blessed $values[0])) {
            if (reftype $values[0] eq 'HASH') {
                my $hashref = shift @values;
                @values = map { $_, $hashref->{$_} } sort { $a cmp $b } keys %$hashref;
            }
            elsif (reftype $values[0] eq 'ARRAY') {
                my $arrayref = shift @values;
                @values = @$arrayref;
            }
            else {
                die "BAD REF TYPE, NO HASH FOR YOU! ",join ', ' => @values;
            }
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
