
use v5.42;
use experimental qw[ class ];

class MXCL::Parser::Token {
    field $source :param :reader;
    field $start  :param :reader = -1;
    field $end    :param :reader = -1;
    field $line   :param :reader = -1;
    field $pos    :param :reader = -1;

    method to_string { $source }
}
