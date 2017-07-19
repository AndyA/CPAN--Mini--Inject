use strict;
use warnings;
use Module::Build;
use 5.005;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'CPAN::Mini::Inject',
  license           => 'perl',
  dist_author       => [
    'Shawn Sorichetti <ssoriche@coloredblocks.net>',
    'Andy Armstrong <andy@hexten.net>',
    'Christian Walde <walde.christian@googlemail.com>',
    'Randy Stauner <rwstauner@cpan.org>',
    'Karen Etheridge <ether@cpan.org>',
    'Salve J. Nilsen <sjn@cpan.org>',
    'Wolfgang Pecho <pecho@belwue.de>',
    'Konstantin Yakunin <twinhooker@gmail.com>',
  ],
  dist_version_from => 'lib/CPAN/Mini/Inject.pm',
  configure_requires => { 'Module::Build' => 0.4 },
  requires          => {
    'CPAN::Checksums'           => 0,
    'CPAN::Mini'                => '0.32',
    'Carp'                      => 0,
    'Compress::Zlib'            => 0,
    'Dist::Metadata'            => '0.921',
    'Env'                       => 0,
    'File::Basename'            => 0,
    'File::Copy'                => 0,
    'File::Path'                => '2.07',
    'File::Spec'                => '2.07',
    'File::Spec::Functions'     => 0,
    'Getopt::Long'              => 0,
    'HTTP::Server::Simple'      => '0.07',
    'IO::Zlib'                  => 0,
    'LWP::Simple'               => 0,
    'Pod::Usage'                => 0,
    'Test::More'                => 0,
    'Net::EmptyPort'            => 0,
    'YAML'                      => 0,
    'File::Slurp'               => 0,
    'File::Temp'                => 0,
  },
  add_to_cleanup =>
   [ 'CPAN-Mini-Inject-*', 't/local/WRITEREPO', 't/local/MYCPAN' ],
  script_files => ["bin/mcpani"],
);

$builder->create_build_script();
