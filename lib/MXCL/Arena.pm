
use v5.42;
use experimental qw[ class ];

use Time::HiRes ();

use MXCL::Internals;

class MXCL::Arena::Commit {
    field $parent    :param :reader;
    field $message   :param :reader;
    field $changed   :param :reader;
    field $roots     :param :reader;
    field $reachable :param :reader;

    method pprint {
        sprintf q[Commit(
    message   : %s,
    parent    : %s,
    changed   :[
        %s
    ],
    reachable : %d terms
)] =>  $message,
       ($parent ? $parent->hash : '~'),
       join("\n        " => sort { $a cmp $b } map $_->hash, @$changed),
       scalar @$reachable;
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
    field $storage    :reader = +{};
    field $commit_log :reader = +[];
    field @staged;

    field $statz :reader = +{};
    field $typez :reader = +{};
    field $hashz :reader = +{};
    field $timez :reader = +{};

    method size { scalar keys %$storage }

    method commit ($label, %opts) {
        my @roots     = @{ $opts{roots} // [] };
        my @reachable = @roots ? $self->reachable_from(@roots) : ();

        push @$commit_log => MXCL::Arena::Commit->new(
            message   => $label,
            parent    => $commit_log->[-1],
            changed   => [ @staged ],
            roots     => \@roots,
            reachable => \@reachable,
        );

        @staged = ();
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
            $storage->{ $hash } = $type->new(%with_hash);
            push @staged => $storage->{ $hash };

            $timez->{allocated} += Time::HiRes::tv_interval( $start );
            # do not let stats interfere
            $statz->{allocated}++;
            $typez->{$type}{allocated}++;
            $hashz->{$hash}{allocated}++;
        }

        return $storage->{ $hash }
    }

    method walk ($cb) {
        for my $commit (@$commit_log) {
            $cb->($commit, $_) for @{$commit->changed};
        }
    }

    method dropped_between ($commit_a, $commit_b) {
        my %in_b = map { $_->hash => 1 } @{$commit_b->reachable};
        return grep { !$in_b{ $_->hash } } @{$commit_a->reachable};
    }

    method reachable_from (@roots) {
        my %seen;
        my @queue = @roots;
        while (my $term = shift @queue) {
            next if exists $seen{ $term->hash };
            $seen{ $term->hash } = $term;
            push @queue, $term->children;
        }
        return values %seen;
    }
}
