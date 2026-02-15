#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Context;

# --- use a fresh context for isolation ---

my $ctx   = MXCL::Context->new;
my $arena = $ctx->arena;
my $terms = $ctx->terms;

# --- fresh context starts at gen 1 (context ADJUST commits "context initialized") ---

is $arena->current_gen, 1,
    'fresh context has current_gen == 1 after ADJUST commit';

# --- terms allocated after context init have gen == 1 ---

my $num1 = $terms->Num(100);

is $num1->gen, 1,
    'term allocated after context init has gen == 1 (current gen)';

# --- commit_generation increments current_gen ---

$arena->commit_generation("test commit");

is $arena->current_gen, 2,
    'current_gen increments to 2 after commit';

# --- term allocated after commit has higher gen ---

my $num2 = $terms->Num(200);

is $num2->gen, 2,
    'term allocated after commit has gen == 2';

# previously allocated term retains its original gen
is $num1->gen, 1,
    'previously allocated term retains gen == 1';

# --- generations array grows with each commit ---

my $gens = $arena->generations;

is scalar @$gens, 2,
    'generations array has 2 entries (init + test commit)';

is $gens->[0]{label}, 'context initialized',
    'first generation label is "context initialized"';

is $gens->[1]{label}, 'test commit',
    'second generation label is "test commit"';

# --- another commit grows the array further ---

$arena->commit_generation("second test commit");

is $arena->current_gen, 3,
    'current_gen increments to 3 after another commit';

is scalar @{$arena->generations}, 3,
    'generations array has 3 entries now';

is $arena->generations->[2]{label}, 'second test commit',
    'third generation label is correct';

# --- bare arena starts at gen 0 ---

my $bare_arena = MXCL::Arena->new;

is $bare_arena->current_gen, 0,
    'bare Arena (no Context) starts at current_gen == 0';

is scalar @{$bare_arena->generations}, 0,
    'bare Arena has empty generations array';

done_testing;
