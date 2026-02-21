package MXCL::Internals;
use v5.42;

use Digest::MD5  ();
use Data::Dumper ();
use Carp         ();


sub hash_data (@data) {
    Digest::MD5::md5_hex(@data)
}

sub PANIC ($data) {
    Carp::confess(Data::Dumper::Dumper($data))
}

__END__
