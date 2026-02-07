
use v5.42;
use experimental qw[ class ];

use MXCL::Parser::Token;

class MXCL::Parser::Compound {
    field $items :param :reader = +[];

    field $open  :param = MXCL::Parser::Token->new(source => '(');
    field $close :param = MXCL::Parser::Token->new(source => ')');

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method push (@items) { push @$items => @items; $self }

    method to_string {
        sprintf 'Compound:%s %s %s' => $open->source, (join ', ' => map $_->to_string, @$items), $close->source
    }
}
