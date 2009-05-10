use strict;
use warnings;
use Module::Build;
use 5.005;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'CPAN::Mini::Inject',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/CPAN/Mini/Inject.pm',
  requires          => {
    'Archive::Tar'         => 0,
    'CPAN::Checksums'      => 0,
    'CPAN::Mini'           => '0.32',
    'Compress::Zlib'       => 0,
    'HTTP::Server::Simple' => '0.07',
    'IO::Zlib'             => 0,
    'LWP::Simple'          => 0,
    'Test::More'           => 0,
    'YAML'                 => 0,
  },
  add_to_cleanup =>
   [ 'CPAN-Mini-Inject-*', 't/local/WRITEREPO', 't/local/MYCPAN' ],
  script_files => ["bin/mcpani"],
);

$builder->create_build_script();
