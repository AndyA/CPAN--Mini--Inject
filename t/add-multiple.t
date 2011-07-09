use Test::More tests => 10;

use CPAN::Mini::Inject;
use File::Path;

mkdir( 't/local/MYCPAN' );

my $mcpi;
$mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;

$mcpi->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.01',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->add(
  #module   => 'Dist::Metadata::Test::MetaFile',
  authorid => 'RWSTAUNER',
  #version  => '2.1',
  file     => 't/local/mymodules/Dist-Metadata-Test-MetaFile-2.2.tar.gz'
 )->add(
  #module   => 'Dist::Metadata::Test::MetaFile',
  authorid => 'RWSTAUNER',
  #version  => '2.2',
  file     => 't/local/mymodules/Dist-Metadata-Test-MetaFile-2.2.tar.gz'
 );

my $auth_path = File::Spec->catfile( 'R', 'RW', 'RWSTAUNER' );
is( $mcpi->{authdir}, $auth_path, 'author directory' );

foreach $dist ( qw(
  t/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz
  t/local/MYCPAN/authors/id/R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-2.2.tar.gz
) ) {
  ok( -r $dist, 'Added module is readable' );
}

foreach $line (
  'CPAN::Mini::Inject                 0.01  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
  'Dist::Metadata::Test::MetaFile::PM  2.0  R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-2.2.tar.gz',
  'Dist::Metadata::Test::MetaFile      2.2  R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-2.2.tar.gz',
) {
  ok( grep( /$line/, @{ $mcpi->{modulelist} } ), 'Module added to list' )
    or diag explain [$line, $mcpi->{modulelist}];

  my $pack = ($line =~ /^(\S+)/)[0];
  is( grep( /^$pack\s+/, @{ $mcpi->{modulelist} } ),
    1, 'Module added to list just once' );
}

is_deeply(
  [$mcpi->added_modules],
  [
    { file => 'CPAN-Mini-Inject-0.01.tar.gz', authorid => 'SSORICHE', modules => {'CPAN::Mini::Inject' => '0.01'} },
    { file => 'Dist-Metadata-Test-MetaFile-2.2.tar.gz', authorid => 'RWSTAUNER',
      modules => { 'Dist::Metadata::Test::MetaFile::PM' => '2.0', 'Dist::Metadata::Test::MetaFile' => '2.2' } },
    # added twice (bug in usage not in reporting)
    { file => 'Dist-Metadata-Test-MetaFile-2.2.tar.gz', authorid => 'RWSTAUNER',
      modules => { 'Dist::Metadata::Test::MetaFile::PM' => '2.0', 'Dist::Metadata::Test::MetaFile' => '2.2' } },
  ],
  'info for added modules'
);

rmtree( 't/local/MYCPAN', 0, 1 );
