use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MXCL',
    VERSION_FROM  => 'lib/MXCL.pm',
    ABSTRACT      => 'Parsing Markua documents and creating DOM',
    PREREQ_PM     => {},
    TEST_REQUIRES => {},
    test => {
        TESTS => "t/**/*.t t/**/**/*.t"
    }
);
