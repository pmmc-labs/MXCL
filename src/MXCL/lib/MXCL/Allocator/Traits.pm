
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Trait;
use MXCL::Term::Trait::Slot;

class MXCL::Allocator::Traits {
    field $arena :param :reader;

    ## -------------------------------------------------------------------------
    ## Traits
    ## -------------------------------------------------------------------------

    method Trait ($name, %bindings) {
        $arena->allocate(MXCL::Term::Trait::,
            name     => $name,
            bindings => \%bindings,
        );
    }

    ## -------------------------------------------------------------------------
    ## Slots
    ## -------------------------------------------------------------------------

    method Absent   { $arena->allocate(MXCL::Term::Trait::Slot::Absent::) }
    method Required { $arena->allocate(MXCL::Term::Trait::Slot::Required::) }
    method Excluded { $arena->allocate(MXCL::Term::Trait::Slot::Excluded::) }

    method Defined  ($term)       { $arena->allocate(MXCL::Term::Trait::Slot::Defined::, term => $term ) }
    method Conflict ($lhs, $rhs)  { $arena->allocate(MXCL::Term::Trait::Slot::Conflict::, lhs => $lhs, rhs => $rhs ) }
    method Alias    ($sym, $term) { $arena->allocate(MXCL::Term::Trait::Slot::Alias::, symbol => $sym, term => $term) }

    ## -------------------------------------------------------------------------
    ## Trait Composition
    ## -------------------------------------------------------------------------

    method MergeSlots ($s1, $s2) {
        return $s2 if $s1 isa MXCL::Term::Trait::Slot::Absent   && $s2 isa MXCL::Term::Trait::Slot::Defined;
        return $s1 if $s1 isa MXCL::Term::Trait::Slot::Required && $s2 isa MXCL::Term::Trait::Slot::Required;
        return $s2 if $s1 isa MXCL::Term::Trait::Slot::Required && $s2 isa MXCL::Term::Trait::Slot::Defined;
        return $s1 if $s1 isa MXCL::Term::Trait::Slot::Excluded && $s2 isa MXCL::Term::Trait::Slot::Defined;
        if ($s1 isa MXCL::Term::Trait::Slot::Defined && $s2 isa MXCL::Term::Trait::Slot::Defined) {
            if ($s1->term->eq($s2->term)) {
                return $s1;
            } else {
                return $self->Conflict($s1, $s2);
            }
        }
        die "Cannot Merge Slots (".blessed($s1).") and (".blessed($s2).")";
    }

    method Compose ($t1, $t2) {

    }
}
