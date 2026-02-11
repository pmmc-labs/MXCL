
use v5.42;
use experimental qw[ class ];

class MXCL::Term {
    field $hash :param :reader;

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\://r }

    method eq ($other) { $hash eq $other->hash }
}
