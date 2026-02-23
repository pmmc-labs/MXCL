
use v5.42;
use experimental qw[ class ];

use MXCL::Internals;

class MXCL::Term::Cons :isa(MXCL::Term) {
    field $head :param :reader;
    field $tail :param :reader;

    method uncons {
        my @items;
        my $list = $self;
        until ($list isa MXCL::Term::Nil) {
            push @items => $list->head;
            $list = $list->tail;
        }
        return @items;
    }

    method stringify {
        sprintf '(%s %s)' => $head->stringify, $tail->stringify
    }

    method pprint {
        sprintf '(%s)' => join ' ' => map $_->pprint, $self->uncons;
    }

    method DECOMPOSE { (head => $head, tail => $tail) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ head tail ]}))
    }
}
