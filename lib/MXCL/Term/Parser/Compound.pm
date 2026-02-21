
use v5.42;
use experimental qw[ class ];

use MXCL::Term::Parser::Token;

class MXCL::Term::Parser::Compound {
    field $items :param :reader = +[];

    field $open  :param = MXCL::Term::Parser::Token->new(source => '(');
    field $close :param = MXCL::Term::Parser::Token->new(source => ')');

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method push (@items) { push @$items => @items; $self }

    method stringify {
        sprintf 'Compound:%s %s %s' => $open->source, (join ', ' => map $_->stringify, @$items), $close->source
    }
}
