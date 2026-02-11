
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

    method Trait (%bindings) {
        $arena->allocate(MXCL::Term::Trait::, bindings => \%bindings);
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

    method BindParams ($parent, $params, $args) {
        die "Arity mismatch" if scalar @$params != scalar @$args;
        my %bindings = map {
            $_->value,
            $self->Defined(shift @$args)
        } @$params;

        my $local    = $self->Trait( %bindings );
        my $composed = $self->Compose( $parent, $local );

        # TODO - check for conflicts!

        return $composed;
    }


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
        die "Cannot Merge Slots (".(blessed($s1) // '???').") and (".(blessed($s2) // '???').")";
    }

    method Compose ($t1, $t2) {
        my $t1_bindings = $t1->bindings;
        my $t2_bindings = $t2->bindings;

        my %merged   = ($t1_bindings->%*, $t2_bindings->%*);
        my @all_keys = keys %merged;

        #say "      t1: ", join ', ' => keys $t1_bindings->%*;
        #say "      t2: ", join ', ' => keys $t2_bindings->%*;
        #say "ALL KEYS: ", join ', ' => @all_keys;

        my %bindings;
        foreach my $key (@all_keys) {
            if (exists $t1_bindings->{$key} && exists $t2_bindings->{$key}) {
                $bindings{ $key } = $self->MergeSlots( $t1_bindings->{$key}, $t2_bindings->{$key} );
            }
            elsif (exists $t1_bindings->{$key} && !(exists $t2_bindings->{$key})) {
                $bindings{ $key } = $t1_bindings->{$key};
            }
            elsif (exists $t2_bindings->{$key} && !(exists $t1_bindings->{$key})) {
                $bindings{ $key } = $t2_bindings->{$key};
            }
            else {
                die "WTF, this can't happen!";
            }
        }

        return $self->Trait(%bindings);
     }
}
