
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Parser::Token :isa(MXCL::Term) {
    field $source :param :reader;
    field $start  :param :reader = -1;
    field $end    :param :reader = -1;
    field $line   :param :reader = -1;
    field $pos    :param :reader = -1;

    method stringify { $source }

    method pprint { $self->stringify }
}
