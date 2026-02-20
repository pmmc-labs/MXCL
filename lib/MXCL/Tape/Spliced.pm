
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
        #warn "ENTER\n";
        while (@$tapes) {
            #warn "has-next? ", join ', ' => @$tapes;
            return true if $tapes->[$idx]->has_next;
            $idx++;
            #warn "??has-next-tape! ", join ', ' => @$tapes;
        }
        #warn "LEAVE\n";
        return false;
    }

    method next {
        #warn ">>> next? ", join ', ' => @$tapes;
        $tapes->[$idx]->next;
    }

    method enqueue (@kontinues) {
        $tapes->[$idx]->enqueue( @kontinues );
        $self;
    }

    method advance ($k, @next) {
        $tapes->[$idx]->advance( $k, @next );
    }
}
