
use v5.42;
use experimental qw[ class switch ];

use MXCL::Arena;
use MXCL::Parser;
use MXCL::Compiler;
use MXCL::Machine;
use MXCL::Runtime;

use MXCL::Runtime::Core::IO;
use MXCL::Runtime::Core::Test;

use MXCL::Allocator::Terms;
use MXCL::Allocator::Roles;
use MXCL::Allocator::Kontinues;

use MXCL::Tape;
use MXCL::Tape::Spliced;

use MXCL::Debugger;

class MXCL::Context {
    field $arena     :reader;

    field $terms     :reader;
    field $roles     :reader;
    field $kontinues :reader;

    field $parser    :reader;
    field $compiler  :reader;
    field $machine   :reader;
    field $runtime   :reader;
    field $tape      :reader;

    field @scopes;
    field %channels;
    field $initialized = false;

    field %modules;

    ADJUST {
        $arena     = MXCL::Arena->new;
        $terms     = MXCL::Allocator::Terms->new( arena => $arena );
        $roles     = MXCL::Allocator::Roles->new( arena => $arena );
        $kontinues = MXCL::Allocator::Kontinues->new( arena => $arena );

        $parser    = MXCL::Parser->new;
        $compiler  = MXCL::Compiler->new( parser => $parser, alloc => $terms );
        $runtime   = MXCL::Runtime->new;
        $machine   = MXCL::Machine->new;
        $tape      = MXCL::Tape::Spliced->new;
    }

    method initialize (%options) {
        return if $initialized;

        ## ------------------------------------------------
        ## Initialize the base runtime ...
        ## ------------------------------------------------

        $runtime->initialize( $self );

        push @scopes => $runtime->base_scope;

        ## ------------------------------------------------
        ## Run the Prelude
        ## ------------------------------------------------

        my $prelude = $runtime->prelude->artifact;

        # Splice in the prelude ...
        $tape->splice(
            MXCL::Tape->new( exprs => $prelude )->enqueue(
                $kontinues->Host($scopes[-1], 'HALT', +{}, $terms->Nil),
                reverse map {
                    $kontinues->Discard($scopes[-1], $terms->Nil),
                    $kontinues->EvalExpr($scopes[-1], $_, $terms->Nil)
                } @$prelude
            )
        );

        push @scopes => $machine->run( $self )->env;

        ## ------------------------------------------------
        ## Load in the I/O
        ## ------------------------------------------------

        my $std_in  = $terms->Channel();
        my $std_out = $terms->Channel();
        my $std_err = $terms->Channel();

        # NOTE:
        # When we have proper effects, then these will change
        # somewhat and become non-blocking, but we can worry
        # about that when we get to it. For now this is here
        # to make things easier, we can improve it later.

        $std_in->on_read = sub ($ch) {
            my $value = <>;
            $ch->buffer_read($terms->Str( $value ));
            return;
        };

        $std_out->on_write = sub ($ch) {
            print map $_->stringify, $ch->buffer_drain;
            return;
        };

        $std_err->on_write = sub ($ch) {
            warn((map $_->stringify, $ch->buffer_drain), "\n");
            return;
        };

        push @scopes => $roles->Union(
            $roles->Role(
                $roles->Defined($terms->Sym('^STDIN'),  $std_in),
                $roles->Defined($terms->Sym('^STDOUT'), $std_out),
                $roles->Defined($terms->Sym('^STDERR'), $std_err),
            ),
            $scopes[-1]
        );

        ## ------------------------------------------------
        ## Prepare the tape to run programs ...
        ## ------------------------------------------------

        my $IO = MXCL::Runtime::Core::IO->new->initialize($self);
        my $IO_module = $IO->artifact;

        # Splice in the IO module ...
        $tape->splice(
            MXCL::Tape->new( exprs => $IO_module )->enqueue(
                $kontinues->Discard($scopes[-1], $terms->Nil),
                reverse map {
                    $kontinues->Discard($scopes[-1], $terms->Nil),
                    $kontinues->EvalExpr($scopes[-1], $_, $terms->Nil)
                } @$IO_module
            )
        );

        my $Test = MXCL::Runtime::Core::Test->new->initialize($self);
        my $Test_module = $Test->artifact;

        # Splice in the Test module ...
        $tape->splice(
            MXCL::Tape->new( exprs => $Test_module )->enqueue(
                $kontinues->Discard($scopes[-1], $terms->Nil),
                reverse map {
                    $kontinues->Discard($scopes[-1], $terms->Nil),
                    $kontinues->EvalExpr($scopes[-1], $_, $terms->Nil)
                } @$Test_module
            )
        );


        $modules{'IO'}   = $IO;
        $modules{'Test'} = $Test;

        ## ------------------------------------------------
        ## All initialized!
        ## ------------------------------------------------

        $initialized = true;
        return $self;
    }

    method prelude_scope { $scopes[1] }

    method base_scope { $scopes[-1] }

    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        return $exprs;
    }

    method evaluate ($env, $exprs, %opts) {
        # Splice in the program ...
        $tape->splice(
            MXCL::Tape->new( exprs => $exprs )->enqueue(
                $kontinues->Host($env, 'HALT', +{}, $terms->Nil),
                reverse map {
                    $kontinues->Discard($env, $terms->Nil),
                    $kontinues->EvalExpr($env, $_, $terms->Nil)
                } @$exprs
            )
        );

        my $result = $machine->run( $self );

        return $result;
    }
}
