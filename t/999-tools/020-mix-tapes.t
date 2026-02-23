#!perl

use v5.42;

use Test::More;

use MXCL::Tape;

class MXCL::Tape::Mixer {
    method has_next {}
    method next     {}
    method enqueue (@kontinues) {}
    method advance ($k, @next)  {}
}

pass('...shhh');

done_testing;
