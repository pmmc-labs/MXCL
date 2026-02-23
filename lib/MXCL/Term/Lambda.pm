
use v5.42;
use experimental qw[ class switch ];

use MXCL::Internals;

class MXCL::Term::Lambda :isa(MXCL::Term) {
    field $name   :param :reader;
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method free_variables {
        my @params = $params->uncons;
        my @free;
        my sub traverse ($t, $f) {
            given (blessed $t) {
                when ('MXCL::Term::Cons') {
                    $f->($t->head, $f);
                    $f->($t->tail, $f);
                }
                when ('MXCL::Term::Sym') {
                    if (0 == scalar grep { $_->eq($t) } @params) {
                        push @free => $t;
                    }
                }
            }
        }
        traverse($body, \&traverse);
        return @free;
    }

    method stringify {
        sprintf '(/lambda [%s] %s %s)' => $name->stringify, $params->stringify, $body->stringify
    }

    method pprint {
        sprintf '(lambda %s %s)' => $params->pprint, $body->pprint
    }

    method DECOMPOSE { (body => $body, env => $env, name => $name, params => $params) }

    sub COMPOSE {
        my ($class, %args) = @_;
        return (%args, hash => MXCL::Internals::hash_fields($class, @args{qw[ body env name params ]}))
    }
}
