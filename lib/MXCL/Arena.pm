
use v5.42;
use experimental qw[ class ];

use Time::HiRes ();

class MXCL::Arena {
    field $terms :reader = +{};

    # XXX - lets see where this goes
    field $history :reader = +[];

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
    field $timez :reader = +{};

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
            timez  => +{ %$timez },
        };

        # clear them each generation
        # so that we are just track
        # the new changes ...
        #$statz->%* = ();
        #$typez->%* = ();
        #$hashz->%* = ();
        #$timez->%* = ();

        # get the next gen marker
        $current_gen = scalar @$generations;
        $self;
    }

    method allocate ($type, %fields) {
        # ask the type to compose its hash from fields
        my $hash_start  = [Time::HiRes::gettimeofday];
        my %with_hash   = $type->COMPOSE(%fields);
        my $hash        = $with_hash{hash};
        $timez->{hashing} += Time::HiRes::tv_interval( $hash_start );

        # dont let stats interfere
        $statz->{alive}++;
        $statz->{types}{$type}++;
        $statz->{hashes}{$hash}++;

        $typez->{$type}{alive}++;
        $typez->{$type}{hits}   //= 0;
        $typez->{$type}{misses} //= 0;

        $hashz->{$hash}{alive}++;
        $hashz->{$hash}{hits}   //= 0;
        $hashz->{$hash}{misses} //= 0;

        # check timing for cache hits/misses
        my $start = [Time::HiRes::gettimeofday];
        if (exists $terms->{ $hash }) {
            $timez->{hits} += Time::HiRes::tv_interval( $start );
            # do not let stats interfere
            $statz->{hits}++;
            $typez->{$type}{hits}++;
            $hashz->{$hash}{hits}++;
        } else {
            $terms->{ $hash } = $type->new(
                %with_hash,
                gen => $current_gen,
            );

            push @$history => $hash;

            $timez->{misses} += Time::HiRes::tv_interval( $start );
            # do not let stats interfere
            $statz->{misses}++;
            $typez->{$type}{misses}++;
            $hashz->{$hash}{misses}++;
        }

        return $terms->{ $hash }
    }
}
