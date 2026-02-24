
use v5.42;
use experimental qw[ class ];

use Time::HiRes ();

use MXCL::Internals;

class MXCL::Arena::Commit {
    field $parent   :param :reader;
    field $message  :param :reader;
    field $changed  :param :reader;

    method pprint {
        sprintf q[Commit(
    msg     : %s,
    parent  : %s,
    changed :[
        %s
    ]
)] =>  $message,
       ($parent ? $parent->hash : '~'),
       join "\n        " => sort { $a cmp $b } map $_->hash, @$changed;
    }

    method hash {
        return MXCL::Internals::hash_fields(
            blessed $self,
            ($parent ? $parent->hash : ''),
            sort { $a cmp $b } map $_->hash, @$changed
        )
    }
}


class MXCL::Arena {
    field $storage :reader = +{};

    # ...
    field $commit_log :reader = +[];
    field @staged;

    # TODO - this could be done better
    field $generations :reader = +[];
    field $current_gen :reader = 0;

    field $statz :reader = +{};
    field $typez :reader = +{};
    field $hashz :reader = +{};
    field $timez :reader = +{};

    # ... commits

    method commit_generation ($label) {
        # track the commits ...
        push @$generations => +{ label  => $label };

        push @$commit_log => MXCL::Arena::Commit->new(
            message => $label,
            parent  => $commit_log->[-1],
            changed => [ @staged ],
        );

        @staged = ();

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
        $statz->{active}++;
        $statz->{types}{$type}++;
        $statz->{hashes}{$hash}++;

        $typez->{$type}{active}++;
        $typez->{$type}{cached}    //= 0;
        $typez->{$type}{allocated} //= 0;

        $hashz->{$hash}{active}++;
        $hashz->{$hash}{cached}    //= 0;
        $hashz->{$hash}{allocated} //= 0;

        # check timing for cache cached/allocated
        my $start = [Time::HiRes::gettimeofday];
        if (exists $storage->{ $hash }) {
            $timez->{cached} += Time::HiRes::tv_interval( $start );
            # do not let stats interfere
            $statz->{cached}++;
            $typez->{$type}{cached}++;
            $hashz->{$hash}{cached}++;
        } else {
            $storage->{ $hash } = $type->new(
                %with_hash,
                gen => $current_gen,
            );

            push @staged => $storage->{ $hash };

            $timez->{allocated} += Time::HiRes::tv_interval( $start );
            # do not let stats interfere
            $statz->{allocated}++;
            $typez->{$type}{allocated}++;
            $hashz->{$hash}{allocated}++;
        }

        return $storage->{ $hash }
    }
}
