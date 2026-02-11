#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use MXCL::Arena;
use MXCL::Allocator::Terms;
use MXCL::Allocator::Environments;
use MXCL::Allocator::Kontinues;
use MXCL::Allocator::Traits;

my $arena  = MXCL::Arena->new;
my $terms  = MXCL::Allocator::Terms->new( arena => $arena );
my $traits = MXCL::Allocator::Traits->new( arena => $arena );

my $t100  = $terms->Num( 100 );
my $t1000 = $terms->Num( 1000 );

isa_ok $traits->MergeSlots(
    $traits->Absent,
    $traits->Defined($t100)
),
'MXCL::Term::Trait::Slot::Defined';

isa_ok $traits->MergeSlots(
    $traits->Required,
    $traits->Required
),
'MXCL::Term::Trait::Slot::Required';

isa_ok $traits->MergeSlots(
    $traits->Required,
    $traits->Defined($t100)
),
'MXCL::Term::Trait::Slot::Defined';

isa_ok $traits->MergeSlots(
    $traits->Defined($t100),
    $traits->Defined($t100)
),
'MXCL::Term::Trait::Slot::Defined';

isa_ok $traits->MergeSlots(
    $traits->Defined($t100),
    $traits->Defined($t1000)
),
'MXCL::Term::Trait::Slot::Conflict';

done_testing;

