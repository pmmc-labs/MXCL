
use v5.42;
use experimental qw[ class switch ];

class MXCL::Tape {
    field $queue :reader = +[];
    field $trace :reader = +[];
    field $steps :reader = 0;

    method has_next { scalar @$queue > 0 }
    method next     { pop @$queue }

    method enqueue (@kontinues) {
        push @$queue => @kontinues
    }

    method advance ($k, @next) {
        push    @$queue => @next;
        unshift @$trace => $k;
        $steps++;
    }
}
