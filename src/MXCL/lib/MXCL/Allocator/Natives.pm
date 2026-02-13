
use v5.42;
use experimental qw[ class ];

use Sub::Util ();

use MXCL::Arena;

use MXCL::Term::Native::Applicative;
use MXCL::Term::Native::Operative;

class MXCL::Allocator::Natives {
    field $arena :param :reader;

    # FIXME : make the context accessible in the Native Applicables instead!
    field $terms :param :reader;

    # store the lifted, and orig-impls
    field $lifted :param :reader = +{};
    field $impls  :param :reader = +{};

    ## -------------------------------------------------------------------------
    ## Applicatives
    ## -------------------------------------------------------------------------
    ## {
    ##     name => 'add',
    ##     signature => [
    ##         { name => 'n', corece => 'numify' },
    ##         { name => 'm', corece => 'numify' },
    ##     ],
    ##     returns => 'Num',
    ##     impl    => sub ($n, $m) { $n + $m },
    ## }
    ##
    method Applicative (%binding) {
        my $name        = $binding{name};
        my @signature   = $binding{signature}->@*;
        my $returns     = $binding{returns};
        my $body        = $binding{impl};
        my @coercions   = map { $_->{coerce} } @signature; # TODO - $returns->can($_->{coerce}) would be better
        my $arity       = scalar @coercions;
        my $constructor = defined $returns
            ? ($terms->can( $returns ) || die "Cannot find ${returns} in Terms")
            # if $returns has not been defined, it means we
            # do not need to inflate, so we use this little
            # hack to make things work, probably should all
            # be re-thought, but this works for now.
            : sub ($, $result) { $result };

        my $bound = Sub::Util::set_subname(
            (sprintf 'applicative:%s' => $name),
            sub (@args) {
                die "ARITY MISMATCH in ${name} expected ${arity} and got ".scalar(@args)
                    if $arity != scalar @args;
                my @coerced;
                foreach my $coerce (@coercions) {
                    my $arg = shift @args;
                    if (not(defined $coerce)) {
                        push @coerced => $arg;
                    } else {
                        push @coerced => $arg->$coerce();
                    }
                }
                $constructor->( $terms, $body->( @coerced ) )
            }
        );

        my $applicative = $arena->allocate(MXCL::Term::Native::Applicative::,
            name    => $terms->Sym($name),
            params  => $terms->List( map { $terms->Sym($_->{name}) } @signature ),
            __body  => $bound,
        );

        my $hash = $applicative->hash;
        if (exists $impls->{ $hash }) {
            my $impl = $impls->{ $hash };
            if (refaddr $impl != refaddr $body) {
                die "BAD! DUPLICATE APPLICATIVE HASH for ${name} but different CODE refaddrs (${hash})";
            } else {
                warn "HMMM, DUPLICATE APPLICATIVE HASH for ${name} with same CODE refaddrs (${hash})";
            }
        } else {
            $lifted->{ $hash } = $bound;
            $impls ->{ $hash } = $body;
        }

        return $applicative;
    }

    ## -------------------------------------------------------------------------
    ## Operatives
    ## -------------------------------------------------------------------------
    ## Note the lack of a `returns` here, since these will always return
    ## Kontinue objects
    ## -------------------------------------------------------------------------
    ## {
    ##     name => 'add',
    ##     signature => [
    ##         { name => 'n' },
    ##         { name => 'm' },
    ##     ],
    ##     impl => sub ($n, $m) { $n + $m },
    ## }
    ##
    method Operative (%binding) {
        my $name      = $binding{name};
        my @signature = $binding{signature}->@*;
        my $body      = $binding{impl};
        my $arity     = scalar @signature;
        my $bound     = Sub::Util::set_subname(
            (sprintf 'operative:%s' => $name),
            sub ($ctx, @args) {
                die "ARITY MISMATCH in '${name}' expected ${arity} and got ".scalar(@args)
                    if $arity != scalar @args;
                return $body->( $ctx, @args );
            }
        );

        my $operative = $arena->allocate(MXCL::Term::Native::Operative::,
            name    => $terms->Sym($name),
            params  => $terms->List( map { $terms->Sym($_->{name}) } @signature ),
            __body  => $bound,
        );

        my $hash = $operative->hash;
        if (exists $impls->{ $hash }) {
            my $impl = $impls->{ $hash };
            if (refaddr $impl != refaddr $body) {
                die "BAD! DUPLICATE OPERATIVE HASH for ${name} but different CODE refaddrs (${hash})";
            } else {
                warn "HMMM, DUPLICATE OPERATIVE HASH for ${name} with same CODE refaddrs (${hash})";
            }
        } else {
            $lifted->{ $hash } = $bound;
            $impls ->{ $hash } = $body;
        }

        return $operative;
    }

}
