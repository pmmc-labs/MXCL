
use v5.42;
use experimental qw[ class ];

use MXCL::Arena;

use MXCL::Term::Parser::Token;
use MXCL::Term::Parser::Compound;

class MXCL::Allocator::Sources {
    field $arena :param :reader;

    method Token (%args) {
        $arena->allocate(MXCL::Term::Parser::Token::, %args);
    }

    method Compound (@items) {
        $arena->allocate(MXCL::Term::Parser::Compound::, items => \@items);
    }

}
