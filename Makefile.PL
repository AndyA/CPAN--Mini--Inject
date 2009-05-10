use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPAN::Mini::Inject',
    AUTHOR              => 'Shawn Sorichetti <ssoriche@coloredblocks.net>',
    VERSION_FROM        => 'lib/CPAN/Mini/Inject.pm',
    EXE_FILES           => [ 'bin/mcpani' ],
    ABSTRACT_FROM       => 'lib/CPAN/Mini/Inject.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::Simple' => 0,
        'CPAN::Checksums' => 0,
        'CPAN::Mini' => 0.32,
        'Compress::Zlib' => 0,
        'Archive::Tar' => 0,
        'IO::Zlib' => 0,
        'YAML' => 0,
        'HTTP::Server::Simple' => 0.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Mini-Inject-* t/local/WRITEREPO t/local/MYCPAN' },
);
