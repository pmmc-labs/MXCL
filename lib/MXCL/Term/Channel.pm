
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Channel :isa(MXCL::Term) {
    field $uid        :reader :param;

    field $__on_read  :param = undef;
    field $__on_write :param = undef;

    field $__buffer   :reader(buffer) = +[];

    method on_read  :lvalue { $__on_read  }
    method on_write :lvalue { $__on_write }

    method read {
        $__on_read->($self) if defined $__on_read;
        return pop @$__buffer;
    }

    method write (@data) {
        unshift @$__buffer => @data;
        $__on_write->($self) if defined $__on_write;
        return;
    }

    method buffer_read ($value) {
        push @$__buffer => $value;
    }

    method buffer_drain  {
        my @buffer = @$__buffer;
        $__buffer->@* = ();
        return @buffer;
    }

    method stringify { sprintf 'Channel<%s>' => $uid }
    method boolify { true }

    method DECOMPOSE {
        (uid => $uid,
            __buffer => $__buffer,
            __on_read => $__on_read,
            __on_write => $__on_write)
    }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, $args{uid}))
    }
}
