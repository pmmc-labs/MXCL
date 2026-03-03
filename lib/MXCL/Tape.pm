
use v5.42;
use experimental qw[ class switch ];

use MXCL::Debugger;

class MXCL::Tape {
    field $name  :param :reader;
    field $exprs :param :reader;

    field $queue :reader = +[];
    field $trace :reader = +[];
    field $steps :reader = 0;

    method has_next { scalar @$queue > 0 }
    method next     { pop @$queue }
    method peek     { $queue->[-1] }

    method enqueue (@kontinues) {
        push @$queue => @kontinues;
        $self;
    }

    method advance ($ctx, $k, @next) {
        MXCL::Debugger->DEBUG
            && MXCL::Debugger->monitor_tape_advance( $ctx, $self, $k, \@next );
        push    @$queue => @next;
        unshift @$trace => $k;
        $steps++;
    }
}
