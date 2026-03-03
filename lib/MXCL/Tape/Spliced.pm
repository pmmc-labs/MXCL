
use v5.42;
use experimental qw[ class switch ];

class MXCL::Tape::Spliced {
    field $tapes :reader = +[];
    field $idx = 0;

    method splice ($tape) { push @$tapes => $tape }

    method queue { $tapes->[$idx]->queue }
    method trace { $tapes->[$idx]->trace }
    method steps { $tapes->[$idx]->steps }

    method has_next {
        while (@$tapes) {
            return true if $tapes->[$idx]->has_next;
            # FIXME: the `next` should actually do the
            # incrementing, because this will increment
            # when tested, and affect any other methods
            # like enqueue. Look at the usage though
            # it might a differnt issue.
            $idx++;

        }
        return false;
    }

    method next {
        $tapes->[$idx]->next;
    }

    method peek {
        $tapes->[$idx]->peek;
    }

    method enqueue (@kontinues) {
        $tapes->[$idx]->enqueue( @kontinues );
        $self;
    }

    method advance ($ctx, $k, @next) {
        $tapes->[$idx]->advance( $ctx, $k, @next );
    }
}
