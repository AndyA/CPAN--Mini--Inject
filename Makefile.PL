use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'CPAN::Mini::Inject',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/CPAN/Mini/Inject.pm',
  EXE_FILES     => ['bin/mcpani'],
  ABSTRACT_FROM => 'lib/CPAN/Mini/Inject.pm',
  PREREQ_PM     => {
    'Archive::Tar'          => 0,
    'CPAN::Checksums'       => 0,
    'CPAN::Mini'            => '0.32',
    'Carp'                  => 0,
    'Compress::Zlib'        => 0,
    'Env'                   => 0,
    'File::Basename'        => 0,
    'File::Copy'            => 0,
    'File::Path'            => 0,
    'File::Spec'            => '2.07',
    'File::Spec::Functions' => 0,
    'Getopt::Long'          => 0,
    'HTTP::Server::Simple'  => '0.07',
    'IO::Zlib'              => 0,
    'LWP::Simple'           => 0,
    'Pod::Usage'            => 0,
    'Test::More'            => 0,
    'YAML'                  => 0,
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean =>
   { FILES => 'CPAN-Mini-Inject-* t/local/WRITEREPO t/local/MYCPAN' },
);
