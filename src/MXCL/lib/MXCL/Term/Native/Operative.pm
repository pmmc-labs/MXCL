
use v5.42;
use experimental qw[ class ];

class MXCL::Term::Native::Operative :isa(MXCL::Term) {
    field $name    :param :reader;
    field $params  :param :reader;
    field $__body  :param :reader(body);

    method stringify {
        sprintf 'native:applicative[%s](%s)' =>
            $name->stringify,
            join ', ' => map $_->stringify, $params->uncons
        ;
    }

    method pprint { $name }
}
