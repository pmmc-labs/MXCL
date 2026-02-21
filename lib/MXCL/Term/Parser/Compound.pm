
use v5.42;
use experimental qw[ class ];

use MXCL::Term::Parser::Token;

class MXCL::Term::Parser::Compound :isa(MXCL::Term) {
    field $items :param;

    method open  { $items->[0] }
    method close { $items->[-1] }

    method items {
        my @items = @$items;
        shift @items;
        pop @items;
        return \@items;
    }

    method stringify {
        sprintf 'Compound:%s' => (join ', ' => map $_->stringify, @$items)
    }

    method pprint { $self->stringify }
}
