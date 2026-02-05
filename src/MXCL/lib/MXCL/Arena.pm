
use v5.42;
use experimental qw[ class ];

use Digest::MD5 ();

use MXCL::Term;

use MXCL::Term::Nil;
use MXCL::Term::Cons;

use MXCL::Term::Bool;
use MXCL::Term::Num;
use MXCL::Term::Str;
use MXCL::Term::Tag;

use MXCL::Term::Sym;
use MXCL::Term::Env;

use MXCL::Term::Lambda;
use MXCL::Term::Opaque;

use MXCL::Term::Native::Applicative;
use MXCL::Term::Native::Operative;

class MXCL::Arena {

    my sub construct_hash ($inv, @values) {
        my $type = blessed $inv // $inv;

        if (scalar @values == 1 && ref $values[0] && reftype $values[0] eq 'HASH') {
            my $hashref = shift @values;
            @values = map { $_, $hashref->{$_} } sort { $a cmp $b } keys %$hashref;
        }

        return Digest::MD5::md5_hex( $type, map { blessed $_ ? $_->hash : $_ } @values );
    }

    field $nil   = MXCL::Term::Nil->new(  hash => construct_hash(MXCL::Term::Nil::,  '#N') );
    field $true  = MXCL::Term::Bool->new( hash => construct_hash(MXCL::Term::Bool::, '#T'), value => true );
    field $false = MXCL::Term::Bool->new( hash => construct_hash(MXCL::Term::Bool::, '#F'), value => false );

    field $terms :reader = +{};

    method Nil   { $nil   }
    method True  { $true  }
    method False { $false }

    method Num ($value) {
        my $hash = construct_hash(MXCL::Term::Num::, $value);
        $terms->{ $hash } //= MXCL::Term::Num->new( hash => $hash, value => $value );
    }

    method Str ($value) {
        my $hash = construct_hash(MXCL::Term::Str::, $value);
        $terms->{ $hash } //= MXCL::Term::Str->new( hash => $hash, value => $value );
    }

    method Sym ($value) {
        my $hash = construct_hash(MXCL::Term::Sym::, $value);
        $terms->{ $hash } //= MXCL::Term::Sym->new( hash => $hash, value => $value );
    }

    method Tag ($value) {
        my $hash = construct_hash(MXCL::Term::Tag::, $value);
        $terms->{ $hash } //= MXCL::Term::Tag->new( hash => $hash, value => $value );
    }

    method Cons ($head, $tail) {
        my $hash = construct_hash(MXCL::Term::Cons::, $head, $tail);
        $terms->{ $hash } //= MXCL::Term::Cons->new(
            hash => $hash,
            head => $head,
            tail => $tail
        );
    }

    method Env (%bindings) {
        my $hash = construct_hash(MXCL::Term::Env::, \%bindings );
        $terms->{ $hash } //= MXCL::Term::Env->new(
            hash     => $hash,
            bindings => \%bindings
        );
    }

    method Lambda ($params, $body, $env) {
        my $hash = construct_hash(MXCL::Term::Lambda::, $params, $body, $env );
        $terms->{ $hash } //= MXCL::Term::Lambda->new(
            hash   => $hash,
            params => $params,
            body   => $body,
            env    => $env
        );
    }

    method Opaque ($env) {
        my $hash = construct_hash(MXCL::Term::Opaque::, $env );
        $terms->{ $hash } //= MXCL::Term::Opaque->new(
            hash => $hash,
            env  => $env,
        );
    }

    method NativeApplicative ($params, $body) {
        my $hash = construct_hash(MXCL::Term::Native::Applicative::, $params, refaddr $body );
        $terms->{ $hash } //= MXCL::Term::Native::Applicative->new(
            hash   => $hash,
            params => $params,
            body   => $body,
        );
    }

    method NativeOperative ($params, $body) {
        my $hash = construct_hash(MXCL::Term::Native::Operative::, $params, refaddr $body );
        $terms->{ $hash } //= MXCL::Term::Native::Operative->new(
            hash   => $hash,
            params => $params,
            body   => $body,
        );
    }

}
