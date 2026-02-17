
use v5.42;
use experimental qw[ class switch ];

class Roles::Tools::Set {
    field $items :param :reader = +[];
    field %index;

    ADJUST {
        $items->@* = grep {
            exists $index{ $_->hash }
                ? false
                : ($index{ $_->hash } = $_)
        } $items->@*;
    }

    method is_empty { scalar @$items == 0 }

    method size { scalar keys %index }

    method contains (@items) {
        foreach my $item (@items) {
            return false unless $index{ $item->hash };
        }
        return true;
    }

    method is_subset        ($other) { $other->contains( @$items ) }
    method is_proper_subset ($other) {
        $self->size < $other->size
            && $self->is_subset( $other )
    }

    method is_superset        ($other) { $other->is_subset( $self ) }
    method is_proper_superset ($other) {
        $self->size > $other->size
            && $other->is_subset( $self )
    }

    method is_equal ($other) {
        $other->is_subset( $self ) && $self->is_subset( $other )
    }

    method is_disjoint ($other) { !$self->intersection( $other )->size }

    method is_properly_intersecting ($other) {
        !$self->is_disjoint( $other )
            && $self->difference( $other )->size
                && $other->difference( $self )->size;
    }

    method difference ($other) {
        return __CLASS__->new(
            items => [ grep { not $other->contains($_) } $items->@* ]
        );
    }

    method union ($other) {
        return __CLASS__->new( items => [ @$items, $other->items->@* ] );
    }

    method intersection ($other) {
        return __CLASS__->new(
            items => [ grep { exists $index{ $_->hash } } $other->items->@* ]
        );
    }

    method symmetric_difference ($other) {
        my @set;
        foreach my $item (@$items, $other->items->@*) {
            unless (exists $index{ $item->hash } && $other->contains( $item )) {
                push @set => $item;
            }
        }
        return __CLASS__->new( items => \@set );
    }

    method to_string {
        sprintf '(%s)' => join ' ' => map $_->to_string, @$items
    }
}

