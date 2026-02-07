
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Apply::Operative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;
}
