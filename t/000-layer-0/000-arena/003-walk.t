#!perl

use v5.42;
use experimental qw[ class ];

use Test::More;

use MXCL::Context;

my $ctx   = MXCL::Context->new;
my $arena = $ctx->arena;
my $terms = $ctx->terms;

# -----------------------------------------------------------------------
# children
# -----------------------------------------------------------------------

# --- leaf terms have no children ---

my $num = $terms->Num(42);
my $str = $terms->Str("hello");
my $nil = $terms->Nil;
my $sym = $terms->Sym("foo");

is scalar($num->children), 0, 'Num has no children';
is scalar($str->children), 0, 'Str has no children';
is scalar($nil->children), 0, 'Nil has no children';
is scalar($sym->children), 0, 'Sym has no children';

# --- Cons children are head and tail ---

my $cons = $terms->Cons($num, $nil);
my @cons_children = $cons->children;

is scalar @cons_children, 2, 'Cons has 2 children';
ok((grep { $_->eq($num) } @cons_children), 'Cons children includes head');
ok((grep { $_->eq($nil) } @cons_children), 'Cons children includes tail');

# --- Array children are its elements ---

my $arr = $terms->Array($num, $str, $nil);
my @arr_children = $arr->children;

is scalar @arr_children, 3, 'Array has 3 children';
ok((grep { $_->eq($num) } @arr_children), 'Array children includes Num');
ok((grep { $_->eq($str) } @arr_children), 'Array children includes Str');
ok((grep { $_->eq($nil) } @arr_children), 'Array children includes Nil');

# -----------------------------------------------------------------------
# walk
# -----------------------------------------------------------------------

# --- walk visits every committed term exactly once ---

my $n1 = $terms->Num(100);
my $n2 = $terms->Num(200);

$arena->commit("walk test commit");

my %visited_hashes;
my @commit_messages;

$arena->walk(sub ($commit, $term) {
    $visited_hashes{ $term->hash }++;
    push @commit_messages, $commit->message unless @commit_messages && $commit_messages[-1] eq $commit->message;
});

ok $visited_hashes{ $n1->hash },
    'walk visits Num(100)';

ok $visited_hashes{ $n2->hash },
    'walk visits Num(200)';

ok scalar @commit_messages >= 2,
    'walk visits terms from multiple commits';

# --- no term appears more than once ---

my $max_visits = (sort { $b <=> $a } values %visited_hashes)[0];
is $max_visits, 1, 'walk visits each term exactly once';

# -----------------------------------------------------------------------
# reachable_from
# -----------------------------------------------------------------------

# --- build a list: Cons(1, Cons(2, Cons(3, Nil))) ---

my $r1   = $terms->Num(1);
my $r2   = $terms->Num(2);
my $r3   = $terms->Num(3);
my $list = $terms->List($r1, $r2, $r3);

my $isolated = $terms->Num(999);

my %reachable = map { $_->hash => 1 } $arena->reachable_from($list);

ok $reachable{ $list->hash }, 'root term itself is reachable';
ok $reachable{ $r1->hash  }, 'Num(1) is reachable from list';
ok $reachable{ $r2->hash  }, 'Num(2) is reachable from list';
ok $reachable{ $r3->hash  }, 'Num(3) is reachable from list';
ok $reachable{ $nil->hash }, 'Nil (list terminator) is reachable from list';

ok !$reachable{ $isolated->hash },
    'Num(999) is not reachable from list';

# --- multiple roots ---

my $extra = $terms->Str("extra");
my %multi = map { $_->hash => 1 } $arena->reachable_from($list, $extra);

ok $multi{ $r1->hash    }, 'Num(1) reachable with multiple roots';
ok $multi{ $extra->hash }, 'Str("extra") reachable as second root';

# -----------------------------------------------------------------------
# dropped_between
# -----------------------------------------------------------------------

# --- terms reachable in commit A but not in commit B are "dropped" ---

my $a = $terms->Num(10);
my $b = $terms->Num(20);
my $c = $terms->Num(30);

my $long_list  = $terms->List($a, $b, $c);
my $short_list = $terms->List($a);

$arena->commit("snap A", roots => [$long_list]);
my $snap_a = $arena->commit_log->[-1];

$arena->commit("snap B", roots => [$short_list]);
my $snap_b = $arena->commit_log->[-1];

my @dropped      = $arena->dropped_between($snap_a, $snap_b);
my %dropped_hash = map { $_->hash => 1 } @dropped;

ok  $dropped_hash{ $b->hash }, 'Num(20) dropped between snapshots';
ok  $dropped_hash{ $c->hash }, 'Num(30) dropped between snapshots';
ok !$dropped_hash{ $a->hash }, 'Num(10) not dropped (still reachable in B)';

done_testing;
