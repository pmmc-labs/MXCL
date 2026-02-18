
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term;
use MXCL::Term::Ref;

class MXCL::Allocator::References {
    field $arena :param :reader;
    field $refs  :param :reader = +{};

    method Ref ($value) {
        state $nonce = 0;
        my $uid = sprintf 'ref:%s:%d' => blessed $value, ++$nonce; # unique ref identity
        $refs->{ $uid } = $value;
        return $arena->allocate(MXCL::Term::Ref::, uid => $uid );
    }

    ## -------------------------------------------------------------------------
    ## Ref Utils
    ## -------------------------------------------------------------------------

    method Deref ($ref) {
        return $refs->{ $ref->uid }
    }

    method SetRef ($ref, $value) {
        $refs->{ $ref->uid } = $value;
        $ref;
    }
}
