use Test::More;

BEGIN {
  eval "use Test::Exception";

  plan skip_all => "Test Exceptions required to test croaks" if $@;
  plan tests => 9;
}

use CPAN::Mini::Inject;
use File::Path;
use Env;
use lib 't/lib';

sub chkcfg {
  return 1 if ( -r '/usr/local/etc/mcpani' );
  return 1 if ( -r '/etc/mcpani' );
}

my $prevhome;
if ( defined( $ENV{HOME} ) ) {
  $prevhome = $ENV{HOME};
  delete $ENV{HOME};
}

my $mcpanienv;
if ( defined( $ENV{MCPANI_CONFIG} ) ) {
  $mcpanienv = $ENV{MCPANI_CONFIG};
  delete $ENV{MCPANI_CONFIG};
}

# loadcfg()
SKIP: {
  skip 'Config file exists', 1 if chkcfg();
  my $mcpi = CPAN::Mini::Inject->new;
  dies_ok { $mcpi->loadcfg } 'No config file';
}

{
  # parsecfg()
  my $mcpi = CPAN::Mini::Inject->new;
  dies_ok { $mcpi->parsecfg( 't/.mcpani/config_bad' ); }
  'Missing config option';
}

# readlist()
SKIP: {
  skip 'User is superuser and can always read', 1 if $< == 0;
  my $mcpi = CPAN::Mini::Inject->new;

  rmtree( ['t/local/MYCPAN/modulelist'], 0, 1 );
  mkdir 't/local/MYCPAN';
  $mcpi->parsecfg( 't/.mcpani/config_noread' );
  dies_ok { $mcpi->readlist } 'unreadable file';
  rmtree( ['t/local/MYCPAN/modulelist'], 0, 1 );
}

{
  my $mcpi = CPAN::Mini::Inject->new;
  $mcpi->parsecfg( 't/.mcpani/config' );

  # add()
  dies_ok {
    $mcpi->add(
      module   => 'CPAN::Mini::Inject',
      authorid => 'SSORICHE',
      version  => '0.01'
    );
  }
  'Missing add param';

  dies_ok {
    $mcpi->add(
      module   => 'CPAN::Mini::Inject',
      authorid => 'SSORICHE',
      version  => '0.01',
      file     => 'blahblah'
    );
  }
  'Module file not readable';

}

{
  my $mcpi = CPAN::Mini::Inject->new;
  $mcpi->parsecfg( 't/.mcpani/config_norepo' );

  dies_ok {
    $mcpi->add(
      module   => 'CPAN::Mini::Inject',
      authorid => 'SSORICHE',
      version  => '0.01',
      file     => 'test-0.01.tar.gz'
    );
  }
  'Missing config repository';

}

SKIP: {
  skip "We don't have a r/o repo", 2;
  my $mcpi = CPAN::Mini::Inject->new;
  $mcpi->parsecfg( 't/.mcpani/config_read' );

  dies_ok {
    $mcpi->add(
      module   => 'CPAN::Mini::Inject',
      authorid => 'SSORICHE',
      version  => '0.01',
      file     => 'test-0.01.tar.gz'
    );
  }
  'read-only repository';

  $mcpi->{config}{remote} = "ftp://blahblah http://blah blah";
  dies_ok { $mcpi->testremote } 'No reachable site';

}

# writelist()
SKIP: {
  skip 'User is superuser and can always write', 1 if $< == 0;

  my $mcpi = CPAN::Mini::Inject->new;
  rmtree( ['t/local/MYCPAN/modulelist'], 0, 1 );
  mkdir 't/local/MYCPAN';
  $mcpi->parsecfg( 't/.mcpani/config_nowrite' );
  dies_ok { $mcpi->writelist } 'fail write file';
  rmtree( ['t/local/MYCPAN/modulelist'], 0, 1 );
}

# Setup routines
sub genmodlist {
  open( MODLIST, '>t/local/MYCPAN/modulelist' )
   or die "Can not create t/local/MYCPAN/modulelist: $!";
  print MODLIST << "EOF"
CPAN::Checksums                   1.016  A/AN/ANDK/CPAN-Checksums-1.016.tar.gz
CPAN::Mini                         0.18  R/RJ/RJBS/CPAN-Mini-0.18.tar.gz
CPANPLUS                         0.0499  A/AU/AUTRIJUS/CPANPLUS-0.0499.tar.gz
EOF
   ;
  close( MODLIST );
}

