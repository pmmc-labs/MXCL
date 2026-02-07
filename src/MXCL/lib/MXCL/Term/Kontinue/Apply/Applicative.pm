
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Kontinue::Apply::Applicative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;
}
