
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Role;
use MXCL::Term::Role::Slot;

class MXCL::Allocator::Roles {
    field $arena :param :reader;

    ## -------------------------------------------------------------------------
    ## Roles
    ## -------------------------------------------------------------------------

    method Role (@slots) {
        my %index = map { $_->ident, undef } @slots;
        die "Duplicated slots in the role, WTF DUDE" if scalar(keys %index) != scalar @slots;
        $arena->allocate(MXCL::Term::Role::, slots => \@slots );
    }

    ## -------------------------------------------------------------------------
    ## Slots
    ## -------------------------------------------------------------------------

    method Defined  ($ident, $value) {
        $arena->allocate(MXCL::Term::Role::Slot::Defined::, ident => $ident, value => $value )
    }

    method Required ($ident) {
        $arena->allocate(MXCL::Term::Role::Slot::Required::, ident => $ident )
    }

    method Conflict ($lhs, $rhs)  {
        $arena->allocate(MXCL::Term::Role::Slot::Conflict::, lhs => $lhs, rhs => $rhs )
    }

    ## -------------------------------------------------------------------------
    ## Merging Slots
    ## -------------------------------------------------------------------------

    method MergeSlot ($s1, $s2) {
        return $s1 if not defined $s2;
        return $s2 if not defined $s1;
        return $s1 if $s1 isa MXCL::Term::Role::Slot::Required && $s2 isa MXCL::Term::Role::Slot::Required;
        return $s1 if $s1 isa MXCL::Term::Role::Slot::Defined  && $s2 isa MXCL::Term::Role::Slot::Required;
        return $s2 if $s1 isa MXCL::Term::Role::Slot::Required && $s2 isa MXCL::Term::Role::Slot::Defined;
        if ($s1 isa MXCL::Term::Role::Slot::Defined && $s2 isa MXCL::Term::Role::Slot::Defined) {
            if ($s1->eq( $s2 )) {
                return $s1;
            } else {
                return $self->Conflict( $s1, $s2 );
            }
        }
        die "Cannot Merge Slots (".(blessed($s1) // '???').") and (".(blessed($s2) // '???').")";
    }

    method MergeSlots (@slots) {
        my %seen;
        foreach my $slot (@slots) {
            if (exists $seen{ $slot->ident->value }) {
                $seen{ $slot->ident->value } = $self->MergeSlot( $seen{ $slot->ident->value }, $slot );
            } else {
                $seen{ $slot->ident->value } = $slot;
            }
        }
        return values %seen;
    }

    ## -------------------------------------------------------------------------
    ## Merging Roles
    ## -------------------------------------------------------------------------

    # all items from both left and right (de-duplicated)
    method Union ($lhs, $rhs) {
        $self->Role( $self->MergeSlots( $lhs->slots->@*, $rhs->slots->@* ) );
    }

    # items in the left that don't exist on the right
    method Difference ($lhs, $rhs) {
        $self->Role( grep { not $rhs->contains($_) } $lhs->slots->@* )
    }

    # items in the right that don't exist on the left
    method Intersection ($lhs, $rhs) {
        $self->Role( grep { $lhs->contains($_) } $rhs->slots->@* )
    }

    # items which only exist in one set or the other, but not both
    method SymmetricDifference ($lhs, $rhs) {
        $self->Role(
            grep {
                not( $lhs->contains( $_ ) && $rhs->contains( $_ ) )
            } ($lhs->slots->@*, $rhs->slots->@*)
        )
    }

    method AsymmetricDifference ($lhs, $rhs) {
        $self->Role(
            $self->MergeSlots(
                grep {
                    $lhs->contains( $_ ) || $rhs->contains( $_ )
                } ($lhs->slots->@*, $rhs->slots->@*)
            )
        )
    }

}
