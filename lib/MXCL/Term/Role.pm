
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

use MXCL::Term::Role::Slot;

class MXCL::Term::Role :isa(MXCL::Term) {
    field $slots :param :reader = +[];

    field %index;
    field %hashes;

    ADJUST {
        %index  = map { $_->ident->value, $_ } $slots->@*;
        %hashes = map { $_->hash, $_ } $slots->@*;
    }

    # --------------------------------------------------------------------------

    method is_empty { scalar @$slots == 0 }
    method size     { scalar @$slots }

    method contains (@slots) {
        foreach my $slot (@slots) {
            return false unless $hashes{ $slot->hash };
        }
        return true;
    }

    method lookup ($ident) { $index{ $ident } }

    # --------------------------------------------------------------------------

    method is_subset   ($other) { $other->contains( @$slots ) }
    method is_superset ($other) { $other->is_subset( $self ) }
    method is_equal    ($other) { $other->is_subset( $self ) && $self->is_subset( $other ) }
    method is_disjoint ($other) { !$self->intersection( $other )->size }

    # --------------------------------------------------------------------------

    method stringify {
        sprintf "(role<%s> %s)" => substr($self->hash, 0, 8), join ' ' => map { sprintf '%s[%s]' => $_->ident->pprint, $_->kind } @$slots
    }

    method pprint {
        return $self->stringify;
        #sprintf "(role\n  -%s)" => join "\n  -" => map $_->pprint, @$slots
    }

    method DECOMPOSE { (slots => $slots) }

    sub COMPOSE ($class, %args) {
        return (%args, hash => MXCL::Internals::hash_fields($class, @{$args{slots}}))
    }
}
