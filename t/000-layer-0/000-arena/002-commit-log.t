#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Context;

# --- use a fresh context for isolation ---

my $ctx   = MXCL::Context->new;
my $arena = $ctx->arena;
my $terms = $ctx->terms;

# --- fresh context has one commit ("context initialized") ---

is scalar @{$arena->commit_log}, 1,
    'fresh context has 1 commit after ADJUST';

my $init_commit = $arena->commit_log->[0];

is $init_commit->message, 'context initialized',
    'first commit message is "context initialized"';

ok !defined($init_commit->parent),
    'first commit has no parent';

# --- commit adds to the log ---

$arena->commit("test commit");

is scalar @{$arena->commit_log}, 2,
    'commit_log grows to 2 after first commit';

my $second_commit = $arena->commit_log->[-1];

is $second_commit->message, 'test commit',
    'second commit has the right message';

# --- parent linkage ---

is $second_commit->parent, $init_commit,
    'second commit parent is the first commit';

# --- another commit extends the chain ---

$arena->commit("third commit");

is scalar @{$arena->commit_log}, 3,
    'commit_log grows to 3 after second commit';

my $third_commit = $arena->commit_log->[-1];

is $third_commit->message, 'third commit',
    'third commit has the right message';

is $third_commit->parent, $second_commit,
    'third commit parent is the second commit';

is $third_commit->parent->parent, $init_commit,
    'grandparent of third commit is the first commit';

# --- changed terms are tracked per commit ---

my $num1 = $terms->Num(100);
my $num2 = $terms->Num(200);

$arena->commit("commit with terms");

my $terms_commit = $arena->commit_log->[-1];

ok scalar @{$terms_commit->changed} >= 2,
    'commit captures newly allocated terms in ->changed';

my %changed_hashes = map { $_->hash => 1 } @{$terms_commit->changed};

ok $changed_hashes{ $num1->hash },
    'Num(100) appears in commit->changed';

ok $changed_hashes{ $num2->hash },
    'Num(200) appears in commit->changed';

# --- reachable snapshot is empty when no roots given ---

is scalar @{$terms_commit->reachable}, 0,
    'commit without roots has empty reachable snapshot';

# --- commit with roots captures a reachable snapshot ---

my $r1   = $terms->Num(1);
my $r2   = $terms->Num(2);
my $list = $terms->List($r1, $r2);

$arena->commit("commit with roots", roots => [$list]);

my $rooted_commit = $arena->commit_log->[-1];

ok scalar @{$rooted_commit->reachable} >= 2,
    'commit with roots has a non-empty reachable snapshot';

my %reachable = map { $_->hash => 1 } @{$rooted_commit->reachable};

ok $reachable{ $r1->hash },
    'Num(1) appears in commit reachable snapshot';

ok $reachable{ $r2->hash },
    'Num(2) appears in commit reachable snapshot';

# --- bare arena starts empty ---

my $bare_arena = MXCL::Arena->new;

is scalar @{$bare_arena->commit_log}, 0,
    'bare Arena (no Context) starts with empty commit_log';

done_testing;
