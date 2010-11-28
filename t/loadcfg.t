use Test::More tests => 3;

use CPAN::Mini::Inject;
use Env;

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

my $native_path = File::Spec->catfile( qw( t .mcpani config ) );
my $mcpi = CPAN::Mini::Inject->new;

$mcpi->loadcfg( $native_path );
is( $mcpi->{cfgfile}, $native_path );

$ENV{HOME} = 't';
$mcpi->loadcfg;
is( $mcpi->{cfgfile}, $native_path );

$ENV{MCPANI_CONFIG} = $native_path;
$mcpi->loadcfg;
is( $mcpi->{cfgfile}, $native_path );

# XXX add tests for /usr/local/etc/mcpani and /etc/minicpani

$ENV{MCPANI_CONFIG} = $mcpanienv if ( defined( $mcpanienv ) );
$ENV{HOME}          = $prevhome  if ( defined( $prevhome ) );
