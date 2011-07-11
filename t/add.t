use Test::More tests => 14;
use Test::Exception;

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
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.02',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->add(
  modules  => {Foo => '1.0', Bar => '2.0'},
  authorid => 'SSORICHE',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
);

my $soriche_path = File::Spec->catfile( 'S', 'SS', 'SSORICHE' );
is( $mcpi->{authdir}, $soriche_path, 'author directory' );
ok(
  -r 't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
  'Added module is readable'
);
my @modules = (
   'CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Foo                                 1.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
   'Bar                                 2.0  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
);

for my $module (@modules) {
    ok( grep( /$module/, @{ $mcpi->{modulelist} } ), "Module $module added to list" );
}

is( grep( /^CPAN::Mini::Inject\s+/, @{ $mcpi->{modulelist} } ),
  1, 'Module added to list just once' );

# Test argument validation on add() method
throws_ok  {$mcpi->add( authorid => 'AUTHOR', modules => {}) }
          qr/Required option not specified: file/, 'Missing file argument';

throws_ok {$mcpi->add( file => 'My-Modules-1.0.tar.gz', modules => {}) }
          qr/Required option not specified: authorid/, 'Missing authorid argument';

throws_ok {$mcpi->add( authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Must specify either/, 'Missing module and modules argument',;

throws_ok {$mcpi->add( modules => {}, module => 'FOO', authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Must specify either/, 'Both module and modules argument given';

throws_ok {$mcpi->add( modules => {}, version => '1.0', authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Must specify either/, 'Both modules and version argument given';

throws_ok {$mcpi->add( modules => {Foo => undef}, authorid => 'AUTHOR', file => 'My-Modules-1.0.tar.gz') }
          qr/Version number required for modules: Foo/, 'Missing version number for a module';

SKIP: {
  skip "Not a UNIX system", 2 if ( $^O =~ /^MSWin/ );
  is( ( stat( 't/local/MYCPAN/authors/id/S/SS/SSORICHE' ) )[2] & 07777,
    0775, 'Added author directory mode is 0775' );
  is(
    (
      stat(
        't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz'
      )
    )[2] & 07777,
    0664,
    'Added module mode is 0664'
  );
}

# XXX do the same test as above again, but this time with a ->readlist after
# the ->parsecfg

rmtree( 't/local/MYCPAN', 0, 1 );
