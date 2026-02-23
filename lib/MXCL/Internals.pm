package MXCL::Internals;
use v5.42;

use Digest::MD5  ();
use Data::Dumper ();
use Carp         ();


sub hash_data (@data) {
    Digest::MD5::md5_hex(@data)
}

sub hash_fields ($type, @values) {
    Digest::MD5::md5_hex(join '' => $type, map {
        defined($_) || PANIC(\@values);
        blessed $_
            ? $_->isa('MXCL::Term')
                ? $_->hash
                : PANIC(\@values)
            : ref $_
                ? PANIC(\@values)
                : $_
    } @values)
}

sub PANIC ($data) {
    Carp::confess(Data::Dumper::Dumper($data))
}

__END__
