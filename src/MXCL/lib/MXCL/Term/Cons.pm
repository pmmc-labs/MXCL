
use v5.42;
use experimental qw[ class ];

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

    method to_string {
        sprintf '(%s %s)' => $head->to_string, $tail->to_string
    }

    method pprint {
        sprintf '(%s)' => join ' ' => map $_->pprint, $self->uncons;
    }
}
