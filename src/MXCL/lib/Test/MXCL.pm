
use v5.42;
use experimental qw[ class ];

package Test::MXCL;

use Exporter 'import';
our @EXPORT_OK = qw[
    ctx
    arena
    terms
    roles
    compiler
    parser
];

use MXCL::Context;

my $CTX;

sub ctx      { $CTX //= MXCL::Context->new }
sub arena    { ctx->arena }
sub terms    { ctx->terms }
sub roles    { ctx->roles }
sub compiler { ctx->compiler }
sub parser   { ctx->parser }

1;
