
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

use MXCL::Context::CodeGenerator;

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
    field $generator :reader;

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
        $generator = MXCL::Context::CodeGenerator->new( context => $self );
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

        $tape->splice(
            $generator->create_tape(
                $scopes[-1],
                $runtime->prelude->artifact
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

        # Splice in the IO module ...
        $tape->splice(
            $generator->create_tape( $scopes[-1], $IO->artifact )
        );

        push @scopes => $machine->run( $self )->env;
        $modules{'IO'} = $IO;

        ## Load the Test module ...

        my $Test = MXCL::Runtime::Core::Test->new->initialize($self);

        # Splice in the Test module ...
        $tape->splice(
            $generator->create_tape( $scopes[-1], $Test->artifact )
        );

        push @scopes => $machine->run( $self )->env;
        $modules{'Test'} = $Test;

        ## ------------------------------------------------
        ## Insert the context ref into the env
        ## ------------------------------------------------

        push @scopes => $roles->Union(
            $roles->Role(
                $roles->Defined(
                    $terms->Sym('^CTX'),
                    $terms->ContextRef($self)
                ),
            ),
            $scopes[-1]
        );

        ## ------------------------------------------------
        ## All initialized!
        ## ------------------------------------------------

        $initialized = true;
        return $self;
    }

    method current_scope { $tape->peek->env }

    method prelude_scope { $scopes[1] }

    method base_scope { $scopes[-1] }

    method compile_source ($source) {
        my $exprs = $compiler->compile( $source );
        return $exprs;
    }

    method evaluate ($env, $exprs, %opts) {
        $tape->splice( $generator->create_tape( $env, $exprs ) );
        return $machine->run( $self );
    }
}
