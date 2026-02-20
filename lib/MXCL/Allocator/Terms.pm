
use v5.42;
use experimental qw[ class ];

use Sub::Util ();

use MXCL::Arena;

use MXCL::Term;

use MXCL::Term::Nil;
use MXCL::Term::Cons;

use MXCL::Term::Bool;
use MXCL::Term::Num;
use MXCL::Term::Str;
use MXCL::Term::Tag;
use MXCL::Term::Sym;

use MXCL::Term::Array;
use MXCL::Term::Hash;

use MXCL::Term::Lambda;

use MXCL::Term::Opaque;
use MXCL::Term::Ref;

use MXCL::Term::Native::Applicative;
use MXCL::Term::Native::Operative;

class MXCL::Allocator::Terms {
    field $arena :param :reader;

    # store the singletons
    field $nil;
    field $true;
    field $false;

    # store the refs
    field $refs  :param :reader = +{};
    # store the lifted, and orig-impls
    field $lifted :param :reader = +{};
    field $impls  :param :reader = +{};

    # intialize ...
    ADJUST {
        $nil   = $arena->allocate(MXCL::Term::Nil::);
        $true  = $arena->allocate(MXCL::Term::Bool::, value => true);
        $false = $arena->allocate(MXCL::Term::Bool::, value => false);
    }

    method Nil   { $nil }
    method True  { $true }
    method False { $false }

    method Bool ($value) { $value ? $true : $false }

    method Num ($value) { $arena->allocate(MXCL::Term::Num::, value => $value) }
    method Str ($value) { $arena->allocate(MXCL::Term::Str::, value => $value) }
    method Sym ($value) { $arena->allocate(MXCL::Term::Sym::, value => $value) }
    method Tag ($value) { $arena->allocate(MXCL::Term::Tag::, value => $value) }

    method Cons ($head, $tail) {
        $arena->allocate(MXCL::Term::Cons::, head => $head, tail => $tail )
    }

    method Lambda ($params, $body, $env, $name=undef) {
        $name //= $self->Sym('__SUB__');
        $arena->allocate(MXCL::Term::Lambda::, name => $name, params => $params, body => $body, env => $env )
    }

    method Array (@elements) {
        $arena->allocate(MXCL::Term::Array::, elements => \@elements )
    }

    method Hash (%elements) {
        $arena->allocate(MXCL::Term::Hash::, elements => \%elements )
    }

    ## -------------------------------------------------------------------------
    ## Opaques (hashed by identity)
    ## -------------------------------------------------------------------------

    method Opaque ($role) {
        state $nonce = 0;
        my $uid = ++$nonce; # unique object identity
        $arena->allocate(MXCL::Term::Opaque::,
            uid  => $uid,
            repr => $nil, # TODO: remove me (probably)
            role => $role,
        );
    }

    ## -------------------------------------------------------------------------
    ## Refs (hashed by identity)
    ## -------------------------------------------------------------------------

    method Ref ($value) {
        state $nonce = 0;
        my $uid = sprintf 'ref:%s:%d' => blessed $value, ++$nonce; # unique ref identity
        $refs->{ $uid } = $value;
        return $arena->allocate(MXCL::Term::Ref::, uid => $uid );
    }

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
        my $body        = $binding{impl};
        my $returns     = $binding{returns};
        my $constructor = defined $returns
            ? ($returns eq 'Nil'
                ? sub (@) { $nil }
                : ($self->can( $returns ) || die "Cannot find ${returns} in Terms"))
            # if $returns has not been defined, it means we
            # do not need to inflate, so we use this little
            # hack to make things work, probably should all
            # be re-thought, but this works for now.
            : sub ($, $result) { $result };

        my $bound;
        if (scalar @signature == 1 && $signature[0]->{name} eq '@') {
            my $coerce = $signature[0]->{coerce};
            $bound = Sub::Util::set_subname(
                (sprintf 'applicative:%s' => $name),
                sub (@args) {
                    if ($coerce) {
                        @args = map { $_->$coerce() } @args
                    }
                    $constructor->( $self, $body->( @args ) );
                }
            );
        } else {
            my @coercions = map { $_->{coerce} } @signature; # TODO - $returns->can($_->{coerce}) would be better
            my $arity     = scalar @coercions;

            $bound = Sub::Util::set_subname(
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
                    $constructor->( $self, $body->( @coerced ) )
                }
            );
        }

        my $applicative = $arena->allocate(MXCL::Term::Native::Applicative::,
            name    => $self->Sym($name),
            params  => $self->List( map { $self->Sym($_->{name}) } @signature ),
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

        my $bound;
        if (scalar @signature == 1 && $signature[0]->{name} eq '@') {
            # XXX - this could use some improvement
            $bound = Sub::Util::set_subname(
                (sprintf 'operative:%s' => $name),
                sub ($ctx, @args) {
                    return $body->( $ctx, @args );
                }
            )
        } else {
            my $arity = scalar @signature;
            $bound = Sub::Util::set_subname(
                (sprintf 'operative:%s' => $name),
                sub ($ctx, @args) {
                    die "ARITY MISMATCH in '${name}' expected ${arity} and got ".scalar(@args)
                        if $arity != scalar @args;
                    return $body->( $ctx, @args );
                }
            );
        }

        my $operative = $arena->allocate(MXCL::Term::Native::Operative::,
            name    => $self->Sym($name),
            params  => $self->List( map { $self->Sym($_->{name}) } @signature ),
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

    ## -------------------------------------------------------------------------
    ## Ref Utils
    ## -------------------------------------------------------------------------

    method Deref ($ref) {
        return $refs->{ $ref->uid }
    }

    method SetRef ($ref, $value) {
        $refs->{ $ref->uid } = $value;
        $ref;
    }

    ## -------------------------------------------------------------------------
    ## List Utils
    ## -------------------------------------------------------------------------

    method List (@items) {
        my $list = $nil;
        foreach my $item (reverse @items) {
            $list = $self->Cons( $item, $list );
        }
        return $list;
    }

    method Uncons ($list) {
        my @items;
        until ($list isa MXCL::Term::Nil) {
            push @items => $list->head;
            $list = $list->tail;
        }
        return @items;
    }

    method Append ($first, $second) {
        $self->List( $self->Uncons($first), $self->Uncons($second) )
    }

}
