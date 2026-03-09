
use v5.42;
use experimental qw[ class switch ];

class MXCL::Tape::Mixer {
    field $main :param :reader;
    field $active;

    ADJUST {
        $active = $main;
    }

    method invoke ($tape) {
        $active = $tape;
    }

    method has_next {
        return true  if $active->has_next;
        return false if refaddr $active == refaddr $main;
        $active = $main;
        return $active->has_next;
    }

    method next {
        $active->next;
    }

    method peek {
        $active->peek;
    }

    method enqueue (@kontinues) {
        $active->enqueue( @kontinues );
        $self;
    }

    method advance ($ctx, $k, @next) {
        $active->advance( $ctx, $k, @next );
    }
}
